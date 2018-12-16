//
//  CommandBase.swift
//  CommandlineKit
//
//  Created by Benoit Pereira da silva on 15/12/2018.
//
import Foundation
import CommandLineKit

protocol PrintDelegate {
    func printIfVerbose(_ message: Any)
    func printAlways(_ message: Any)
}

/// Base command implementing common behavior for all commands
public class CommandBase: PrintDelegate {
    
    public var isVerbose=true
    
    private static let _cli = CommandLine()

    init(){
        CommandBase._cli.usesSubCommands = true
    }
    
    func addOptions(options: Option...) {
        for o in options {
            CommandBase._cli.addOption(o)
        }
    }

    func parse() -> Bool {
        do {
            try CommandBase._cli.parse()
            return true
        } catch {
            CommandBase._cli.printUsage()
            exit(EX_USAGE)
        }
    }
    
    func printIfVerbose(_ message: Any) {
        if self.isVerbose {
            self.printAlways(message)
        }
    }
    
    /**
     Versatile print method.
     
     - parameter string: the message
     */
    func printAlways(_ message: Any) {
        print("\(message)")
    }
    
}
