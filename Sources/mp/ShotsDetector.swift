//
//  ShotsDetector.swift
//  mp
//
//  Created by Benoit Pereira da silva on 15/12/2018.
//


import Foundation
import Globals
import AppKit
import CoreMedia
import AVFoundation

public extension Notification.Name {
    public struct ShotsDetection {
        public static let didFinish = Notification.Name(rawValue: "com.pereira-da-sivla.notification.ShotsDetection.didFinish")
    }
}

enum ShotsDetectorError:Error {
    case nilMovieURL
    case movieIsNotReadable
}

public struct Shot : Codable{
    let time:Double
    let timeCode:String
    let detectionValue:Int
}

struct TimedImage {
    
    let image:CGImage
    let keyTime:CMTime
    var difference:Int = -1
    
    var hasBeenEvaluated:Bool { return self.difference >= 0 }
    
    init(image: CGImage, keyTime: CMTime) {
        self.image = image
        self.keyTime = keyTime
    }
}

/*
 struct Bunch{
 
 // Define the size of a bunch
 var bunchSize: Int = 0 // Nb of TimedImage
 // The cache of TimedImage
 var cached: [TimedImage] = [TimedImage]()
 var countDown: Int = 0
 
 }
 */


class ShotsDetector{
    
    
    let startTime:CMTime
    let endTime:CMTime
    let fps:Double
    let origin:Double
    let movie:AVMovie
    let frameDuration:CMTime
    let totalNumber:Int64
    
    var maxConcurrentComparison: Int = 8
    
    // The shot detection treshold
    var differenceThreshold:Int = 40
    var minDurationBetweenTwoShotsInSeconds:Double = 1
    
    // Those shots are not registred to the document.
    // The timestamps are using absolute time.
    var shots:[Shot] = [Shot]()
    
    fileprivate let bunchSize:Int = 64
    fileprivate var _cachedBunch = [TimedImage]()
    fileprivate var _bunchCountDown = 0
    
    //var bunches: [Bunch] = [Bunch]()
    
    
    fileprivate var _resume = true
    fileprivate var _imageGenerator : AVAssetImageGenerator
    
    var progress:Progress
    
    /// The constructor launches the extraction process.
    ///
    /// - Parameters:
    ///   - movieURL: the movie url :)
    ///   - startTime: the startTime
    ///   - endTime: the endTime
    ///   - fps: the fps
    ///   - origin: the origin
    init(movieURL: URL, startTime: CMTime, endTime: CMTime,fps: Double,origin: Double) throws{
        
        self.movie = AVMovie(url: movieURL)
        
        guard  self.movie.isReadable else{
            throw ShotsDetectorError.movieIsNotReadable
        }
        
        self.startTime = startTime
        self.endTime = endTime
        self.fps = fps
        self.origin = origin
        
        self._imageGenerator=AVAssetImageGenerator(asset: self.movie)
        // If we have more than one video track we need to create a video composition in order to playback the movie correctly.
        if movie.tracks(withMediaType:AVMediaType.video).count > 1{
            self._imageGenerator.videoComposition = AVVideoComposition(propertiesOf: movie)
        }
        // We need the maximun precision
        self._imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        self._imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        self.frameDuration = (1 / self.fps).toCMTime()
        self.totalNumber = Int64((self.endTime - self.startTime).seconds * fps)
        self.progress = Progress(totalUnitCount: self.totalNumber)
    }
    
    func start(){
        self._nextBunch()
    }
    
    func cancel(){
        self._resume = false
    }
    
    // MARK: - Extraction
    
    fileprivate func _nextBunch(){
        let isFirst = self._cachedBunch.count == 0
        // Let's center the frame
        let initialTime = isFirst ? self.startTime + (self.frameDuration.seconds / 2).toCMTime()  : self._cachedBunch.last!.keyTime + self.frameDuration
        var nextTime = initialTime
        guard self._resume && nextTime <= self.endTime else {
            // This is the end
            NotificationCenter.default.post(name: NSNotification.Name.ShotsDetection.didFinish, object: nil, userInfo: ["detector":self])
            return
        }
        
        self._cachedBunch.removeAll()
        
        var timesAsValues = [NSValue]()
        self._bunchCountDown = 0
        for _ in 0...self.bunchSize{
            timesAsValues.append(NSValue(time:CMTime(seconds: nextTime.seconds, preferredTimescale: nextTime.timescale)))
            nextTime = nextTime + self.frameDuration
            self._bunchCountDown += 1
        }
        print("Next Bunch \(initialTime.timeCodeRepresentation(self.fps, showImageNumber: true))-\(nextTime.timeCodeRepresentation(self.fps, showImageNumber: true)) \(self._progressString()))")
        // Let's generate CGImages
        self._imageGenerator.generateCGImagesAsynchronously(forTimes:timesAsValues, completionHandler: { (requestedTime, image, actualTime, generatorResult, error) in
            if let confirmedImage = image{
                if let resized = ImagesComparator.resize(image: confirmedImage){
                    self._extracted(resized, at: requestedTime)
                    return
                }
            }
            // There is a problem
            print("ERROR: \(String(describing: error))")
            if let last = self._cachedBunch.last?.image{
                self._extracted(last, at: nextTime)
            }
        })
    }
    
    
    /// Proceed to evaluation on any extracted image
    ///
    /// - Parameters:
    ///   - image: the image
    ///   - time: the extraction time
    fileprivate func  _extracted(_ image:CGImage,at time:CMTime){
        let current = TimedImage.init(image: image, keyTime: time)
        self._cachedBunch.append(current)
        self._bunchCountDown -= 1
        // Did we grab all the image
        if self._bunchCountDown == 0{
            let duration:Double = measure {
                self._analyzeCachedTimedImages()
            }
            print("Bunch analysis. Size: \(self.bunchSize) Duration: \(duration) PerImg: \(duration / Double(self.bunchSize)) s/img")
            self.progress.completedUnitCount += Int64(self.bunchSize)
            self._nextBunch()
        }
    }
    
