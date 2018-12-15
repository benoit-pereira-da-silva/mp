//
//  VideoMetadataExtractor.swift
//  mp
//
//  Created by Benoit Pereira da silva on 15/12/2018.
//

import Foundation
import Globals
import AppKit
import AVKit
import CoreMedia


enum VideoMetadataExtractorError:Error{
    case message(_ message:String)
}
struct VideoMetadataExtractor{


    // MARK: - AVAssets metadata extraction

    /**
     Extracts the Time Metadata origin, fps and duration.
     the origin correspond to a time code of the first frame (a film may start at 10 : 22 : 10 : 001 for example)

     - parameter url:     the asset URL
     - parameter success: called on successfull extraction on the main queue
     - parameter document: the associated document
     - parameter failure: called on failure extraction on the main queue
     - parameter acquireSecurizedUrl: if set to false we do not use sandboxed
     */
    static func extractMetadataFromMovieAtURL( _ url: URL,
                                               success:@escaping (_ origin: Double?, _ fps: Double, _ duration: Double,_ width:Float, _ height:Float,_ url:URL)->(),
                                               failure:@escaping (_ message: String,_ url:URL)->()) ->(){
        syncOnMain{
            let asset = AVAsset(url: url)
            var error: NSError?
            asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"], completionHandler: { () -> Void in

                syncOnMain {

                    var origin: Double?
                    var fps: Double = 25.0
                    var duration: Double = 0
                    var width:Float = 0
                    var height:Float = 0

                    let tracksStatus=asset.statusOfValue(forKey: "tracks", error: &error)
                    if tracksStatus == AVKeyValueStatus.loaded {
                        let durationStatus=asset.statusOfValue(forKey: "duration", error: &error)
                        if durationStatus == AVKeyValueStatus.loaded {
                            duration=asset.duration.seconds
                            asset.tracks.forEach({ (track) in
                                if track.mediaType == AVMediaType.video {
                                    width = Float(track.naturalSize.width)
                                    height = Float(track.naturalSize.height)
                                    if track.nominalFrameRate != 0 {
                                        fps = Double(track.nominalFrameRate)
                                    }
                                }
                            })
                            if fps == 0 {
                                failure("Unable to get fps from video track",url)
                            } else {
                                asset.tracks.forEach({ (track) in
                                    if track.mediaType == AVMediaType.timecode {
                                        do {
                                            let reader = try AVAssetReader(asset: asset)
                                            let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
                                            if reader.canAdd(readerOutput) {
                                                reader.add(readerOutput)
                                                if reader.startReading() {
                                                    var count = 0
                                                    while reader.status == AVAssetReader.Status.reading {
                                                        if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                                                            count += 1
                                                            if let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                                                                let length = CMBlockBufferGetDataLength(blockBuffer)
                                                                if length > 0 {
                                                                    if let data = NSMutableData(length: length) {
                                                                        CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: data.mutableBytes)
                                                                        var bytes = [UInt8](repeating: 0, count: length)
                                                                        data.getBytes(&bytes, length: length * MemoryLayout<UInt8>.size)
                                                                        var n: Int = 0
                                                                        for b in bytes {
                                                                            n = (n << 8) + Int(b)
                                                                        }
                                                                        origin = Double(n) / fps
                                                                    }
                                                                }
                                                            }
                                                        } else {
                                                            continue
                                                        }
                                                    }
                                                    if count == 0 {
                                                        // No data where read from the timecode track
                                                    }
                                                }
                                            }
                                        } catch {
                                            //Silent Catch
                                            //Unable to read the timecode track
                                        }
                                    }
                                })
                                success(origin, fps, duration,width,height,url)
                            }
                        } else {
                            failure("The key \"duration\" was not loaded \(String(describing: error))",url)

                        }
                    } else {
                        failure("The key \"tracks\" was not loaded \(String(describing: error))",url)

                    }
                }
            })
        }
    }
}
