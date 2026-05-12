//
//  AppAsyncImage.swift
//  SwiftImageDownloader
//
//  Created by Ratnesh Jain on 17/01/25.
//


import Foundation
import SwiftUI
import FetchingView
import ImageDownloader

/// An Async Image view using a Application specific caching mechanics.
///
/// This is also handling the in progress and error state using `FetchingView`.
/// In case of the reuse, `.onChange(of: url)` handles it properly.
/// When the view is disappearing it will also cancel the in-flight download task to prevent resources.

@MainActor
@Observable
final class AppAsyncImageStore {
    let downloader: ImageDownloaderInstance
    var fetchingState: FetchingState<PlatformImage> = .idle
    
    init(downloader: ImageDownloaderInstance) {
        self.downloader = downloader
    }
    
    func fetch(url: URL) async {
        guard self.fetchingState == .idle else { return }
        do {
            self.fetchingState = .fetching
            let image = try await downloader.download(url: url)
            self.fetchingState = .fetched(image)
        } catch is CancellationError {
            await self.cancel(url: url)
            self.fetchingState = .idle
        } catch {
            self.fetchingState = .error(message: error.localizedDescription)
        }
    }
    
    func cancel(url: URL) async {
        await downloader.cancel(url: url)
    }
    
    func clearCache(url: URL) async {
        await downloader.clearCache(urls: [url])
    }
}

public struct AppAsyncImage: View {
    let url: URL
    let contentMode: ContentMode
    @State var store: AppAsyncImageStore
    
    /// An Async Image view using a Application specific caching mechanics.
    /// - Parameter url: A remote image address.
    public init(url: URL, contentMode: ContentMode = .fill, downloader: ImageDownloaderInstance = .defaultInstance) {
        self.url = url
        self.contentMode = contentMode
        self._store = .init(initialValue: .init(downloader: downloader))
    }
    
    public var body: some View {
        FetchingView(fetchingState: store.fetchingState) { image in
            Image(platformImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } onFetching: {
            ProgressView()
                .id(UUID())
        } onError: {
            ImageErrorView()
        }
        .task(id: url) {
            await store.fetch(url: url)
        }
        .onDisappear {
            Task {
                await store.clearCache(url: url)
            }
        }
        .id(url)
    }
    
    struct ImageErrorView: View {
        var body: some View {
            VStack {
                Image(systemName: "exclamationmark.circle.fill")
            }
            .background(Color.accentColor.opacity(0.1))
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
