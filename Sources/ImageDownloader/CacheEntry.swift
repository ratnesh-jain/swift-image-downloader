//
//  CacheEntry.swift
//  SwiftImageDownloader
//
//  Created by Ratnesh Jain on 17/01/25.
//

import Foundation


extension NSCache where KeyType == NSString, ObjectType == ImageDownloader.CacheEntry  {
    subscript(url: URL) -> ImageDownloader.TaskState? {
        get {
            let key = url.absoluteString as NSString
            let value = self.object(forKey: key)
            return value?.state
        }
        set {
            let key = url.absoluteString as NSString
            if let state = newValue {
                let value = ImageDownloader.CacheEntry(state: state)
                self.setObject(value, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }
}

extension NSCache where KeyType == NSString, ObjectType == ImageDownloader.ColorEntry {
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
