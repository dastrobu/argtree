import XCTest
import LoggerAPI
import HeliumLogger

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    Log.logger = HeliumLogger(.debug)
    return [
        testCase(ArgTreeTests.allTests),
        testCase(CommandTests.allTests),
        testCase(FlagTests.allTests),
        testCase(OptionTests.allTests),
        testCase(VarArgsTests.allTests),
    ]
}
#endif
