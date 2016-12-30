import XCTest
@testable import SwiftdaKit

class LineChunkerTests: XCTestCase {
    func testLinePerChunk() {
        var lines: [String] = []

        let chunker = LineChunker { line in
            print(line)
            lines.append(line)
        }

        chunker.append("hello\n")
        chunker.append(" world")
        if let rem = chunker.remainder() {
            lines.append(rem)
        }

        let expected = [
            "hello",
            " world"
        ]

        XCTAssertEqual(lines, expected)
    }

    func testSplitBetweenChunks() {
        var lines: [String] = []

        let chunker = LineChunker { line in
            print(line)
            lines.append(line)
        }

        chunker.append("hel")
        chunker.append("lo\n world")
        if let rem = chunker.remainder() {
            lines.append(rem)
        }

        let expected = [
            "hello",
            " world"
        ]

        XCTAssertEqual(lines, expected)
    }

    static var allTests: [(String, (LineChunkerTests) -> () throws -> Void)] {
        return [
        ]
    }
}
