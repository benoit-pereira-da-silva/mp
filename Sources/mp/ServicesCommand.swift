//
//  ServicesCommand.swift
//  mp
//
//  Created by Benoit Pereira da silva on 18/12/2018.
//

import Foundation
import Cocoa
import Globals
import CommandLineKit
import Tolerance
import HTTPClient

class ServicesCommand: CommandBase {

    required init() {

        super.init()

        let initialize = BoolOption(shortFlag: "i", longFlag: "initialize", required: false,
                                 helpMessage: "Creates a file configuraiton to be used by mp to access to external APIs")

        let outputPath = StringOption(shortFlag: "f", longFlag: "file-path", required: true,
                                  helpMessage: "The configuration file path")

        let verbose = BoolOption(shortFlag: "v", longFlag: "verbose", required: false,
                                 helpMessage: "If verbose some progress messages will be displayed in the standard output.")

        self.addOptions(options: initialize, outputPath, verbose)
        if self.parse() {
            self.isVerbose  = verbose.value
            if let input: String = outputPath.value{
                let url : URL = URL(fileURLWithPath: input)
                if initialize.value == true {

                    // Create the AuthContext configuration file.

                    let identityServerBaseURL:URL = URL(string: "https://your-identity-server.com")!
                    let apiServerBaseURL:URL = URL(string: "https://your-api-server.com")!

                    let login:RequestDescriptor = RequestDescriptor(baseURL:identityServerBaseURL.appendingPathComponent("/login"),
                                                                    method:.POST,
                                                                    argumentsEncoding:.httpBody(type:.form))

                    // There is no arguments currently to encode so we set Query string by default
                    let logout:RequestDescriptor = RequestDescriptor(baseURL:identityServerBaseURL.appendingPathComponent("/token"),
                                                                     method:.DELETE,
                                                                     argumentsEncoding:.queryString)

                    // There is no arguments currently to encode so we set Query string by default
                    let refresh:RequestDescriptor = RequestDescriptor(baseURL:identityServerBaseURL.appendingPathComponent("/refresh"),
                                                                      method:.GET,
                                                                      argumentsEncoding:.queryString)

                    let descriptors:AuthDescriptors = AuthDescriptors(login: login, logout: logout, refresh: refresh)

                    let context = AuthContext.init(identityServerBaseURL: identityServerBaseURL,
                                            apiServerBaseURL:apiServerBaseURL,
                                            descriptors:descriptors )
                    do{
                        let data :Data = try JSON.prettyEncoder.encode(context)
                        try data.write(to: url)
                        self.printAlways("Configuration file has been saved:\(url)")
                        exit(EX_OK)
                    }catch{
                        self.printAlways("\(error)")
                        exit(EX__BASE)
                    }
                }else{
                    exit(EX_OK)
                }
            }else{
                self.printIfVerbose("Invalid")
                exit(EX__BASE)
            }
        }
    }
}


