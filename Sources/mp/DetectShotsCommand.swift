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
import Tolerance
import MPLib

class DetectShotsCommand: CommandBase {
    
    var detector: ShotsDetector?
    var movie: AVMovie?

    /*
     Usage: mp detect-shots [options]Usage: mp [options]
     -i, --input:
     The media file URL or path
     -o, --output:
     The Out put file path
     -a, --authorization-token:
     The optional Authorization bearer token (for media URLs)
     -s, --starts:
     The optional starting time stamp in seconds (double)
     -e, --ends:
     The optional ends time stamp in seconds (double)
     -t, --threshold:
     The optional detection threshold (integer from 1 to 255)
     */

    required init() {

        super.init()

        let input = StringOption(shortFlag: "i", longFlag: "input", required: true,
                                     helpMessage: "The media file URL or path (supports Bearer tokens)")
        
        let output = StringOption(shortFlag: "o", longFlag: "output", required: false,
                                      helpMessage: "The optional Output file URL or path. If not set the result will be printed to the standard output. In case of URL usage + token it POST the file with the token in an HTTP Authorization Header")

        let token = StringOption(shortFlag: "a", longFlag: "authorization-token", required: false,
                                    helpMessage: "The optional Authorization bearer token (for media URLs)")

        let startsAt = DoubleOption(shortFlag: "s", longFlag: "starts", required: false,
                                    helpMessage: "The optional starting time stamp in seconds (double)")
        
        let endsAt = DoubleOption(shortFlag: "e", longFlag: "ends", required: false,
                                  helpMessage: "The optional ends time stamp in seconds (double)")
        
        let threshold = IntOption(shortFlag: "t", longFlag: "threshold", required: false,
                                  helpMessage: "The optional detection threshold (integer from 1 to 255)")

        let prettyEncode = BoolOption(shortFlag: "p", longFlag: "pretty-json", required: false,
                                    helpMessage: "Should the result be pretty encoded (default is false)")

        let verbose = BoolOption(shortFlag: "v", longFlag: "verbose", required: false,
                                      helpMessage: "If verbose some progress messages will be displayed in the standard output.")
        
        self.addOptions(options: input, output, token, startsAt, endsAt, threshold, prettyEncode, verbose)
        if self.parse() {
            self.isVerbose  = verbose.value
            if let input: String = input.value{
                let movieURL:URL
                if FileManager.default.fileExists(atPath: input){
                    movieURL = URL(fileURLWithPath: input)
                }else{
                    guard let url:URL = URL(string: input) else{
                        self.printIfVerbose("Invalid movie URL \(input)")
                        exit(EX__BASE)
                    }
                    if let token:String = token.value{
                        if var components : URLComponents = URLComponents(url: url , resolvingAgainstBaseURL: false) {
                            let queryItems:Dictionary<String,String> = ["token":token]
                            components.queryItems = components.queryItems ?? [URLQueryItem]()
                            for (k,v) in queryItems{
                                components.queryItems?.append(URLQueryItem(name: k, value: v))
                            }
                            movieURL = components.url ?? url
                        }else{
                            movieURL = url
                        }
                    }else{
                        movieURL = url
                    }
                }
                self.printIfVerbose("Processing \(movieURL) -> \(output)")

                let starts = startsAt.value ?? 0
                let endsTime:CMTime? = endsAt.value?.toCMTime()
                let startTime:CMTime = starts.toCMTime()
                VideoMetadataExtractor.extractMetadataFromMovieAtURL(movieURL, success: { (origin, fps, duration, width:Float, height:Float,url:URL) in

                    self.printIfVerbose("Processing video: \(url) ")
                    self.printIfVerbose("Fps: \(fps)")
                    self.printIfVerbose("Size: \(Int(width))/\(Int(height))")
                    self.printIfVerbose("Duration: \(duration.stringMMSS)")

                    if let origin:Double = origin{
                        self.printIfVerbose("Origin: \(origin.toCMTime().timeCodeRepresentation(fps, showImageNumber: true))")
                    }else{
                        self.printIfVerbose("Origin: \(0.toCMTime().timeCodeRepresentation(fps, showImageNumber: true))")
                    }

                    do{

                        let videoSource: VideoSource = VideoSource( url: url,
                                                            token: token.value,
                                                            fps: fps,
                                                            width: Double(width),
                                                            height: Double(height),
                                                            duration: duration,
                                                            origin: origin ?? 0,
                                                            originTimeCode: (origin ?? 0).stringMMSS)

                        self.detector = try ShotsDetector.init( source: videoSource,
                                                               startTime: startTime,
                                                               endTime: endsTime ?? duration.toCMTime())
                        self.detector?.printDelegate = self

                        if let threshold = threshold.value{
                            
                            if threshold > 0 && threshold <= 255{
                                self.detector?.differenceThreshold = threshold
                            }else{
                                self.printIfVerbose("Ignoring threshold option \(threshold), its value should be > 0 and <= 255")
                            }
                        }

                        NotificationCenter.default.addObserver(forName: NSNotification.Name.ShotsDetection.didFinish, object:nil, queue:nil, using: { (notification) in
                            if let result: ShotsDetectionResult = self.detector?.result{
                                doCatchLog({
                                    setlocale(LC_ALL,"en_US") // To fix a bug in Swift JSON Apple Radar #36107307
                                    let data:Data
                                    if prettyEncode.value{
                                        data = try JSON.prettyEncoder.encode(result)
                                    }else{
                                        data = try JSON.encoder.encode(result)
                                    }
                                    if  let output: String = output.value{
                                        let outputURL:URL = URL(fileURLWithPath: output)
                                        if outputURL.isFileURL{
                                            self.printIfVerbose("Saving the out put file : \(outputURL)")
                                            try writeData(data, to: outputURL)
                                        }else{
                                            // POST with the bearer token auth if present @todo
                                        }
                                    }
                                    if !verbose.value || output.value == nil{
                                        if let utf8String:String = String(data: data, encoding: .utf8 ){
                                            self.printAlways(utf8String)
                                        }
                                    }
                                })
                            }
                            self.printIfVerbose("This the END")
                            exit(EX_OK)
                        })
                        self.detector?.start()
                    }catch{
                        self.printIfVerbose("Error:\(error)")
                        exit(EX__BASE)
                    }
                }) { (message, url) in
                    self.printIfVerbose("\(url) \(message)")
                    exit(EX__BASE)
                }
            }else{
                self.printIfVerbose("Invalid")
                exit(EX__BASE)
            }
        }
    }
}


