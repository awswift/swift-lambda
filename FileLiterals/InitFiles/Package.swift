import PackageDescription

let package = Package(
    name: "<name>",
    dependencies: [
        // .Package(url: "https://github.com/awswift/awswift", majorVersion: 0, minor: 3)
        .Package(url: "https://github.com/awswift/swiftda-runtime", majorVersion: 0, minor: 1)
    ]
)
