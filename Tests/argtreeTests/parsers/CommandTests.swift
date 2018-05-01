import XCTest
@testable import argtree

final class CommandTests: XCTestCase {

    func testCommandParsing() {
        var parsed = false
        let command = Command(name: "bar", parsed: { _ in parsed = true })
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
        XCTAssertEqual(command.count, 1)
        XCTAssertEqual(varArgs.count, 2)
        XCTAssertEqual(varArgs[0], "biz")
        XCTAssertEqual(varArgs[1], "bar")
    }

    func testCommandParsingWithGlobalFlag() {
        var flagParsed = false
        var commandParsed = false
        let tokensConsumed = try! ArgTree(parsers: [
            Flag(shortName: "x", parsed: { _ in flagParsed = true }),
            Command(name: "bar", parsed: { _ in commandParsed = true }),
        ]).parse(arguments: ["foo", "-x", "bar"])
        XCTAssertEqual(tokensConsumed, 3)
        XCTAssert(flagParsed)
        XCTAssert(commandParsed)
    }

    func testCommandParsingWithGlobalFlagAfterCommand() {
        var flagParsed = false
        var commandParsed = false
        let tokensConsumed = try! ArgTree(parsers: [
            Flag(shortName: "x", parsed: { _ in flagParsed = true }),
            Command(name: "bar", parsed: { _ in commandParsed = true }),
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
            try ArgTree(parsers: [
                Command(name: "x")
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

        help.values.removeAll()
        foo.values.removeAll()
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
        try! ArgTree(parsers: [foo]).parse(arguments: ["ignored", "foo", "-h"])
        XCTAssert(defaultAction)
    }

#if !os(macOS)
    static var allTests = [
        ("testCommandNotParsableTwice", testCommandNotParsableTwice),
        ("testCommandNotParsingGlobalFlagAfterCommand", testCommandNotParsingGlobalFlagAfterCommand),
        ("testCommandParsing", testCommandParsing),
        ("testCommandParsingWithGlobalFlag", testCommandParsingWithGlobalFlag),
        ("testCommandParsingWithGlobalFlagAfterCommand", testCommandParsingWithGlobalFlagAfterCommand),
        ("testCommandParsingWithVarArgs", testCommandParsingWithVarArgs),
        ("testCustomHelp", testCustomHelp),
        ("testDefaultAction", testDefaultAction),
    ]
#endif
}
