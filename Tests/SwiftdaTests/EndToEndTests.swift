import XCTest
@testable import SwiftdaKit

class EndToEndTests: XCTestCase {
    func testSimple() {
        InitCommand().command(name: "e2e-test")

        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath

        fm.changeCurrentDirectoryPath("e2e-test")
        let lambdaDir = fm.currentDirectoryPath

        defer {
            fm.changeCurrentDirectoryPath(cwd)
            try! fm.removeItem(atPath: lambdaDir)
        }

        BuildCommand().command()
        DeployCommand().command(newVersion: false)

        let output = InvokeCommand().invoke(async: false, local: false)
        XCTAssert(output.range(of: "Hello, world!") != nil)

        DestroyCommand().command()
    }

    static var allTests: [(String, (EndToEndTests) -> () throws -> Void)] {
        return [
        ]
    }
}
