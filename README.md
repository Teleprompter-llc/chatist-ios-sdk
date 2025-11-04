# ChatistSdk

![Version](https://img.shields.io/badge/version-0.1.9-blue)
![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey)
![Swift](https://img.shields.io/badge/swift-6.0-orange)

A Swift SDK for integrating Chatist customer support into your iOS applications.

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Teleprompter-llc/chatist-ios-sdk.git", from: "0.1.9")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/Teleprompter-llc/chatist-ios-sdk.git`
3. Select version `0.1.9` or later
4. Click Add Package

## Requirements

- iOS 17.0+
- Xcode 16.4+
- Swift 6.0+

## Usage

### Basic Setup

```swift
import ChatistSdk

// Initialize the SDK
let config = ChatistConfig(
    apiKey: "your-api-key",
    organizationSlug: "your-org",
    productSlug: "your-product"
)

Chatist.configure(with: config)
```

### Presenting the Chat Interface

```swift
import SwiftUI
import ChatistSdk

struct ContentView: View {
    var body: some View {
        VStack {
            Button("Open Support Chat") {
                Chatist.present()
            }
        }
    }
}
```

## Documentation

For detailed documentation and examples, visit our [developer documentation](https://docs.chatist.com).

## Version History

- **0.1.9** - Built from commit [1a81cf0d39752ecb9978f19f0e0ab263d11e7f17](https://github.com/Teleprompter-llc/customer-support/commit/1a81cf0d39752ecb9978f19f0e0ab263d11e7f17)

## License

This SDK is distributed under a commercial license. See the LICENSE file for details.

## Support

For technical support, please contact our team or create a support ticket through the Chatist platform.
