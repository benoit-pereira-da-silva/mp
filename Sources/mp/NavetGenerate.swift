//
//  NavetGenerate.swift
//  navet
//
//  Created by Benoit Pereira da silva on 27/10/2017.
//  Copyright © 2017 Pereira da Silva https://pereira-da-silva.com All rights reserved.
//

import Foundation
import CommandLineKit
import NavetLib

public class NavetGenerate: CommandBase {
    
    public required init() {
        super.init()
        #if os(OSX)
        let duration = DoubleOption(shortFlag: "d", longFlag: "duration", required: true, helpMessage: "The duration in seconds")

        let fps = DoubleOption(shortFlag: "f", longFlag: "fps", required: false, helpMessage: "The number of frame per seconds (default 25)")

        let width = DoubleOption(shortFlag: "w", longFlag: "width", required: false, helpMessage: "The width of the video (default 1080)")

        let height = DoubleOption(shortFlag: "h", longFlag: "height", required: false, helpMessage: "The height of the video (default 720)")

        let colorMode = EnumOption<Navet.ColorMode>(longFlag: "color-mode", required: false, helpMessage: "\"uniform\" \"random\" or \"progressive\" (default is \"progressive\")")

        let fileType = EnumOption<Navet.FileType>(longFlag: "file-type", required: false, helpMessage: "\"mov\" \"m4v\" or \"mp4\" (default is \"mov\")")

        let codec = EnumOption<Navet.VideoCodec>(longFlag: "codec", required: false, helpMessage: "\"hevc\" \"h264\" \"jpeg\"  \"proRes4444\" or \"proRes422\" (default is \"h264\")")

        let videoFilePath = StringOption(shortFlag: "p", longFlag: "video-file-path", required: false,
                                            helpMessage: "The video file path. If undefined we will create a navet folder on the desktop")

        addOptions(options: duration, fps,videoFilePath,colorMode,width,height,fileType,codec)

        if parse() {
            if let duration = duration.value{
                let navet = Navet()
                if let path = videoFilePath.value{
                   let fileURL = URL(fileURLWithPath: path)
                    if fileURL.isFileURL{
                        navet.videoFileURL = fileURL
                        navet.navetFolderURL = fileURL.deletingLastPathComponent()
                    }
                }
                navet.fileType = fileType.value ?? navet.fileType
                navet.videoCodec = codec.value ?? navet.videoCodec
                navet.numberOfSeconds = duration
                navet.fps = fps.value ?? navet.fps
                navet.colorMode = colorMode.value ?? navet.colorMode
                navet.width = CGFloat(width.value ?? Double(navet.width))
                navet.height = CGFloat(height.value ?? Double(navet.height))
                navet.generate({ (progress) in
                })
            }
        }
        #else
            print("osX only")
            exit(EX__BASE)
        #endif
    }
}

