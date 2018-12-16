//
//  VideoSource.swift
//  mp
//
//  Created by Benoit Pereira da silva on 16/12/2018.
//

import Foundation

public struct VideoSource : Codable{

    let url: URL
    let token: String?
    let fps: Double
    let width: Double
    let height: Double
    let duration: Double
    let origin: Double
    let originTimeCode: String

}
