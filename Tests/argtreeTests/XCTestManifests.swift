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
