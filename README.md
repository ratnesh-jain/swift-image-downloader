# Swift Image Downloader
This swift package provides a easy to use APIs for downloading and Caching of remote images.

## Installation
```swift
dependencies: [
  .package(url: "https://github.com/ratnesh-jain/swift-image-downloader", .upToNextMajor("0.0.1")
]
```

## Compatibility
- Swift 6
- iOS 17+
- macOS 15+

This package offers 3 libraries:
1. ImageDownloader
2. AppAsyncImage for SwiftUI
3. AsyncImageView for UIKit

## ImageDownloader
ImageDownloader allows to download and cache the remote images using simple APIs. For caching simple NSCache instance is used.

```swift
import ImageDownloader

AppImageDownloader.download(url: URL) async throws -> PlatformImage
AppImageDownloader.cancel(url: URL) async
AppImageDownloader.downloadAndCache(urls: [URL]) async throws
AppImageDownloader.clearCache(urls: [URL]) async
AppImageDownloader.color(for url: URL) async -> ColorValue?
```

User can use these apis for directly downloading/caching of the remote images without depending of the View type (i.e. AppAsyncImage, AsyncImageView) in there view models or other architectural structure.

### ColorValue
ColorValue is a simple `Equatable` and `Sendable` type to hold RGBA value of Color information.
This library calculates and caches the average color from an Image using `CIAreaAverage` CIFilter.

## AppAsyncImage for SwiftUI
AppAsyncImage is a SwiftUI View to display a remote image using URL.
```swift
import AppAsyncImage
import SwiftUI

struct ContentView: View {
  let url: URL
  var body: some View {
    AppAsyncImage(url: url)
  }
}
```
For reusability in scrolling context, it observe the url changes using `.onChangeOf(url)` viewModifier. 
`AppAsyncImage` also handles cancelling of the ongoing download process for user of this library.

Be default, `AppAsyncImage` uses a simple `ProgressView()` for its fetching state (via [FetchingView](https://github.com/ratnesh-jain/swiftui-fetching-view))
But this can be customized like:
```swift
import AppAsyncImage
import FetchingView
import SwiftUI

struct ContentView: View {
  let url: URL
  var body: some View {
    AppAsyncImage(url: url)
      .fetchingStateView {
        Image(systemName: "photo")
          .foregroundStyle(.secondary)
      }
  }
}
```

User is free to use any SwiftUI View for the content of `.fetchingStateView` i.e. Lottie's AnimationView or any other decorative Views.

## SwiftUI Example for AppAsyncImage
```swift
import AppAsyncImage
import FetchingView
import SwiftUI

struct ContentView: View {
    var images: [URL] = Array(1...100).compactMap {
        URL(string: "https://picsum.photos/id/\($0)/200/250")
    }
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], content: {
                ForEach(images, id: \.self) { url in
                    AppAsyncImage(url: url)
                }
            })
            .padding()
        }
        .fetchingStateView {
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
                .font(.system(size: 120))
                .overlay {
                    ProgressView()
                }
                .frame(maxWidth: .infinity)
                .background(.background.secondary)
        }
    }
}

#Preview {
    ContentView()
        #if os(macOS)
        .frame(minWidth: 1024, minHeight: 720)
        #endif
}
```

### Preview for iOS
<img width="300" alt="Screenshot 2025-01-18 at 12 59 10 PM" src="https://github.com/user-attachments/assets/aaf61b7a-3ec6-4cb1-9d8b-49619c7cfb0e" />

### Preview for macOS

<img width="550" alt="Screenshot 2025-01-18 at 1 00 24 PM" src="https://github.com/user-attachments/assets/b2ae3cd2-4ffd-4ee8-a94e-372ac1ea822f" />

## AsyncImageView for UIKit
```swift
import AsyncImageView
import UIKit

class ViewController: UIViewController {
  var imageView: AsyncImageView = {
    let imageView = AsyncImageView()
    return imageView
  }()

  func configure(url: URL) {
    self.imageView.url = url
  }

  // For using inside a scrollable container cell i.e. UTableViewCell, UICollectionViewCell
  func prepareForReuse() {
    self.imageView.prepareForReuse()
  }
}
```

### UIKit Example for AsyncImageView
<details>
    <summary>Open Example</summary>

```swift
#if canImport(UIKit)
import Foundation
import AsyncImageView

import UIKit

class ViewController: UIViewController {

  var items: [URL] = Array(1...100).compactMap {
      URL(string: "https://picsum.photos/id/\($0)/200/200")
  }

  enum Section: Hashable {
      case main
  }

  private var layout: UICollectionViewCompositionalLayout = {
      let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(1/2))
      let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/2), heightDimension: .fractionalHeight(1))
      let item = NSCollectionLayoutItem(layoutSize: itemSize)
      let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
      group.interItemSpacing = .fixed(8)
      let section = NSCollectionLayoutSection(group: group)
      section.interGroupSpacing = 8
      section.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
      let layout = UICollectionViewCompositionalLayout(section: section)
      return layout
  }()

  private lazy var collectionView: UICollectionView = {
      let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
      collectionView.register(ImageCell.self, forCellWithReuseIdentifier: String(describing: ImageCell.self))
      return collectionView
  }()

  private lazy var dataSource: UICollectionViewDiffableDataSource<Section, URL> = {
      UICollectionViewDiffableDataSource<Section, URL>(collectionView: self.collectionView) { collectionView, indexPath, itemIdentifier in
          let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImageCell.self), for: indexPath) as? ImageCell
          cell?.configure(url: itemIdentifier)
          return cell
      }
  }()

  override func viewDidLoad() {
      super.viewDidLoad()
      configureViews()
      applySnapshot()
  }

  private func configureViews() {
      self.view.addSubview(collectionView)
      collectionView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
          collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
          collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
          collectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
          collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
      ])
  }

  private func applySnapshot() {
      var snapshot = NSDiffableDataSourceSnapshot<Section, URL>()
      snapshot.appendSections([.main])
      snapshot.appendItems(items, toSection: .main)
      self.dataSource.apply(snapshot)
  }

  class ImageCell: UICollectionViewCell {
      private lazy var imageView: AsyncImageView = {
          let imageView = AsyncImageView()
          return imageView
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
          self.contentView.addSubview(imageView)
          imageView.translatesAutoresizingMaskIntoConstraints = false
          NSLayoutConstraint.activate([
              imageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
              imageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
              imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
              imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
          ])
      }
    
      func configure(url: URL) {
          self.imageView.url = url
      }
        
      override func prepareForReuse() {
          super.prepareForReuse()
          self.imageView.prepareForReuse()
      }
   }
}

#Preview {
  ViewController()
}

#endif
```
</details>
