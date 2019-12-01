import XCTest
@testable import argtree

final class VarArgsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setUpLogger();
    }

    func testUnexpectedVarArgsHandlingNotThrowing() {
        let command = Command(name: "bar")
        command.defaultAction = {}
        let tokensConsumed = try! ArgTree(parsers: [
            command,
            UnexpectedArgHandler(),
        ]).parse(arguments: ["foo", "bar"])
        XCTAssertEqual(tokensConsumed, 2)
    }

    func testUnexpectedVarArgsHandlingNotThrowingWithSubVarArgs() {
        let tokensConsumed = try! ArgTree(parsers: [
            Command(name: "bar", parsers: [
                VarArgs()
            ]),
            UnexpectedArgHandler(),
        ]).parse(arguments: ["foo", "bar", "baz"])
        XCTAssertEqual(tokensConsumed, 3)
    }

    func testUnexpectedVarArgsHandlingThrowing() {
        do {
            try ArgTree(parsers: [
                Command(name: "bar", parsers: [UnexpectedArgHandler()]),
            ]).parse(arguments: ["foo", "bar", "baz"])
        } catch ArgParseError.unexpectedArg(argument: "baz", atIndex: 2) {
            return
        } catch {
            XCTFail("unexpected error \(error)")
        }
        XCTFail("no error")
    }

    func testStopToken() {
        let tokensConsumed = try! ArgTree(parsers: [
            Command(name: "bar", parsers: [UnexpectedArgHandler(), VarArgs()]),
        ]).parse(arguments: ["foo", "bar", "--", "baz"])
        XCTAssertEqual(tokensConsumed, 4)
    }

#if !os(macOS)
    static var allTests = [
        ("testStopToken", testStopToken),
        ("testUnexpectedVarArgsHandlingNotThrowing", testUnexpectedVarArgsHandlingNotThrowing),
        ("testUnexpectedVarArgsHandlingNotThrowingWithSubVarArgs",
            testUnexpectedVarArgsHandlingNotThrowingWithSubVarArgs),
        ("testUnexpectedVarArgsHandlingThrowing", testUnexpectedVarArgsHandlingThrowing),
    ]
#endif
}
