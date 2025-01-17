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
public struct AppAsyncImage: View {
    let url: URL
    @State private var fetchingState: FetchingState<PlatformImage> = .fetching
    
    /// An Async Image view using a Application specific caching mechanics.
    /// - Parameter url: A remote image address.
    public init(url: URL) {
        self.url = url
    }
    
    public var body: some View {
        FetchingView(fetchingState: fetchingState) { image in
            Image(platformImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } onError: { message in
            VStack {
                Image(systemName: "exclamationmark.circle.fill")
            }
            .background(Color.accentColor.opacity(0.1))
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: url, { oldValue, newValue in
            Task {
                await AppImageDownloader.cancel(url: oldValue)
                await fetchImage(url: newValue)
            }
        })
        .onAppear {
            Task {
                await fetchImage(url: url)
            }
        }
        .onDisappear {
            Task {
                await AppImageDownloader.cancel(url: url)
            }
        }
    }
    
    /// Downloads the Image from the Remote image address using the `ImageDownloader` actor.
    /// This will also handle the image fetching state via `fetchingState`.
    /// - Parameter url: An Remote Image address.
    private func fetchImage(url: URL) async {
        guard self.fetchingState.value == nil else { return }
        do {
            self.fetchingState = .fetching
            let image = try await AppImageDownloader.download(url: url)
            self.fetchingState = .fetched(image)
        } catch {
            self.fetchingState = .error(message: error.localizedDescription)
        }
    }
}
