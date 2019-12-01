import XCTest
import Logging

var logHandler: LogHandler? = nil

func setUpLogger() {
    if logHandler == nil {
        LoggingSystem.bootstrap({ label in
            var newLogHandler = StreamLogHandler.standardError(label: label)
            newLogHandler.logLevel = .trace
            logHandler = newLogHandler
            return newLogHandler
        })
    }
}

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    [
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
