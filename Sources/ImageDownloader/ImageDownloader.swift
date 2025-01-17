//
//  ImageDownloader.swift
//  SwiftImageDownloader
//
//  Created by Ratnesh Jain on 17/01/25.
//

import Foundation
#if os(iOS)
import UIKit
#endif
import OSLog

#if os(macOS)
import AppKit
#endif

/// An Image Download actor.
///
/// This will download the image from the web server and manages the local and filesystem cache.
///
/// The main reason to use an `actor` for the `ImageDownloader` is that it can be called for
/// multiple images at the same time and can be called from multiple threads.
///
/// This will prevent the data-race for the local `caches` variable since it can be read-write from
/// multiple threads/queues incorporated by cooperative thread pool used by `Task`.
///

actor ImageDownloader {
    
    /// `TaskState` allow use to keep track of on-going (in-flight) image downloading task and
    ///  a completed task.
    enum TaskState {
        case inProgress(Task<PlatformImage, Error>)
        case ready(PlatformImage)
        
        /// `readyImage` property can be used to directly return the recently downloaded image
        ///  before checking the local file system cache.
        var readyImage: PlatformImage? {
            guard case let .ready(image) = self else {
                return nil
            }
            return image
        }
    }
    
    class CacheEntry {
        var state: TaskState
        
        init(state: TaskState) {
            self.state = state
        }
    }
    
    class ColorEntry {
        var colorValue: ColorValue
        
        init(colorValue: ColorValue) {
            self.colorValue = colorValue
        }
    }
    
    #if !os(tvOS)
    /// A common path for the local file system cache directory path.
    private let localBaseURL = URL.documentsDirectory.appending(path: "Images")
    #endif
    
    /// A local dictionary to store the current download task state with corresponding to the remote url.
    private var cache: NSCache<NSString, CacheEntry> = .init()
    
    private var colorCache: NSCache<NSString, ColorEntry> = .init()

    /// Downloads the image from the remote url.
    /// - Parameter url: Remote server address for the target image.
    /// - Returns: An `UIImage` type if its exist from local cache or from file system cache or by
    /// downloading from the remote server address.
    func download(url: URL) async throws -> PlatformImage {
        
        // Check for the in-memory cache, this is cheapter then file system
        // reading, incresing the overall app performance.
        if let readyImage = self.cache[url]?.readyImage {
            log("Image is available in the in memory cache for: \(url)")
            return readyImage
        }
        
        #if !os(tvOS)
        // If the in-memory cache does not have a downloaded image, then checking
        // for the local file system for the stored image.
        // This is cheapter then the remote server image download.
        if let localImage = self.localImage(for: url) {
            log("In memory cache is empty but found image on the file system for: \(url)")
            self.cache[url] = .ready(localImage)
            self.colorCache[url] = localImage.averageColor
            return localImage
        }
        #endif
        
        // if both in-memory downloaded and file-system cache does not have an entry for the
        // requested image, we check for the if there is an on-going download task available,
        // if yes, we wait for its result and cache them in both in-memory and file-system.
        // else if the image is downloaded but did not store in the file-system, we store it
        // in file-system.
        if let cacheEntry = cache[url] {
            log("Both in-memory cache and file system is empty, so checking if its currently downloading for: \(url)")
            switch cacheEntry {
            case .inProgress(let task):
                let image = try await task.value
                self.cache[url] = .ready(image)
                self.colorCache[url] = image.averageColor
                #if !os(tvOS)
                try self.store(image: image, for: url)
                #endif
                return image
                
            case .ready(let image):
                #if !os(tvOS)
                try self.store(image: image, for: url)
                #endif
                return image
            }
        }
        
        log("New image download request for url: \(url)")
        // if all cache (in-memory and file-system) and in-flight task does not exists,
        // we create a `Task` to download the image data from the remote server url.
        let task = Task<PlatformImage, Error> {
            return try await downloadImage(url: url)
        }
        
        // We store the in task in inProgress state to cache.
        self.cache[url] = .inProgress(task)
        
        // We wait for the task's result and store in in-memory and file-system if it is successfull
        // else we clear the in-memory cache entry to nil, this will allow the system to re-try when
        // the image is requested again in future.
        do {
            let image = try await task.value
            self.cache[url] = .ready(image)
            self.colorCache[url] = image.averageColor
            #if !os(tvOS)
            try self.store(image: image, for: url)
            #endif
            return image
        } catch {
            self.cache[url] = nil
            self.colorCache[url] = nil
            throw error
        }
    }
    
    func imageColor(for url: URL) -> ColorValue? {
        if let color = self.colorCache[url] {
            self.logger.debug("Found the color cache for url: \(url)")
            return color
        } else {
            let color = self.cache[url]?.readyImage?.averageColor
            self.colorCache[url] = color
            self.logger.debug("Not Found the color cache for url: \(url), so created new entry!")
            return color
        }
    }
    
    /// Cancels the in-flight image download task.
    /// - Parameter url: Remote server address for the image from which we track the current in-flight download task.
    func cancel(url: URL) {
        if let cacheEntry = self.cache[url] {
            if case .inProgress(let task) = cacheEntry {
                task.cancel()
                log("Cancelled image downloading for: \(url)")
            }
            self.cache[url] = nil
            self.colorCache[url] = nil
        }
    }
    
    /// Download Image from the Remote server address.
    /// - Parameter url: Remote server address for Image.
    /// - Returns: `UIImage` from the URLSession data task.
    private func downloadImage(url: URL) async throws -> PlatformImage {
        log("Downloading image from the remote server: \(url)")
        let (data, _) = try await URLSession.shared.data(from: url)
        if let image = PlatformImage(data: data) {
            return image
        } else {
            struct ImageError: LocalizedError {
                var message: String
                var errorDescription: String? { message }
            }
            throw ImageError(message: "Can not get image from the url")
        }
    }
    
    #if !os(tvOS)
    /// URL for file-system directory for local cache.
    /// - Parameter url: Remote server address of Image.
    /// - Returns: Local file-system url
    private func localImageURL(for url: URL) -> URL {
        let component = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let path = component?.path
        let queries = component?.queryItems?.compactMap({$0.description}).joined()
        let localPath = [path, queries].compactMap({$0}).joined()
        return self.localBaseURL.appending(path: localPath)
    }
    
    /// Image from the local file-system.
    /// - Parameter url: Remote server address of Image
    /// - Returns: `UIImage` object from the local file-system path.
    private func localImage(for url: URL) -> PlatformImage? {
        let localUrl = self.localImageURL(for: url)
        log("Checking file system for \nRemoteURL: \(url), \nLocalURL:\(localUrl.path())")
        return PlatformImage(contentsOfFile: localUrl.path())
    }
    
    /// Stores the downloaded image from the remote server address for image.
    /// - Parameters:
    ///   - image: Downloaded Image.
    ///   - url: Remote server address for Image. Used as a key to get the file-system url.
    private func store(image: PlatformImage, for url: URL) throws {
        let localURL = localImageURL(for: url)
        try? FileManager.default.createDirectory(at: localURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try image.data?.write(to: localURL)
        log("Stored image to file system for remote \nurl: \(url), \nlocalURL: \(localURL)")
    }
    #endif
    
    private var logger = Logger(subsystem: "ImageDownloader", category: "ImageDownloader")
    
    private func log(_ message: String) {
        #if DEBUG
        logger.debug("\(message)")
        #endif
    }
    
    func clearCache(urls: [URL]) {
        for url in urls {
            self.cache[url] = nil
            self.colorCache[url] = nil
        }
        log("Cleared cache for urls: \(urls)")
    }
}
