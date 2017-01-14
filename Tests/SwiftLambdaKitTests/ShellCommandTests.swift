import XCTest
@testable import SwiftLambdaKit

class ShellCommandTests: XCTestCase {
    func testSimpleCommand() {
        var lines: [String] = []

        _ = ShellCommand.command(command: "yes | head -n3", stdout: { line in
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
