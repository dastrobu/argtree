import XCTest
@testable import argtree

final class ArgTreeTests: XCTestCase {

    func testShowUsageAsDefault() {
        var helpPrinted = false
        let argTree = ArgTree(helpText: "usage") {
            helpPrinted = true
        }

        var out = ""
        argTree.writeToOutStream = { s in
            print(s, to: &out)
        }

        let tokensConsumed = try? argTree.parse(arguments: ["foo"])
        XCTAssertEqual(tokensConsumed, 1)
        XCTAssertEqualIgnoringWhiteSpace(out, "usage")
        XCTAssert(helpPrinted)
    }

    func testShowNothingAsDefault() {
        let argTree = ArgTree(helpText: "usage")

        var out = ""
        argTree.writeToOutStream = { s in
            print(s, to: &out)
        }

        argTree.defaultAction = nil
        let tokensConsumed = try? argTree.parse(arguments: ["foo"])
        XCTAssertEqual(tokensConsumed, 1)

        XCTAssertEqualIgnoringWhiteSpace(out, "")
    }

    func testHelpShortFlag() {
        var helpPrinted = false
        let argTree = ArgTree(helpText: "usage") {
            helpPrinted = true
        }

        var out = ""
        argTree.writeToOutStream = { s in
            print(s, to: &out)
        }

        argTree.defaultAction = nil
        let tokensConsumed = try? argTree.parse(arguments: ["foo", "-h"])
        XCTAssertEqual(tokensConsumed, 2)

        XCTAssertEqualIgnoringWhiteSpace(out, "usage")
        XCTAssert(helpPrinted)
    }

    func testHelpLongFlag() {
        var helpPrinted = false
        let argTree = ArgTree(helpText: "usage") {
            helpPrinted = true
        }

        var out = ""
        argTree.writeToOutStream = { s in
            print(s, to: &out)
        }

        argTree.defaultAction = nil
        let tokensConsumed = try? argTree.parse(arguments: ["foo", "--help"])
        XCTAssertEqual(tokensConsumed, 2)
        XCTAssertEqualIgnoringWhiteSpace(out, "usage")
        XCTAssert(helpPrinted)
    }

    func testGeneratedHelp() {
        var helpPrinted = false
        let argTree = ArgTree(description: "usage") {
            helpPrinted = true
        }
        argTree.append(Flag(longName: "bar", shortName: "b", description: "a bar flag", parsed: { _ in }))

        var out = ""
        argTree.writeToOutStream = { s in
            print(s, to: &out)
        }

        argTree.defaultAction = nil
        let tokensConsumed = try? argTree.parse(arguments: ["foo", "--help"])
        XCTAssertEqual(tokensConsumed, 2)
        let expected = """
            usage
                --help, -h print this help
                --bar, -b  a bar flag
            """
        XCTAssertEqualIgnoringWhiteSpace(out, expected)
        XCTAssert(helpPrinted)
    }

    func testGeneratedHelpIgnoringFlagWithoutDescription() {
        var helpPrinted = false
        let argTree = ArgTree(description: "usage") {
            helpPrinted = true
        }
        argTree.append(Flag(longName: "bar", shortName: "b", parsed: { _ in }))

        var out = ""
        argTree.writeToOutStream = { s in
            print(s, to: &out)
        }

        argTree.defaultAction = nil
        let tokensConsumed = try? argTree.parse(arguments: ["foo", "--help"])
        XCTAssertEqual(tokensConsumed, 2)
        let expected = """
            usage
                --help, -h print this help
            """
        XCTAssertEqualIgnoringWhiteSpace(out, expected)
        XCTAssert(helpPrinted)
    }

    func testSimpleDemo() {
        var verbose = false
        try! ArgTree(description:
        """
        usage: \(CommandLine.arguments[0])) [flags]

        hello world demo

        options:
        """,
            parsers: [
                Flag(longName: "verbose", shortName: "v", description: "print verbose output") { _ in
                    verbose = true
                }
            ]).parse()

        if verbose {
            print("hello world")
        } else {
            print("hi")
        }
    }

    func testVarArgsExample() {
        let varArgs = VarArgs()
        let argTree = ArgTree(
            parsers: [
                Flag(longName: "verbose", shortName: "v", description: "print verbose output") { _ in
                },
                varArgs,
            ])
        try! argTree.parse()
        varArgs.values.forEach { _ in
            /* ... */
        }
    }

    func testReorderingFlags() {
        let argTree = ArgTree(description: "foo",
            parsers: [
                Flag(longName: "verbose", shortName: "v", description: "print verbose output") { _ in
                },
            ],
            helpPrinted: { () in })
        argTree.append(argTree.removeFirst())
        var out = ""
        argTree.writeToOutStream = { s in
            print(s, to: &out)
        }

        try! argTree.parse(arguments: ["foo", "-h"])
        let expected = """
            foo
                --verbose, -v print verbose output
                --help, -h    print this help
            """
        XCTAssertEqualIgnoringWhiteSpace(out, expected)
    }

#if !os(macOS)
    static var allTests = [
        ("testGeneratedHelp", testGeneratedHelp),
        ("testGeneratedHelpIgnoringFlagWithoutDescription", testGeneratedHelpIgnoringFlagWithoutDescription),
        ("testHelpLongFlag", testHelpLongFlag),
        ("testHelpShortFlag", testHelpShortFlag),
        ("testShowNothingAsDefault", testShowNothingAsDefault),
        ("testShowUsageAsDefault", testShowUsageAsDefault),
    ]
#endif
}
