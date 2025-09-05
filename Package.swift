// swift-tools-version:6.1.0

import PackageDescription

let package = Package(
  name: "ChatistSdk",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    .library(
      name: "ChatistSdk",
      targets: ["ChatistSdk"]
    )
  ],
  targets: [
    .binaryTarget(
      name: "ChatistSdk",
      path: "ChatistSdk.xcframework"
    )
  ],
  swiftLanguageModes: [.v6]
) 