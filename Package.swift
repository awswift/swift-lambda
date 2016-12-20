import PackageDescription

let package = Package(
    name: "Swiftda",
    dependencies: [
        .Package(url: "https://github.com/kylef/Commander", majorVersion: 0, minor: 5),
        .Package(url: "https://github.com/onevcat/Rainbow", majorVersion: 2),
        .Package(url: "https://github.com/SwiftyJSON/SwiftyJSON", majorVersion: 3)
    ]
)
