import XCTest

internal func XCTAssertEqualTrimmingWhiteSpace(_ s1: String, _ s2: String,
                                               file: StaticString = #file,
                                               line: UInt = #line) {
    XCTAssertEqual(
        s1.trimmingCharacters(in: .whitespacesAndNewlines),
        s2.trimmingCharacters(in: .whitespacesAndNewlines),
        file: file, line: line)
}
