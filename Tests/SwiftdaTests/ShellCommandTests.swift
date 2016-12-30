import XCTest
@testable import SwiftdaKit

class ShellCommandTests: XCTestCase {
    func testSimpleCommand() {
        var lines: [String] = []

        let cmd = ShellCommand.command(command: "yes | head -n3", stdout: { line in
            lines.append(line)
        }) { line in
            XCTFail("Should not receive any stderr from command")
        }

        let expected = [
            "y",
            "y",
            "y"
        ]

        XCTAssertEqual(lines, expected)
    }

    static var allTests: [(String, (ShellCommandTests) -> () throws -> Void)] {
        return [
        ]
    }
}
