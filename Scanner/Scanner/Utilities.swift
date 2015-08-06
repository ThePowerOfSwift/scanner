//
//  File.swift
//  Scanner
//
//  Created by Tamás Zahola on 06/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import Foundation
import UIKit
import ImageIO

func thumbnailFromImage(path:String) -> UIImage? {
    let imageURL = NSURL(fileURLWithPath: path)!
    let imageSource = CGImageSourceCreateWithURL(imageURL, nil)
    let options:[String:AnyObject] = [
        kCGImageSourceCreateThumbnailWithTransform as String : true,
        kCGImageSourceCreateThumbnailFromImageIfAbsent as String : true,
        kCGImageSourceThumbnailMaxPixelSize as String : 256
    ]
    let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options)
    return UIImage(CGImage: thumbnail)
}