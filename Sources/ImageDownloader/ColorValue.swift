//
//  ColorValue.swift
//  SwiftImageDownloader
//
//  Created by Ratnesh Jain on 17/01/25.
//


import Foundation
#if os(iOS)
import UIKit
#endif
import SwiftUI

public struct ColorValue: Equatable, Sendable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat
    
    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

#if os(iOS)
extension UIColor {
    public convenience init(value: ColorValue) {
        self.init(red: value.red, green: value.green, blue: value.blue, alpha: value.alpha)
    }
    
    public var colorValue: ColorValue {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return .init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif

#if os(macOS)
extension NSColor {
    public convenience init(value: ColorValue) {
        self.init(red: value.red, green: value.green, blue: value.blue, alpha: value.alpha)
    }
    
    public var colorValue: ColorValue {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return .init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif

extension Color {
    public init(value: ColorValue) {
        self.init(red: value.red, green: value.green, blue: value.blue, opacity: value.alpha)
    }
    
    public init(value: ColorValue?, default colorValue: Color) {
        if let value {
            self.init(red: value.red, green: value.green, blue: value.blue, opacity: value.alpha)
        } else {
            self = colorValue
        }
    }
}

#if os(iOS)
extension UIImage {
    public var averageColor: ColorValue? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extendVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extendVector]) else { return nil }
        guard let output = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(output, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        if bitmap[0] <= 22, bitmap[1] <= 22, bitmap[2] <= 22 {
            return UIColor.darkGray.colorValue
        }
        
        return .init(
            red: CGFloat(bitmap[0])/255,
            green: CGFloat(bitmap[1])/255,
            blue: CGFloat(bitmap[2])/255,
            alpha: CGFloat(bitmap[3])/255
        )
    }
}
#endif

#if os(macOS)
extension NSImage {
    public var averageColor: ColorValue? {
        guard let data = self.tiffRepresentation, let inputImage = CIImage(data: data) else { return nil }
        let extendVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extendVector]) else { return nil }
        guard let output = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(output, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        if bitmap[0] <= 22, bitmap[1] <= 22, bitmap[2] <= 22 {
            return NSColor.darkGray.colorValue
        }
        
        return .init(
            red: CGFloat(bitmap[0])/255,
            green: CGFloat(bitmap[1])/255,
            blue: CGFloat(bitmap[2])/255,
            alpha: CGFloat(bitmap[3])/255
        )

    }
}
#endif
