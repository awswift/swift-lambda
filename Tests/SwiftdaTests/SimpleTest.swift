import XCTest

class SimpleTest: XCTestCase {
    func testSimple() {
        XCTAssert(1 == 1)
    }

    static var allTests: [(String, (SimpleTest) -> () throws -> Void)] {
        return [
        ]
    }
}
