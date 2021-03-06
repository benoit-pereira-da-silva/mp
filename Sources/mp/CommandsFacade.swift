//
// CommandsFacade.swift
//  mp
//
//  Created by Benoit Pereira da silva on 15/12/2018.
//

import AppKit
import Globals
import MPLib
import NavetLib

public let CLI_VERSION: String = "1.0.11"

public struct CommandsFacade {

    static let args = Swift.CommandLine.arguments
    let executableName = NSString(string: args.first!).pathComponents.last!
    let firstArgumentAfterExecutablePath: String = (args.count >= 2) ? args[1] : ""
    
    let echo: String = args.joined(separator: " ")
    
    public func actOnArguments() {
        let _ = getElapsedTime()
        switch firstArgumentAfterExecutablePath {
        case nil:
            print(self._noArgMessage())
            exit(EX_NOINPUT)
        case "-h", "-help", "h", "help":
            print(self._noArgMessage())
            exit(EX_USAGE)
        case "-version", "--version", "v", "version":
            print("CLI: \(CLI_VERSION) MPLib:\(MPLib_VERSION) NavetLib:\(Navet.version)")
            exit(EX_USAGE)
        case "echo", "--echo":
            print(echo)
            exit(EX_USAGE)
        case "detect-shots", "shots" :
            let _ = DetectShotsCommand()
        case "services":
            let _ = ServicesCommand()
        case "generate-video","navet":
            let _ = NavetGenerate()
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
                "detect-shots","shots",
                "services",
                "generate-video","navet"
            ]
            let bestCandidate = self.bestCandidate(string: firstArgumentAfterExecutablePath, reference: reference)
            print("Hey ...\"\(self.executableName) \(firstArgumentAfterExecutablePath)\" is unexpected!")
            print("Did you mean:\"\(self.executableName) \(bestCandidate)\"?")
            exit(EX__BASE)
        }
    }
    
    private func _noArgMessage() -> String {
        var s=""
        s += "\(self.executableName) is a video oriented Media Processor Command Line tool"
        s += "\nCreated by Benoit Pereira da Silva https://pereira-da-silva.com"
        s += "\nvalid calls are composed of sub commands like:\"\(self.executableName) <subcommand> [options]\""
        s += "\n"
        s += "\n\(self.executableName) help"
        s += "\n\(self.executableName) version"
        s += "\n\(self.executableName) echo <args>"
        s += "\n"
        s += "\nYou can call help for each subcommand e.g:\t\"\(self.executableName) shots help\""
        s += "\n"
        s += "\nAvailable sub command:"
        s += "\n"
        s += "\n\(self.executableName) detect-shots -i <input file or url> -o <output file or url> [options]"
        s += "\n\(executableName) generate-video -d <duration> -f <fps> [options]"
        s += "\n\(self.executableName) services --initialize -o <output file url> -v"
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
