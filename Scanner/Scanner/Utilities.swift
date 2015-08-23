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

private let maxThumbnailSize:Int = 500

func CGSizeAspectRatio(size: CGSize) -> CGFloat {
    return size.width / size.height
}

func CGSizeScaledToFitSize(size: CGSize, sizeToFit: CGSize) -> CGSize {
    let sizeAspect = CGSizeAspectRatio(size)
    let sizeToFitAspect = CGSizeAspectRatio(sizeToFit)
    
    if sizeToFitAspect < sizeAspect {
        return CGSize(width: sizeToFit.width, height: sizeToFit.width / sizeAspect)
    } else {
        return CGSize(width: sizeToFit.height * sizeAspect, height: sizeToFit.height)
    }
}

func CGRectCenteredInRect(rect: CGRect, size: CGSize) -> CGRect {
    return CGRect(
        x: rect.origin.x + (rect.width - size.width) / 2,
        y: rect.origin.y + (rect.height - size.height) / 2,
        width: size.width,
        height: size.height)
}

func pointLineDistance(point:CGPoint, linePoint1:CGPoint, linePoint2:CGPoint) -> CGFloat {
    let numerator:CGFloat = fabs((linePoint2.y - linePoint1.y)*point.x - (linePoint2.x - linePoint1.x)*point.y + linePoint2.x*linePoint1.y - linePoint2.y*linePoint1.x)
    let denominator:CGFloat = sqrt((linePoint2.x - linePoint1.x)*(linePoint2.x - linePoint1.x) + (linePoint2.y - linePoint1.y)*(linePoint2.y - linePoint1.y))
    return numerator / denominator
}

func lloToUloTransformForHeight(height:CGFloat) -> CGAffineTransform {
    return CGAffineTransformTranslate(CGAffineTransformMakeScale(1, -1), 0, -height)
}

func imageToBitmapTransformForOrientation(orientation:UIImageOrientation, width:CGFloat, height:CGFloat) -> CGAffineTransform {
    switch orientation {
    case .Up:
        return CGAffineTransformIdentity
    case .UpMirrored:
        return CGAffineTransformTranslate(CGAffineTransformMakeScale(-1, 1), -width, 0)
    case .Down:
        return CGAffineTransformTranslate(CGAffineTransformMakeRotation(CGFloat(M_PI)), -width, -height)
    case .DownMirrored:
        return CGAffineTransformTranslate(CGAffineTransformScale(CGAffineTransformMakeRotation(CGFloat(M_PI)), -1, 1), 0, -height)
    case .Left:
        return CGAffineTransformTranslate(CGAffineTransformMakeRotation(CGFloat(M_PI / 2)), 0, -width)
    case .LeftMirrored:
        return CGAffineTransformScale(CGAffineTransformMakeRotation(CGFloat(M_PI / 2)), 1, -1)
    case .Right:
        return CGAffineTransformTranslate(CGAffineTransformMakeRotation(CGFloat(-M_PI / 2)), -height, 0)
    case .RightMirrored:
        return CGAffineTransformTranslate(CGAffineTransformScale(CGAffineTransformMakeRotation(CGFloat(-M_PI / 2)), 1, -1), -height, -width)
    }
}

func imageAtPath(path:String) -> UIImage? {
    return UIImage(contentsOfFile: path)
}

func imageAtPath(path:String, cropRect:CGRect) -> UIImage? {
    if let image = imageAtPath(path) {
        let cgImage = image.CGImage
        let width = CGImageGetWidth(cgImage)
        let height = CGImageGetHeight(cgImage)
        let cropRectInBitmapSpace = CGRectApplyAffineTransform(cropRect, imageToBitmapTransformForOrientation(image.imageOrientation, CGFloat(width), CGFloat(height)))
        let croppedImage = CGImageCreateWithImageInRect(cgImage, cropRectInBitmapSpace)
        return UIImage(CGImage: croppedImage, scale: image.scale, orientation: image.imageOrientation)
    } else {
        return nil
    }
}

func thumbnailFromImage(path:String, cropRect:CGRect) -> UIImage? {
    if let croppedImage = imageAtPath(path, cropRect) {
    
        let croppedCGImage = croppedImage.CGImage
        let width = CGImageGetWidth(croppedCGImage)
        let height = CGImageGetHeight(croppedCGImage)
        
        let thumbnailWidth:Int
        let thumbnailHeight:Int
        if width > height {
            thumbnailWidth = maxThumbnailSize
            thumbnailHeight = height * maxThumbnailSize / width
        } else {
            thumbnailWidth = width * maxThumbnailSize / height
            thumbnailHeight = maxThumbnailSize
        }
        
        let thumbnailContext = CGBitmapContextCreate(nil,
            thumbnailWidth,
            thumbnailHeight,
            CGImageGetBitsPerComponent(croppedCGImage),
            CGImageGetBytesPerRow(croppedCGImage),
            CGImageGetColorSpace(croppedCGImage),
            CGImageGetBitmapInfo(croppedCGImage))
        
        CGContextDrawImage(thumbnailContext, CGRect(x: 0, y: 0, width: thumbnailWidth, height: thumbnailHeight), croppedCGImage)
        
        let thumbnail = CGBitmapContextCreateImage(thumbnailContext)
        
        return UIImage(CGImage: thumbnail, scale: croppedImage.scale, orientation: croppedImage.imageOrientation)
    } else {
        return nil
    }
}