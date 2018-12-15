//
//  CommandBase.swift
//  mp
//
//  Created by Benoit Pereira da silva on 15/12/2018.
//
import Foundation
import CommandLineKit

/// Base command implementing common behavior for all commands
public class CommandBase{
    
    public var isVerbose=true
    
    private let _cli = CommandLine()

    
    func addOptions(options: Option...) {
        for o in options {
            _cli.addOption(o)
        }
    }

    func parse() -> Bool {
        do {
            try _cli.parse()
            return true
        } catch {
            _cli.printUsage()
            exit(EX_USAGE)
        }
    }
    
    func printVerbose(string: String) {
        if self.isVerbose {
            self.printVersatile(string: string)
        }
    }
    
    /**
     Versatile print method.
     
     - parameter string: the message
     */
    func printVersatile(string: String) {
        print(string)
    }
    
}
