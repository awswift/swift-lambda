import PackageDescription

let package = Package(
    name: "<name>",
    dependencies: [
        .Package(url: "https://github.com/awswift/awswift", majorVersion: 0, minor: 2)
    ]
)
