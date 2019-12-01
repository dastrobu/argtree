import XCTest
import Logging
import HeliumLogger

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    Log.logger = HeliumLogger(.debug)
    LoggingSystem.bootstrap(logger.makeLogHandler)
    return [
        testCase(ArgTreeTests.allTests),
        testCase(CommandTests.allTests),
        testCase(FlagTests.allTests),
        testCase(OptionTests.allTests),
        testCase(VarArgsTests.allTests),
    ]
}
#endif
