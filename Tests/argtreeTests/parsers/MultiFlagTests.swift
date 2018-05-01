import XCTest
@testable import argtree

final class MultiFlagTests: XCTestCase {

    func testFlagParsing() {
        var xPath: [ParsePathSegment] = []
        var yPath: [ParsePathSegment] = []
        let tokensConsumed = try! ArgTree(parsers: [
            MultiFlag(parsers: [
                Flag(shortName: "x", parsed: { path in
                    xPath = path
                }),
                Flag(shortName: "y", parsed: { path in
                    yPath = path
                }),
            ])
        ]).parse(arguments: ["foo", "-xy"])

        XCTAssertEqual(tokensConsumed, 2)
        XCTAssertEqual(xPath.count, 1, "xPath \(xPath)")
        XCTAssertEqual(yPath.count, 1, "yPath \(yPath)")
    }

    func testFlagParsingWithOneFlag() {
        var xPath: [ParsePathSegment] = []
        let tokensConsumed = try! ArgTree(parsers: [
            MultiFlag(parsers: [
                Flag(shortName: "x", parsed: { path in
                    xPath = path
                }),
            ]),
            VarArgs(),
        ]).parse(arguments: ["ignored", "foo", "-x"])

        XCTAssertEqual(tokensConsumed, 3)
        XCTAssertEqual(xPath.count, 1, "xPath \(xPath)")
    }

    func testFlagParsingStopToken() {
        var xPath: [ParsePathSegment] = []
        var yPath: [ParsePathSegment] = []
        let tokensConsumed = try! ArgTree(parsers: [
            MultiFlag(parsers: [
                Flag(shortName: "x", parsed: { path in
                    xPath = path
                }),
                Flag(shortName: "y", parsed: { path in
                    yPath = path
                }),
            ]),
            VarArgs(),
        ]).parse(arguments: ["foo", "--", "-xy"])

        XCTAssertEqual(tokensConsumed, 3)
        XCTAssertEqual(xPath.count, 0, "xPath \(xPath)")
        XCTAssertEqual(yPath.count, 0, "yPath \(yPath)")
    }

    func testFlagParsingForSingleFlag() {
        var xPath: [ParsePathSegment] = []
        var yPath: [ParsePathSegment] = []
        let tokensConsumed = try? ArgTree(parsers: [
            MultiFlag(parsers: [
                Flag(shortName: "x", parsed: { path in
                    xPath = path
                }),
                Flag(shortName: "y", parsed: { path in
                    yPath = path
                }),
            ])
        ]).parse(arguments: ["foo", "-x"])

        XCTAssertEqual(tokensConsumed, 2)
        XCTAssertEqual(xPath.count, 1, "xPath \(xPath)")
        XCTAssertEqual(yPath.count, 0, "yPath \(yPath)")
    }

    func testHelpText() {
        let argTree = ArgTree(description: "usage", parsers: [
            MultiFlag(parsers: [
                Flag(shortName: "x", description: "foo"),
                Flag(shortName: "y", description: "bar"),
            ])
        ]) {
        }
        var out = ""
        argTree.writeToOutStream = { s in
            print(s, to: &out)
        }

        try! argTree.parse(arguments: ["ignored", "-h"])
        let expected = """
        usage
            --help, -h print this help
            -x         foo
            -y         bar
        """
        XCTAssertEqualTrimmingWhiteSpace(out, expected)
    }

#if !os(macOS)
    static var allTests = [
        ("testFlagParsing", testFlagParsing),
        ("testFlagParsingForSingleFlag", testFlagParsingForSingleFlag),
        ("testFlagParsingStopToken", testFlagParsingStopToken),
        ("testHelpText", testHelpText),
    ]
#endif
}
