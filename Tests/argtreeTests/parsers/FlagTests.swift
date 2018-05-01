import XCTest
@testable import argtree

final class FlagTests: XCTestCase {

    func testFlagParsing() {
        var parsed = false
        let flag = Flag(shortName: "x", parsed: { _ in parsed = true })
        let tokensConsumed = try? ArgTree(parsers: [
            flag
        ]).parse(arguments: ["foo", "-x"])
        XCTAssertEqual(tokensConsumed, 2)
        XCTAssert(parsed)
        XCTAssertEqual(flag.values.count, 1)
    }

    func testFlagParsingTwice() {
        var parsed = false
        let flag = Flag(shortName: "x", multiAllowed: true, parsed: { _ in parsed = true })
        let tokensConsumed = try? ArgTree(parsers: [
            flag
        ]).parse(arguments: ["foo", "-x", "-x"])
        XCTAssertEqual(tokensConsumed, 3)
        XCTAssert(parsed)
        XCTAssertEqual(flag.values.count, 2)
    }

    func testFlagNotParsableTwice() {
        do {
            try ArgTree(parsers: [
                Flag(shortName: "x")
            ]).parse(arguments: ["foo", "-x", "-x"])
        } catch FlagParseError.flagAllowedOnlyOnce(flag: _, atIndex: 2) {
            return

        } catch {
            XCTFail("unexpected error \(error)")
        }
        XCTFail("no error")
    }

    func testCustomPrefix() {
        let flag = Flag(longName: "xx", shortName: "x", longPrefix: "++", shortPrefix: "+", multiAllowed: true)
        let tokensConsumed = try! ArgTree(parsers: [
            flag
        ]).parse(arguments: ["foo", "+x", "++xx"])
        XCTAssertEqual(tokensConsumed, 3)
        XCTAssertEqual(flag.values.count, 2)
    }

    func testUnexpectedFlagHandling() {
        do {
            try ArgTree(parsers: [
                Flag(shortName: "x"),
                UnexpectedFlagHandler(),
            ]).parse(arguments: ["foo", "-x", "-y"])
        } catch FlagParseError.unexpectedFlag(flag: "-y", atIndex: 2) {
            return

        } catch {
            XCTFail("unexpected error \(error)")
        }
        XCTFail("no error")
    }

    func testAccessingFlagLater() {
        let verboseFlag = Flag(longName: "verbose", shortName: "v")
        let argTree: ArgTree = ArgTree(parsers: [verboseFlag])

        verboseFlag.values.removeAll()
        try! argTree.parse(arguments: ["foo", "-v"])
        var verbose = verboseFlag.values.first != nil
        XCTAssert(verbose)

        verboseFlag.values.removeAll()
        try! argTree.parse(arguments: ["foo"])
        verbose = verboseFlag.values.first != nil
        XCTAssert(!verbose)
    }

#if !os(macOS)
    static var allTests = [
        ("testAccessingFlagLater", testAccessingFlagLater),
        ("testCommandParsing", testCommandParsing),
        ("testCustomPrefix", testCustomPrefix),
        ("testFlagNotParsableTwice", testFlagNotParsableTwice),
        ("testFlagParsing", testFlagParsing),
        ("testUnexpectedFlagHandling", testUnexpectedFlagHandling),
    ]
#endif
}
