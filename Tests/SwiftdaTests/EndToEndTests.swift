import XCTest
@testable import SwiftdaKit

class EndToEndTests: XCTestCase {
    func testSimple() throws {
        try SetupCommand().command()
        
        InitCommand().command(name: "e2e-test")

        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath

        fm.changeCurrentDirectoryPath("e2e-test")
        let lambdaDir = fm.currentDirectoryPath

        defer {
            fm.changeCurrentDirectoryPath(cwd)
            try! fm.removeItem(atPath: lambdaDir)
        }

        try BuildCommand().command()
        try DeployCommand().command(newVersion: false)

        let output = try InvokeCommand().invoke(async: false, local: false)
        XCTAssert(output.tail.range(of: "Hello, World") != nil)

        try DestroyCommand().command()
    }

    static var allTests: [(String, (EndToEndTests) -> () throws -> Void)] {
        return [
        ]
    }
}
