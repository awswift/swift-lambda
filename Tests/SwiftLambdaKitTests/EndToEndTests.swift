import XCTest
@testable import SwiftLambdaKit

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
        try DeployCommand().command(newVersion: false, skipLibs: false)

        let output = try InvokeCommand().invoke(async: false, local: false)
        XCTAssert(output.tail.range(of: "Hello, World") != nil)
        
        let logsOutput = try LogsCommand().logs(tail: false)
        XCTAssert(logsOutput.range(of: "Hello, World") != nil)

        try DestroyCommand().command()
    }

    static var allTests: [(String, (EndToEndTests) -> () throws -> Void)] {
        return [
        ]
    }
}
