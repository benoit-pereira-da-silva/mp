//
//  ImagesComparer.swift
//  mp
//
//  Created by Benoit Pereira da silva on 15/12/2018.
//

import AppKit
import Globals


// This Comparator uses CoreImage to perform high performance image comparison.
//
// You should use CIImage if possible or CGImage
// CoreImage Conceptual overview
// https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_intro/ci_intro.html
// CoremImage filter reference
// https://developer.apple.com/library/content/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html
class ImagesComparator: NSObject {
    
    static public var maxWidth:CGFloat = 512
    
    static public var maxHeight:CGFloat = 512

    // MARK: CoreGraphics

    /// High level comparison method that may combinate multiple algoritms
    ///
    /// - Parameters:
    ///   - leftImage: the CGImage image on the left
    ///   - rightImage: the CGImage image on the right
    /// - Returns: return a value from 0 t0 255 where 0 is full match
    static public func measureDifferenceBetween( leftImage : CGImage, rightImage : CGImage) -> Int{
        return ImagesComparator._measureDifferenceBetween(leftImage: CIImage(cgImage:leftImage), rightImage: CIImage(cgImage:rightImage))
    }
    
    
    static public func resize(image: CGImage, maxWidth: CGFloat = ImagesComparator.maxWidth,maxHeight: CGFloat = ImagesComparator.maxHeight) -> CGImage? {
        var scaleFactor: CGFloat = 0.0
        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)
        
        if (imageWidth > imageHeight) {
            scaleFactor = maxWidth / imageWidth
        } else {
            scaleFactor = maxHeight / imageHeight
        }
        if scaleFactor > 1 {
            scaleFactor = 1
        }
        let width = imageWidth * scaleFactor
        let height = imageHeight * scaleFactor
        
        guard let colorSpace = image.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: image.bitsPerComponent, bytesPerRow: image.bytesPerRow, space: colorSpace, bitmapInfo: image.alphaInfo.rawValue) else { return nil }
        
        // draw image to context (resizing it)
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: Int(width), height: Int(height)))
        
        // extract resulting image from context
        return context.makeImage()
    }
    

    // MARK: CoreImage
    
    
    /// High level comparison method that may combinate multiple algoritms
    ///
    /// - Parameters:
    ///   - leftImage: the image on the left
    ///   - rightImage: the image on the right
    /// - Returns: return a value from 0 t0 255 where 0 is full match
    static public func measureDifferenceBetween( leftImage : CIImage, rightImage : CIImage) -> Int{
        return ImagesComparator._measureDifferenceBetween(leftImage: leftImage, rightImage: rightImage)
    }
    
    // MARK: - CoreImage Computation
    
    static private func _measureDifferenceBetween (leftImage : CIImage, rightImage : CIImage) -> Int {
        return ImagesComparator._blendedAverage(leftImage: leftImage, rightImage: rightImage)
    }
    
    
    static private func _blendedAverage (leftImage : CIImage, rightImage : CIImage) -> Int {
        
        // blend the two images
        let differenceFilter = CIFilter(name: "CIDifferenceBlendMode")
        differenceFilter?.setDefaults()
        differenceFilter?.setValue(leftImage, forKey: kCIInputImageKey)
        differenceFilter?.setValue(rightImage, forKey: kCIInputBackgroundImageKey)
        
        let averageFilter = CIFilter(name: "CIAreaAverage")
        averageFilter?.setDefaults()
        averageFilter?.setValue(differenceFilter?.outputImage, forKey: kCIInputImageKey)
        // NOTE: I find it's useful to come back in at least one pixel from the edges
        // as sometimes you get a white line at the edge the combined result
        let compareRect = CGRect(x: 0, y: 0, width: leftImage.extent.width-1, height: leftImage.extent.height-1)
        let extents = CIVector(cgRect: compareRect)
        averageFilter?.setValue(extents, forKey: kCIInputExtentKey)
        
        // Create the CIContext to draw into
        let space  = CGColorSpaceCreateDeviceRGB()
        let bminfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        var pixelBuffer = Array<CUnsignedChar>(repeating: 255, count: 16)
        let cgCont = CGContext(data: &pixelBuffer, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 16, space: space, bitmapInfo: bminfo.rawValue)
        let contextOptions : [CIContextOption:Any]? = [ CIContextOption.workingColorSpace  : space, CIContextOption.useSoftwareRenderer  : true]
        let myContext = CIContext(cgContext: cgCont!, options: contextOptions)
        
        averageFilter?.setValue(extents, forKey: kCIInputExtentKey)
        
        // render that final single pixel result
        myContext.draw((averageFilter?.outputImage)!, in: CGRect(x:0,y:0,width:1,height:1), from: CGRect(x:0,y:0,width:1,height:1))
        
        let r = Int(pixelBuffer[0])
        let g = Int(pixelBuffer[1])
        let b = Int(pixelBuffer[2])
        
        // Take the best component.
        return min(r,g,b)
    }
}

