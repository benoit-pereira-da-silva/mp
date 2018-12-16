//
//  main.swift
//  mp
//
//  Created by Benoit Pereira da silva on 15/12/2018.
//

import Foundation


// Instanciate the facade
let facade = CommandsFacade()
facade.actOnArguments()


var holdOn = true
let runLoop = RunLoop.current
while (holdOn && runLoop.run(mode: RunLoop.Mode.default, before: NSDate.distantFuture) ) {}
