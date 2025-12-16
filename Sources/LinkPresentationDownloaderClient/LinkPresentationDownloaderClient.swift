//
//  File.swift
//  SwiftImageDownloader
//
//  Created by Ratnesh Jain on 16/12/25.
//

import Dependencies
import DependenciesMacros
import DefaultDownloaderClient
import Foundation
import UniformTypeIdentifiers

#if canImport(LinkPresentation)
import LinkPresentation

extension DefaultDownloadClient {
    public static let linkPresentation: DefaultDownloadClient = {
        return DefaultDownloadClient { url in
            let provider = LPMetadataProvider()
            let metadata = try await provider.startFetchingMetadata(for: url)
            let image = try await metadata.imageProvider?.loadItem(forTypeIdentifier: UTType.data.identifier) as? Data
            let icon = try await metadata.iconProvider?.loadItem(forTypeIdentifier: UTType.data.identifier) as? Data
            return image ?? icon ?? Data()
        }
    }()
}

#endif
