//
//  AsyncImageView.swift
//  SwiftImageDownloader
//
//  Created by Ratnesh Jain on 17/01/25.
//

#if canImport(UIKit)
import Foundation
import FetchingView
import ImageDownloader
import UIKit

@dynamicMemberLookup
public class AsyncImageView: UIView {
    public var url: URL? {
        didSet {
            if let url {
                if let oldValue {
                    self.imageView.image = nil
                    Task { await AppImageDownloader.cancel(url: oldValue) }
                }
                self.configure(url: url)
            }
        }
    }
    
    public var onStateChange: ((FetchingState<UIImage>) -> Void)?
    
    public var placeholder: UIImage?
    
    public private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }
    
    private func configureViews() {
        self.addSubview(activityIndicatorView)
        self.addSubview(imageView)
        
        activityIndicatorView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        if let url {
            self.configure(url: url)
        }
    }
    
    private func configure(url: URL) {
        Task { @MainActor in
            self.activityIndicatorView.startAnimating()
            defer {
                self.activityIndicatorView.stopAnimating()
            }
            self.onStateChange?(.fetching)
            do {
                let image = try await AppImageDownloader.download(url: url)
                self.imageView.image = image
                self.onStateChange?(.fetched(image))
            } catch {
                self.imageView.image = placeholder
                self.onStateChange?(.error(message: error.localizedDescription))
            }
        }
    }
    
    public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<UIImageView, T>) -> T {
        self.imageView[keyPath: keyPath]
    }
    
    public func prepareForReuse() {
        self.imageView.image = nil
        self.url = nil
    }
}
#endif
