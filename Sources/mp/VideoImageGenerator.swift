//
//  VideoImageGenerator.swift
//  mp
//
//  Created by Benoit Pereira da silva on 15/12/2018.
//

import Foundation
import AppKit
import Globals
import CoreMedia
import CoreGraphics
import AVFoundation

public class VideoImageGenerator: VideoFrameGenerator {

    var counter : Int = 0
    
    var isRunning : Bool = true
    
    let movie : AVMovie
    
    var times : [CMTime]
    
    let delegate : VideoFrameGeneratorDelegate
    
    let onProgress : VideoImageGeneratorProgress
    
    fileprivate var _generator:AVAssetImageGenerator?

    // MARK : - 
    
    init(movie:AVMovie,
         times:[CMTime],
         delegate:VideoFrameGeneratorDelegate,
         priority:VideoFrameGenerator.Priority,
         progressClosure:@escaping VideoImageGeneratorProgress){

        self.movie = movie
        self.times = times
        self.delegate = delegate
        self.onProgress = progressClosure
        super.init()
        self.priority = priority
        self._run()
    }
    
    
    override func cancel(){
        self._generator?.cancelAllCGImageGeneration()
    }
    
    // MARK: Implementation
    
    fileprivate func _run(){
        if self.times.count==0 || self.isRunning == false{
            self.delegate.imageGenerationHasBeenCompleted(reference: self)
        }else{
            self._generator = AVAssetImageGenerator(asset: self.movie)
            if let generator = self._generator{
                // If we have more than one video track we need to create a video composition in order to playback the movie correctly.
                if movie.tracks(withMediaType:AVMediaType.video).count > 1{
                    generator.videoComposition = AVVideoComposition(propertiesOf: movie)
                }
                // We need the maximun precision
                generator.requestedTimeToleranceAfter =  CMTime.zero
                generator.requestedTimeToleranceBefore = CMTime.zero
                
                let timesAsValues = times.map{ (time) -> NSValue in
                    return NSValue.init(time: time)
                }

                // Let's generate CGImages
                generator.generateCGImagesAsynchronously(forTimes:timesAsValues, completionHandler: { (requestedTime, imageRef, actualTime, generatorResult, error) in

                    self.counter += 1
                    let isTheLast = (self.counter == timesAsValues.count)
                    var progressHasBeenDispatched = false

                    if let cgimage = imageRef , error == nil{
                        self.onProgress(cgimage, requestedTime, true)
                        progressHasBeenDispatched = true
                    }
                    if !progressHasBeenDispatched{
                        // There is an issue.

                        let height = 1
                        let width = 1
                        let numComponents = 3
                        let numBytes = height * width * numComponents
                        let pixelData = [UInt8](repeating: 210, count: numBytes)
                        let colorspace = CGColorSpaceCreateDeviceRGB()
                        let rgbData = CFDataCreate(nil, pixelData, numBytes)!
                        let provider = CGDataProvider(data: rgbData)!
                        let onePixelImage:CGImage = CGImage(width: width,
                                                            height: height,
                                                            bitsPerComponent: 8,
                                                            bitsPerPixel: 8 * numComponents,
                                                            bytesPerRow: width * numComponents,
                                                            space: colorspace,
                                                            bitmapInfo: CGBitmapInfo(rawValue: 0),
                                                            provider: provider,
                                                            decode: nil,
                                                            shouldInterpolate: true,
                                                            intent: CGColorRenderingIntent.defaultIntent)!

                        print("Void image at relative time: \(requestedTime.seconds.stringMMSS)")
                        self.onProgress(onePixelImage, requestedTime, false)
                    }
                    if isTheLast{
                        self.isRunning=false
                        self.delegate.imageGenerationHasBeenCompleted(reference: self)
                    }
                })

            }
        }
    }
}

