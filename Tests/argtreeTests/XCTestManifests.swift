import XCTest
import Logging

private var loggerInitialized = false

func setUpLogger() {
    if !loggerInitialized {
        LoggingSystem.bootstrap({ label in
            var logHandler = StreamLogHandler.standardError(label: label)
            logHandler.logLevel = .debug
            return logHandler
        })
        loggerInitialized = true
    }
}

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ArgTreeTests.allTests),
        testCase(CommandTests.allTests),
        testCase(FlagTests.allTests),
        testCase(MultiFlagTests.allTests),
        testCase(OptionTests.allTests),
        testCase(VarArgsTests.allTests),
        testCase(ArgTreeTests.allTests),
    ]
}
#endif
