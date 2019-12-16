import XCTest
@testable import argtree

final class OptionTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setUpLogger()
    }

    func testShortName() {
        var parsedValue = ""
        let option = Option(shortName: "x", parsed: { value, _ in parsedValue = value })
        let tokensConsumed = try? ArgTree(parsers: [
            option
        ]).parse(arguments: ["foo", "-x", "foo"])
        XCTAssertEqual(tokensConsumed, 3)
        XCTAssertEqual(parsedValue, "foo")
        XCTAssertEqual(option.values.count, 1)
    }

    func testShortNameWithEquals() {
        var parsedValue = ""
        let option = Option(shortName: "x", parsed: { value, _ in parsedValue = value })
        let tokensConsumed = try? ArgTree(parsers: [
            option
        ]).parse(arguments: ["foo", "-x=foo"])
        XCTAssertEqual(tokensConsumed, 2)
        XCTAssertEqual(parsedValue, "foo")
        XCTAssertEqual(option.values.count, 1)
    }

    func testLongName() {
        var parsedValue = ""
        let option = Option(longName: "xx", parsed: { value, _ in parsedValue = value })
        let tokensConsumed = try? ArgTree(parsers: [
            option
        ]).parse(arguments: ["foo", "--xx", "foo"])
        XCTAssertEqual(tokensConsumed, 3)
        XCTAssertEqual(parsedValue, "foo")
        XCTAssertEqual(option.values.count, 1)
    }

    func testLongNameWithEquals() {
        var parsedValue = ""
        let option = Option(longName: "xx", parsed: { value, _ in parsedValue = value })
        let tokensConsumed = try? ArgTree(parsers: [
            option
        ]).parse(arguments: ["foo", "--xx=foo"])
        XCTAssertEqual(tokensConsumed, 2)
        XCTAssertEqual(parsedValue, "foo")
        XCTAssertEqual(option.values.count, 1)
    }

    func testMultiValue() {
        var parsedValue = ""
        let option = Option(longName: "xx", shortName: "x", multiAllowed: true,
            parsed: { value, _ in parsedValue = value })
        let tokensConsumed = try? ArgTree(parsers: [
            option,
            VarArgs(),
        ]).parse(arguments: ["foo", "-x=foo", "ignore", "--xx=bar"])
        XCTAssertEqual(tokensConsumed, 4)
        XCTAssertEqual(parsedValue, "bar")
        XCTAssertEqual(option.values.count, 2)
    }

    func testStopToken() {
        var parsedValue = ""
        let option = Option(longName: "xx", shortName: "x", multiAllowed: true,
            parsed: { value, _ in parsedValue = value })
        let varArgs = VarArgs()
        let tokensConsumed = try? ArgTree(parsers: [
            option,
            varArgs,
            // --xx=bar is parsed as vararg
        ]).parse(arguments: ["foo", "-x=foo", "--", "--xx=bar"])
        XCTAssertEqual(tokensConsumed, 4)
        XCTAssertEqual(parsedValue, "foo")
        XCTAssertEqual(option.values.count, 1)
        XCTAssertEqual(varArgs.values.count, 1)
        XCTAssertEqual(varArgs.values.first, "--xx=bar")
    }

    func testUnexpectedOptionHandling() {
        do {
            try ArgTree(parsers: [
                Option(shortName: "x"),
                UnexpectedOptionHandler(),
            ]).parse(arguments: ["foo", "-x=foo", "-y=bar"])
        } catch OptionParseError<Void>.unexpectedOption(option: "-y=bar", atIndex: 2) {
            return

        } catch {
            XCTFail("unexpected error \(error)")
        }
        XCTFail("no error")
    }

#if !os(macOS)
    static var allTests = [
        ("testLongName", testLongName),
        ("testLongNameWithEquals", testLongNameWithEquals),
        ("testMultiValue", testMultiValue),
        ("testShortName", testShortName),
        ("testShortNameWithEquals", testShortNameWithEquals),
        ("testStopToken", testStopToken),
        ("testUnexpectedOptionHandling", testUnexpectedOptionHandling),
    ]
#endif
}
