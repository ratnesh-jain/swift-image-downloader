//
//  MacImage.swift
//  SwiftImageDownloader
//
//  Created by Ratnesh Jain on 17/01/25.
//


import Foundation
#if os(macOS)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

import SwiftUI

#if os(macOS)
@dynamicMemberLookup
public struct MacImage: @unchecked Sendable, Equatable {
    public var image: NSImage
    
    public subscript<T>(dynamicMember keypath: KeyPath<NSImage, T>) -> T {
        self.image[keyPath: keypath]
    }
    
    public init(image: NSImage) {
        self.image = image
    }
    
    public init?(data: Data) {
        guard let image = NSImage(data: data) else { return nil }
        self.image = image
    }
    
    public init?(contentsOfFile path: String) {
        guard let image = NSImage(contentsOfFile: path) else { return nil }
        self.image = image
    }
    
    public init?(contentsOf url: URL) {
        guard let image = NSImage(contentsOf: url) else { return nil }
        self.image = image
    }
    
    public var data: Data? {
        guard let tiffData = self.image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}
public typealias PlatformImage = MacImage
#else
public typealias PlatformImage = UIImage
#endif

#if canImport(UIKit)
extension UIImage {
    public var data: Data? {
        self.pngData() ?? self.jpegData(compressionQuality: 0.9)
    }
}
#endif

extension Image {
    public init(platformImage: PlatformImage) {
        #if os(macOS)
        self.init(nsImage: platformImage.image)
        #else
        self.init(uiImage: platformImage)
        #endif
    }
}
