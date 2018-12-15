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

        let inputFile = StringOption(shortFlag: "i", longFlag: "input-file", required: true,
                                     helpMessage: "The media file url or path")
        
        let outputFile = StringOption(shortFlag: "o", longFlag: "output-file", required: true,
                                      helpMessage: "The Out put file path ")
        
        let startsAt = DoubleOption(shortFlag: "s", longFlag: "starts", required: false,
                                    helpMessage: "The optional starting time stamp in seconds (double)")
        
        let endsAt = DoubleOption(shortFlag: "e", longFlag: "ends", required: false,
                                  helpMessage: "The optional ends time stamp in seconds (double)")
        
        let threshold = IntOption(shortFlag: "t", longFlag: "threshold", required: false,
                                  helpMessage: "The optional detection threshold (integer from 1 to 255)")
        
        self.addOptions(options: inputFile, outputFile, startsAt, endsAt,threshold)
        if self.parse() {
            if let inputFile: String = inputFile.value,
                let outputFile: String = outputFile.value{

                guard let movieURL:URL = URL(string: inputFile) else{
                    print("Invalid movie URL \(inputFile)")
                    exit(EX__BASE)
                }
                print("Processing \(movieURL) -> \(outputFile)")

                let starts = startsAt.value ?? 0
                let endsTime:CMTime = endsAt.value?.toCMTime() ?? Double.infinity.toCMTime()
                let startTime:CMTime = starts.toCMTime()
                VideoMetadataExtractor.extractMetadataFromMovieAtURL(movieURL, success: { (origin, fps, duration, width:Float, height:Float,url:URL) in
                    do{
                        self.detector = try ShotsDetector.init(movieURL: movieURL, startTime: startTime, endTime: endsTime, fps: fps, origin: origin ?? 0 )
                        if let threshold = threshold.value{
                            if threshold > 0 && threshold <= 255{
                                self.detector?.differenceThreshold = threshold
                            }else{
                                print("Ignoring threshold option \(threshold), its value should be > 0 and <= 255")
                            }
                        }
                        NotificationCenter.default.addObserver(forName: NSNotification.Name.ShotsDetection.didFinish, object:nil, queue:nil, using: { (notification) in
                            print("The END")
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


