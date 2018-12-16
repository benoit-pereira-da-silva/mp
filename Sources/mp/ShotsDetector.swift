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

public struct ShotsDetectionResult:Codable{
    let source:VideoSource
    var shots:[Shot]
    var stats: ShotsStats
}

public struct ShotsStats: Codable{
    let cliVersion:String = CLI_VERSION
    var averageImageComparisonResult:Int = 0
    var elapsedTime:Double = 0
    var elapsedTimeString:String = ""
    var imgPerSecond:Int = 0
    init(){}
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

    let startTime: CMTime
    let endTime: CMTime
    let movie: AVMovie
    var frameDuration: CMTime { return  (1 / self.source.fps).toCMTime() }
    var totalNumber: Int64 {return Int64((self.endTime - self.startTime).seconds * self.source.fps)}

    var printDelegate:PrintDelegate?

    // Concurrency.
    var maxConcurrentComparison: Int = 8
    
    // The shot detection treshold
    var differenceThreshold:Int = 40
    var cumulatedDifferences:Int = 0 // used to compute average difference
    var minDurationBetweenTwoShotsInSeconds:Double = 1

    var result: ShotsDetectionResult
    var source: VideoSource { return self.result.source }
    var shots: [Shot] { return self.result.shots }


    fileprivate let bunchSize:Int = 64
    fileprivate var _cachedBunch = [TimedImage]()
    fileprivate var _bunchCountDown = 0
    
    //var bunches: [Bunch] = [Bunch]()
    
    
    fileprivate var _resume = true
    fileprivate var _imageGenerator : AVAssetImageGenerator
    
    var progress: Progress = Progress(totalUnitCount:0)
    
    /// The constructor launches the extraction process.
    ///
    /// - Parameters:
    ///   - movieURL: the movie url :)
    ///   - startTime: the startTime
    ///   - endTime: the endTime


    func printIfVerbose(_ message:String){
        if let d : PrintDelegate = self.printDelegate{
            d.printIfVerbose(message)
        }
    }

    func printAlways(_ message:String){
        if let d : PrintDelegate = self.printDelegate{
            d.printAlways(message)
        }
    }



    init(source: VideoSource, startTime: CMTime, endTime: CMTime) throws{

        self.movie = AVMovie(url: source.url)
        self.result = ShotsDetectionResult(source: source, shots: [Shot](), stats: ShotsStats())

        guard  self.movie.isReadable else{
            throw ShotsDetectorError.movieIsNotReadable
        }
        
        self.startTime = startTime
        self.endTime = endTime
        
        self._imageGenerator=AVAssetImageGenerator(asset: self.movie)
        // If we have more than one video track we need to create a video composition in order to playback the movie correctly.
        if movie.tracks(withMediaType:AVMediaType.video).count > 1{
            self._imageGenerator.videoComposition = AVVideoComposition(propertiesOf: movie)
        }
        // We need the maximun precision
        self._imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        self._imageGenerator.requestedTimeToleranceBefore = CMTime.zero
    }
    
    func start(){
        self.progress.totalUnitCount = self.totalNumber
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
        self.printIfVerbose("Next Bunch \(initialTime.timeCodeRepresentation(self.source.fps, showImageNumber: true))-\(nextTime.timeCodeRepresentation(self.source.fps, showImageNumber: true)) \(self._progressString())")
        // Let's generate CGImages
        self._imageGenerator.generateCGImagesAsynchronously(forTimes:timesAsValues, completionHandler: { (requestedTime, image, actualTime, generatorResult, error) in
            if let confirmedImage = image{
                if let resized = ImagesComparator.resize(image: confirmedImage){
                    self._extracted(resized, at: requestedTime)
                    return
                }
            }
            // There is a problem
            self.printIfVerbose("ERROR: \(String(describing: error))")
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
            self.printIfVerbose("Bunch analysis. Size: \(self.bunchSize) Duration: \(duration) PerImg: \(duration / Double(self.bunchSize)) s/img")
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
                    self.cumulatedDifferences += current.difference
                    if current.difference  >= self.differenceThreshold{
                        shotsCandidates.append(current)
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
                    self.printIfVerbose("Distance between shots is to small ==\(distance) seconds Skipping \(timedImage.keyTime.timeCodeRepresentation(self.source.fps, showImageNumber: true))")
                    continue // Do not create the shot
                }
            }
            lastQualifiedCandidate = timedImage
            let shot:Shot = Shot(time: timedImage.keyTime.seconds, timeCode:timedImage.keyTime.timeCodeRepresentation(self.source.fps, showImageNumber: true) , detectionValue: timedImage.difference)
            self.result.shots.append(shot)
            let elapsedTime:Double = getElapsedTime()
            
            self.printIfVerbose("Appending shot at \(timedImage.keyTime.timeCodeRepresentation(self.source.fps, showImageNumber: true)). Total shots number: \(self.shots.count) Elapsed time : \(elapsedTime.stringMMSS) for \(self.progress.completedUnitCount)/ \(self.progress.totalUnitCount) -> \(percent)%")
        }
        if lastQualifiedCandidate == nil{
            self.printIfVerbose(self._progressString())
        }
    }
    
    
    fileprivate func _progressString()->String{
        let percent:Int64 = self.progress.totalUnitCount > 0 ? self.progress.completedUnitCount * 100 / self.progress.totalUnitCount : 0
        let elapsedTime:Double = getElapsedTime()
        let imgPerSeconds:Int64 = self.progress.completedUnitCount / (Int64(elapsedTime) > 0 ? Int64(elapsedTime) : Int64.max)
        self.result.stats.averageImageComparisonResult = self.cumulatedDifferences / Int(self.progress.completedUnitCount > 0 ? self.progress.completedUnitCount : 1)
        self.result.stats.elapsedTime = elapsedTime
        self.result.stats.imgPerSecond = Int(imgPerSeconds)
        self.result.stats.elapsedTimeString = elapsedTime.stringMMSS
        return "Total shots number: \(self.shots.count) Elapsed time : \(elapsedTime.stringMMSS) for \(self.progress.completedUnitCount)/ \(self.progress.totalUnitCount)  completion: \(percent)%  Speed: \(imgPerSeconds) img/s average difference between images: \(self.result.stats.averageImageComparisonResult)"
    }
    
}

