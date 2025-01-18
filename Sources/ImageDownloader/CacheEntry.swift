//
//  CacheEntry.swift
//  SwiftImageDownloader
//
//  Created by Ratnesh Jain on 17/01/25.
//

import Foundation

class CacheEntry {
    var state: ImageDownloader.TaskState
    
    init(state: ImageDownloader.TaskState) {
        self.state = state
    }
}

extension NSCache where KeyType == NSString, ObjectType == CacheEntry  {
    subscript(url: URL) -> ImageDownloader.TaskState? {
        get {
            let key = url.absoluteString as NSString
            let value = self.object(forKey: key)
            return value?.state
        }
        set {
            let key = url.absoluteString as NSString
            if let state = newValue {
                let value = CacheEntry(state: state)
                self.setObject(value, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }
}

class ColorEntry {
    var colorValue: ColorValue
    
    init(colorValue: ColorValue) {
        self.colorValue = colorValue
    }
}

extension NSCache where KeyType == NSString, ObjectType == ColorEntry {
    subscript(url: URL) -> ColorValue? {
        get {
            let key = url.absoluteString as NSString
            let value = self.object(forKey: key)
            return value?.colorValue
        }
        set {
            let key = url.absoluteString as NSString
            if let newValue {
                self.setObject(.init(colorValue: newValue), forKey: key)
            } else {
                self.removeObject(forKey: key)
            }
        }
    }
}
