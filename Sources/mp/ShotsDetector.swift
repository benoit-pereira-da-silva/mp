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

fileprivate struct Shot{
    let time:CMTime
    let detectionValue:Int
}

fileprivate struct TimedImage {

    let image:CGImage
    let keyTime:CMTime
    var difference:Int = -1

    var hasBeenEvaluated:Bool { return self.difference >= 0 }

    init(image: CGImage, keyTime: CMTime) {
        self.image = image
        self.keyTime = keyTime
    }
}


class ShotsDetector{

    // How many TimedImage do we store?
    let storageSize = 128 //TimedImage
    // Define the size of a bunch
    let bunchSize = 64 // TimedImage

    let startTime:CMTime
    let endTime:CMTime
    let fps:Double
    let origin:Double
    let movie:AVMovie
    let frameDuration:CMTime
    let totalNumber:Int64

    // The shot detection treshold
    var differenceThreshold:Int = 40
    var minDurationBetweenTwoShotsInSeconds:Double = 1


    // Those shots are not registred to the document.
    // The timestamps are using absolute time.
    fileprivate var _shots = [Shot]()
    fileprivate var _cachedBunch = [TimedImage]()
    fileprivate var _resume = true
    fileprivate var _highestTime =  CMTime.zero
    fileprivate var _imageGenerator :AVAssetImageGenerator

    var progress:Progress = Progress(totalUnitCount: 0)


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
        self.progress.totalUnitCount = self.totalNumber
        self.progress.totalUnitCount = 0
    }
    
    func start(){
        self._nextBunch()
    }

    func cancel(){
        self._resume = false
    }

    // MARK: - Extraction ( on an Utility queue)

    fileprivate var _bunchCountDown = 0

    fileprivate func _nextBunch(){
        let isFirst = self._cachedBunch.count == 0
        // Let's center the frame
        var nextTime = isFirst ? self.startTime + (self.frameDuration.seconds / 2).toCMTime()  : self._cachedBunch.last!.keyTime + self.frameDuration
        guard self._resume && nextTime <= self.endTime else {
            // This is the end
            NotificationCenter.default.post(name: NSNotification.Name.ShotsDetection.didFinish, object: nil, userInfo: ["detector":self])
            return
        }

        // Purge the previous cached bunch
        while self._cachedBunch.count > self.bunchSize{
            self._cachedBunch.removeFirst()
        }

        var timesAsValues = [NSValue]()
        self._bunchCountDown = 0
        for _ in 0...self.bunchSize{
            timesAsValues.append(NSValue(time:CMTime(seconds: nextTime.seconds, preferredTimescale: nextTime.timescale)))
            nextTime = nextTime + self.frameDuration
            self._bunchCountDown += 1
        }

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
            self._analyzeCachedTimedImages()
            self._nextBunch()
        }

        self.progress.totalUnitCount = 1
        self.progress.completedUnitCount += 1
        let d = NSLocalizedString("Number of detected Shots: ", comment: "Number of detected Shots: ")
        let message = "\(d)\((self._shots.count)) | \(self.progress.completedUnitCount) / \( self.progress.totalUnitCount) \(self.progress.completedUnitCount * 100 / self.progress.totalUnitCount )%"
        print(message)
    }

    // We analyze all the stored Images
    // The process is currently simple but could involve more complex bunches analysis
    fileprivate func _analyzeCachedTimedImages(){
        autoreleasepool{
            self._cachedBunch = self._cachedBunch.sorted { (lt, rt) -> Bool in
                return lt.keyTime < rt.keyTime
            }

            // #1- Determinate the shots candidates
            var shotsCandidates = [TimedImage]()
            for (i,timedImage) in self._cachedBunch.enumerated(){
                // We don't want to recompute already computed differences
                if timedImage.difference == -1 && i > 0 {
                    let previous:TimedImage = self._cachedBunch[i - 1 ]
                    var current:TimedImage = timedImage
                    // Proceed to image by image comparison
                    current.difference = ImagesComparator.measureDifferenceBetween(leftImage: previous.image, rightImage:current.image )
                    if current.difference  >= self.differenceThreshold{
                        shotsCandidates.append(current)
                    }
                }
            }

            guard shotsCandidates.count > 0 else{
                return
            }

            // 2# Respect minDurationBetweenTwoShotsInSeconds
            var lastQualifiedCandidate:TimedImage?
            for timedImage in shotsCandidates{
                if let referentCandidate = lastQualifiedCandidate{
                    if (timedImage.keyTime - referentCandidate.keyTime).seconds < self.minDurationBetweenTwoShotsInSeconds{
                        print("Skipping \(timedImage.keyTime.timeCodeComponents(self.fps))")
                        continue // Do not create the shot
                    }
                }
                lastQualifiedCandidate = timedImage
                let shot:Shot = Shot(time:  timedImage.keyTime,detectionValue: timedImage.difference)
                self._shots.append(shot)
            }
        }
    }
}

