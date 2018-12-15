//
// CommandsFacade.swift
//  mp
//
//  Created by Benoit Pereira da silva on 15/12/2018.
//

import AppKit
import Globals

public struct CommandsFacade {

    public let version:String = "1.0.0"

    static let args = Swift.CommandLine.arguments
    let executableName = NSString(string: args.first!).pathComponents.last!
    let firstArgumentAfterExecutablePath: String = (args.count >= 2) ? args[1] : ""
    
    let echo: String = args.joined(separator: " ")
    
    public func actOnArguments() {

        switch firstArgumentAfterExecutablePath {
        case nil:
            print(self._noArgMessage())
            exit(EX_NOINPUT)
        case "-h", "-help", "h", "help":
            print(self._noArgMessage())
            exit(EX_USAGE)
        case "-version", "--version", "v", "version":
            print("\n\"\(self.executableName)\" has been created by Benoit Pereira da Silva https://pereira-da-silva.com\n\nCurrent version of \(self.executableName) is: \(self.version)")
            exit(EX_USAGE)
        case "echo", "--echo":
            print(echo)
            exit(EX_USAGE)
        case "detect-shots":
            let _ = DetectShotsCommand()
        case "detect-main-subject":
            #if os(OSX)
                if #available(OSX 10.13, *) {
                   // COREML Support
                   // let _ = DetectMainSubjectCommand(completionHandler: completionHandler)
                }else{
                    print("COREML  macOS 10.13 and +")
                }
            #else
                print("COREML support is restricted to macOS")
                exit(EX_USAGE)
            #endif
        default:
            // We want to propose the best verb candidate
            let reference=[
                "h", "help",
                "v","version",
                "echo",
                "extract","extract-document",
                "reveal",
                "export-alignements",
                "wsd","watson-speaker-diarization",
                "detect-shots",
                "detect-main-subject",
                "pyannote-import-mdtm"
            ]
            let bestCandidate = self.bestCandidate(string: firstArgumentAfterExecutablePath, reference: reference)
            print("Hey ...\"\(self.executableName) \(firstArgumentAfterExecutablePath)\" is unexpected!")
            print("Did you mean:\"\(self.executableName) \(bestCandidate)\"?")
            exit(EX__BASE)
        }
    }
    
    private func _noArgMessage() -> String {
        var s=""
        s += "\(self.executableName) is a Video Media processor Command Line tool"
        s += "\nCreated by Benoit Pereira da Silva https://pereira-da-silva.com"
        s += "\nvalid calls are S.V.O sentences like:\"\(self.executableName) <verb> [options]\""
        s += "\n"
        s += "\n\(self.executableName) help"
        s += "\n\(self.executableName) version"
        s += "\n\(self.executableName) echo <args>"
        s += "\n"
        s += "\nYou can call help for each verb e.g:\t\"\(self.executableName) extract help\""
        s += "\n"
        s += "\nAvailable verbs:"
        s += "\n"
        s += "\n\(self.executableName) detect-shots -f <ydb path> -k <bkey path> -c <components path>"
        s += "\n\(self.executableName) detect-main-subject -u <a video URI> -m <the file path to the core ml model>  -f <the sampling frequency>"
        s += "\n"
        return s
    }
    
    // MARK: levenshtein distance
    
    private func bestCandidate(string: String, reference: [String]) -> String {
        if trim(string) == ""{
            return "help"
        }
        var selectedCandidate=string
        var minDistance: Int=Int.max
        for candidate in reference {
            let distance = levenshtein(string, candidate)
            if distance < minDistance {
                minDistance=distance
                selectedCandidate=candidate
            }
        }
        return selectedCandidate
    }
    


}
