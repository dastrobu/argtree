import XCTest
import Logging

struct LoggerSetup {
    static let setup: Void = {
        LoggingSystem.bootstrap({ label in
            var logHandler = StreamLogHandler.standardError(label: label)
            logHandler.logLevel = .debug
            return logHandler
        })
    }()
}

func setUpLogger() {
    _ = LoggerSetup.setup
}

#if os(Linux)
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
