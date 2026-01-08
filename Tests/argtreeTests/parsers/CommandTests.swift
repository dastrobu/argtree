import XCTest
@testable import argtree

final class CommandTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setUpLogger()
    }

    func testCommandParsing() {
        var parsed = false
        let command = Command(name: "bar", parsed: { _ in parsed = true })
        command.defaultAction = {
        }
        let tokensConsumed = try! ArgTree(parsers: [
            command
        ]).parse(arguments: ["foo", "bar"])
        XCTAssertEqual(tokensConsumed, 2)
        XCTAssert(parsed)
        XCTAssertEqual(command.values.count, 1)
    }

    func testCommandParsingWithVarArgs() {
        var parsed = false
        let varArgs = VarArgs()
        let command = Command(name: "bar", parsed: { _ in parsed = true }, parsers: [
            varArgs
        ])
        let tokensConsumed = try! ArgTree(parsers: [
            command
        ]).parse(arguments: ["foo", "bar", "biz", "bar"])
        XCTAssertEqual(tokensConsumed, 4)
        XCTAssert(parsed)
        // although bar was passed twice, it should only be parsed once, since commands cannot be passed twice.
        // The second one should be treated as variadic argument.
        XCTAssertEqual(command.values.count, 1)
        XCTAssertEqual(varArgs.values.count, 2)
        XCTAssertEqual(varArgs.values[0], "biz")
        XCTAssertEqual(varArgs.values[1], "bar")
    }

    func testCommandParsingWithGlobalFlag() {
        var flagParsed = false
        var commandParsed = false
        let command = Command(name: "bar", parsed: { _ in commandParsed = true })
        command.defaultAction = {
        }
        let tokensConsumed = try! ArgTree(parsers: [
            Flag(shortName: "x", parsed: { _ in flagParsed = true }),
            command,
        ]).parse(arguments: ["foo", "-x", "bar"])
        XCTAssertEqual(tokensConsumed, 3)
        XCTAssert(flagParsed)
        XCTAssert(commandParsed)
    }

    func testCommandParsingWithGlobalFlagAfterCommand() {
        var flagParsed = false
        var commandParsed = false
        let command = Command(name: "bar", parsed: { _ in commandParsed = true })
        command.defaultAction = {
        }
        let tokensConsumed = try! ArgTree(parsers: [
            Flag(shortName: "x", parsed: { _ in flagParsed = true }),
            command,
        ]).parse(arguments: ["foo", "bar", "-x"])
        XCTAssertEqual(tokensConsumed, 3)
        XCTAssert(flagParsed)
        XCTAssert(commandParsed)
    }

    func testCommandNotParsingGlobalFlagAfterCommand() {
        var flagParsed = false
        var commandParsed = false
        // -x should be treated as var arg
        let tokensConsumed = try! ArgTree(parsers: [
            Command(name: "bar", parsed: { _ in commandParsed = true },
                parsers: [VarArgs()]),
            Flag(shortName: "x", parsed: { _ in flagParsed = true }),
        ]).parse(arguments: ["foo", "bar", "-x"])
        XCTAssertEqual(tokensConsumed, 3)
        XCTAssert(!flagParsed)
        XCTAssert(commandParsed)
    }

    func testCommandNotParsableTwice() {
        do {
            let command = Command(name: "x")
            command.defaultAction = {
            }
            try ArgTree(parsers: [
                command
            ]).parse(arguments: ["foo", "x", "x"])
        } catch CommandParseError.commandAllowedOnlyOnce(command: _, atIndex: let index) {
            XCTAssertEqual(index, 2)
            return

        } catch {
            XCTFail("unexpected error \(error)")
        }
        XCTFail("no error")
    }

    func testCustomHelp() {
        var globalHelp = false
        var fooHelp = false

        let help = Flag(longName: "help", shortName: "h")
        let foo = Command(name: "foo", parsers: [help])
        foo.removeFirst()
        help.parsed = { _, path in
            switch path.last {
            case let cmd as Command where cmd === foo:
                print("foo help")
                fooHelp = true
            default:
                print("global help")
                globalHelp = true
            }
        }

        globalHelp = false
        fooHelp = false
        try! ArgTree(parsers: [help, foo]).parse(arguments: ["ignored", "foo", "-h"])
        XCTAssert(fooHelp)

        help.clearValues()
        foo.clearValues()
        globalHelp = false
        fooHelp = false
        try! ArgTree(parsers: [help, foo]).parse(arguments: ["ignored", "-h"])
        XCTAssert(globalHelp)
    }

    func testDefaultAction() {
        var defaultAction = false
        let foo = Command(name: "foo")
        foo.defaultAction = { () in
            defaultAction = true
        }
        try! ArgTree(parsers: [foo]).parse(arguments: ["ignored", "foo"])
        XCTAssert(defaultAction)
    }

    func testShowDescriptionAsDefault() {
        var helpPrinted = false

        let foo = Command(name: "foo", description: "foo usage", helpPrinted: {
            helpPrinted = true
        })
        var out = ""
        foo.writeToOutStream = { s in
            print(s, to: &out)
        }
        let tokensConsumed = try! ArgTree(helpText: "usage", parsers: [foo]).parse(arguments: ["ignored", "foo", "-h"])
        XCTAssertEqual(tokensConsumed, 3)
        XCTAssert(out.starts(with: "foo usage"))
        XCTAssert(helpPrinted)
    }

    func testShowHelpTextAsDefault() {
        var helpPrinted = false

        let foo = Command(name: "foo", helpText: "foo usage", helpPrinted: {
            helpPrinted = true
        })
        var out = ""
        foo.writeToOutStream = { s in
            print(s, to: &out)
        }
        let tokensConsumed = try! ArgTree(helpText: "usage", parsers: [foo]).parse(arguments: ["ignored", "foo", "-h"])
        XCTAssertEqual(tokensConsumed, 3)
        XCTAssert(out.starts(with: "foo usage"))
        XCTAssert(helpPrinted)
    }

    func testShowNothingAsDefault() {
        let foo = Command(name: "foo", helpText: "foo usage")
        foo.defaultAction = nil
        var out = ""
        foo.writeToOutStream = { s in
            print(s, to: &out)
        }
        let tokensConsumed = try! ArgTree(helpText: "usage", parsers: [foo]).parse(arguments: ["ignored", "foo", "bar"])
        XCTAssertEqual(tokensConsumed, 2)
        XCTAssertEqualTrimmingWhiteSpace(out, "")
    }

    func testGeneratedHelp() {
        var helpPrinted = false

        let foo = Command(name: "foo", helpText: "foo usage",
            parsers: [Flag(longName: "bar", shortName: "b", description: "a bar flag")],
            helpPrinted: {
                helpPrinted = true
            })
        var out = ""
        foo.writeToOutStream = { s in
            print(s, to: &out)
        }
        let tokensConsumed = try! ArgTree(helpText: "usage", parsers: [foo]).parse(arguments: ["ignored", "foo", "-h"])
        XCTAssertEqual(tokensConsumed, 3)
        let expected = """
                       foo usage
                           --help, -h print this help
                           --bar, -b  a bar flag
                       """
        XCTAssertEqualTrimmingWhiteSpace(out, expected)
        XCTAssert(helpPrinted)
    }

    #if !os(macOS)
    static let allTests = [
        ("testCommandNotParsableTwice", testCommandNotParsableTwice),
        ("testCommandNotParsingGlobalFlagAfterCommand", testCommandNotParsingGlobalFlagAfterCommand),
        ("testCommandParsing", testCommandParsing),
        ("testCommandParsingWithGlobalFlag", testCommandParsingWithGlobalFlag),
        ("testCommandParsingWithGlobalFlagAfterCommand", testCommandParsingWithGlobalFlagAfterCommand),
        ("testCommandParsingWithVarArgs", testCommandParsingWithVarArgs),
        ("testCustomHelp", testCustomHelp),
        ("testDefaultAction", testDefaultAction),
        ("testShowDescriptionAsDefault", testShowDescriptionAsDefault),
        ("testShowHelpTextAsDefault", testShowHelpTextAsDefault),
        ("testShowNothingAsDefault", testShowNothingAsDefault),
        ("testGeneratedHelp", testGeneratedHelp),
    ]
    #endif
}
