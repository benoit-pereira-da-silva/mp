//
//  DetectShots.swift
//  mp
//
//  Created by Benoit Pereira da silva on 15/12/2018.
//

import Cocoa
import AVKit
import Globals
import CoreMedia
import CommandLineKit


class DetectShotsCommand: CommandBase {
    
    var detector:ShotsDetector?
    var movie:AVMovie?

    /*
     Usage: mp detect-shots [options]
     -i, --input-file:
     The media file url or path
     -o, --output-file:
     The Out put file path
     -s, --starts:
     The optional starting time stamp in seconds (double)
     -e, --ends:
     The optional ends time stamp in seconds (double)
     -t, --threshold:
     The optional detection threshold (integer from 1 to 255)
     */

    override init() {

        super.init()

        let input = StringOption(shortFlag: "i", longFlag: "input", required: true,
                                     helpMessage: "The media file URL or path")
        
        let output = StringOption(shortFlag: "o", longFlag: "output", required: true,
                                      helpMessage: "The Out put file path ")
        
        let startsAt = DoubleOption(shortFlag: "s", longFlag: "starts", required: false,
                                    helpMessage: "The optional starting time stamp in seconds (double)")
        
        let endsAt = DoubleOption(shortFlag: "e", longFlag: "ends", required: false,
                                  helpMessage: "The optional ends time stamp in seconds (double)")
        
        let threshold = IntOption(shortFlag: "t", longFlag: "threshold", required: false,
                                  helpMessage: "The optional detection threshold (integer from 1 to 255)")
        
        self.addOptions(options: input, output, startsAt, endsAt,threshold)
        if self.parse() {
            if let input: String = input.value,
                let output: String = output.value{

                let movieURL:URL
                if FileManager.default.fileExists(atPath: input){
                    movieURL = URL(fileURLWithPath: input)
                }else{
                    guard let url:URL = URL(string: input) else{
                        print("Invalid movie URL \(input)")
                        exit(EX__BASE)
                    }
                    movieURL = url
                }
                print("Processing \(movieURL) -> \(output)")

                let starts = startsAt.value ?? 0
                let endsTime:CMTime? = endsAt.value?.toCMTime()
                let startTime:CMTime = starts.toCMTime()
                VideoMetadataExtractor.extractMetadataFromMovieAtURL(movieURL, success: { (origin, fps, duration, width:Float, height:Float,url:URL) in

                    print("Processing video: \(url) ")
                    print("Fps: \(fps)")
                    print("Size: \(Int(width))/\(Int(height))")
                    print("Duration: \(duration.stringMMSS)")
                    if let origin:Double = origin{
                        print("Origin: \(origin.toCMTime().timeCodeRepresentation(fps, showImageNumber: true))")
                    }else{
                        print("Origin: \(0.toCMTime().timeCodeRepresentation(fps, showImageNumber: true))")
                    }
                    do{
                        let desc: VideoDescriptor = VideoDescriptor(url: url, fps: fps, width: Double(width), height: Double(height), duration: duration, origin: origin ?? 0, originTimeCode: duration.stringMMSS)
                        self.detector = try ShotsDetector.init(source: desc,startTime: startTime, endTime: endsTime ?? duration.toCMTime())
                        if let threshold = threshold.value{
                            if threshold > 0 && threshold <= 255{
                                self.detector?.differenceThreshold = threshold
                            }else{
                                print("Ignoring threshold option \(threshold), its value should be > 0 and <= 255")
                            }
                        }
                        NotificationCenter.default.addObserver(forName: NSNotification.Name.ShotsDetection.didFinish, object:nil, queue:nil, using: { (notification) in
                            if let shots: [Shot] = self.detector?.shots{
                                let result: ShotsDetectionResult = ShotsDetectionResult(infos:desc, shots:shots)
                                doCatchLog({
                                    let outputURL:URL = URL(fileURLWithPath: output)
                                    print("Saving the out put file : \(outputURL)")
                                    try save(instance: result, to: outputURL)
                                    try saveCollection(collection: shots, to:outputURL)
                                })
                            }
                            print("This the END")
                            exit(EX_OK)
                        })
                        self.detector?.start()
                    }catch{
                        print("Error:\(error)")
                        exit(EX__BASE)
                    }
                }) { (message, url) in
                    print("\(url) \(message)")
                    exit(EX__BASE)
                }
            }else{
                print("Invalid")
                exit(EX__BASE)
            }
        }
    }
}