    // We analyze all the stored Images
    // The process is currently simple but could involve more complex bunches analysis
    fileprivate func _analyzeCachedTimedImages(){
        
        self._cachedBunch = self._cachedBunch.sorted { (lt, rt) -> Bool in
            return lt.keyTime < rt.keyTime
        }
        
        // #1- Determinate the shots candidates
        var shotsCandidates = [TimedImage]()
        
        let operationQueue:OperationQueue = OperationQueue.init()
        operationQueue.maxConcurrentOperationCount = self.maxConcurrentComparison
        operationQueue.qualityOfService = .userInteractive
        
        for (i,timedImage) in self._cachedBunch.enumerated(){
            operationQueue.addOperation {
                // We don't want to recompute already computed differences
                if timedImage.difference == -1 && i > 0 {
                    let previous:TimedImage = self._cachedBunch[i - 1 ]
                    var current:TimedImage = timedImage
                    // Proceed to image by image comparison
                    current.difference = ImagesComparator.measureDifferenceBetween(leftImage: previous.image, rightImage:current.image )
                    if current.difference  >= self.differenceThreshold{
                        syncOnMain {
                            shotsCandidates.append(current)
                        }
                    }
                }
            }
        }
        operationQueue.waitUntilAllOperationsAreFinished()
        
        let percent:Int64 = self.progress.totalUnitCount > 0 ? self.progress.completedUnitCount * 100 / self.progress.totalUnitCount : 0
        
        guard shotsCandidates.count > 0 else{
            return
        }
        
        // 2# Respect minDurationBetweenTwoShotsInSeconds
        var lastQualifiedCandidate:TimedImage?
        
        for timedImage in shotsCandidates{
            if let referentCandidate = lastQualifiedCandidate{
                let distance:Double = (timedImage.keyTime - referentCandidate.keyTime).seconds
                if distance < self.minDurationBetweenTwoShotsInSeconds{
                    print("Distance between shots is to small ==\(distance) seconds Skipping \(timedImage.keyTime.timeCodeRepresentation(self.fps, showImageNumber: true))")
                    continue // Do not create the shot
                }
            }
            lastQualifiedCandidate = timedImage
            let shot:Shot = Shot(time: timedImage.keyTime.seconds, timeCode:timedImage.keyTime.timeCodeRepresentation(self.fps, showImageNumber: true) , detectionValue: timedImage.difference)
            self.shots.append(shot)
            let elapsedTime:Double = getElapsedTime()
            
            print("Appending shot at \(timedImage.keyTime.timeCodeRepresentation(self.fps, showImageNumber: true)). Total shots number: \(self.shots.count) Elapsed time : \(elapsedTime.stringMMSS) for \(self.progress.completedUnitCount)/ \(self.progress.totalUnitCount) -> \(percent)%")
        }
        if lastQualifiedCandidate == nil{
            print(self._progressString())
        }
        
    }
    
    
    fileprivate func _progressString()->String{
        let percent:Int64 = self.progress.totalUnitCount > 0 ? self.progress.completedUnitCount * 100 / self.progress.totalUnitCount : 0
        let elapsedTime:Double = getElapsedTime()
        let imgPerSeconds:Int64 = self.progress.completedUnitCount / (Int64(elapsedTime) > 0 ? Int64(elapsedTime) : Int64.max)
        return "Total shots number: \(self.shots.count) Elapsed time : \(elapsedTime.stringMMSS) for \(self.progress.completedUnitCount)/ \(self.progress.totalUnitCount)  completion: \(percent)%  Speed: \(imgPerSeconds) img/s"
    }
    
}

