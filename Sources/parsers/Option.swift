public enum OptionParseError<T>: Error {
    case optionAllowedOnlyOnce(option: OptionParser<T>, atIndex: Int)
    case missingValueForOption(option: OptionParser<T>, atIndex: Int, key: String)
    case valueNotIntConvertible(option: OptionParser<T>, atIndex: Int, value: String)
    case valueNotDoubleConvertible(option: OptionParser<T>, atIndex: Int, value: String)
    case unexpectedOption(option: String, atIndex: Int)
}

open class OptionParser<T>: ValueParser<T>, @unchecked Sendable {
    /** flag to indicate if passing an option more that once is an error */
    public var multiAllowed = false

    public init(longName: String? = nil,
                shortName: String? = nil,
                description: String? = nil,
                longPrefix: String = "--",
                shortPrefix: String = "-",
                multiAllowed: Bool = false,
                stopToken: String? = "--",
                parsed: OnValueParsed<T>? = nil) {
        self.multiAllowed = multiAllowed
        var aliases: [String] = []
        if let longName = longName {
            aliases.append(longPrefix + longName)
        }
        if let shortName = shortName {
            aliases.append(shortPrefix + shortName)
        }
        super.init(aliases: aliases, description: description, stopToken: stopToken, parsed: { value, path in
            if let parsed = parsed {
                parsed(value, path)
            }
        })
    }

    open override func parse(arguments: [String], atIndex i: Int, path: [ParsePathSegment]) throws -> Int {
        let arg = arguments[i]
        if arg == stopToken {
            logger.debug("stopping parsing on stopToken '\(arg)'")
            return 0
        }
        for alias in aliases {
            if arg == alias {
                try checkMultiOption(arguments: arguments, atIndex: i, path: path)
                if i + 1 >= arguments.count {
                    logger.debug("no value for option '\(alias)' could be found for '\(arg)' at index \(i)")
                    throw OptionParseError.missingValueForOption(option: self, atIndex: i, key: arg)
                }
                let value = arguments[i + 1]
                try parseOption(alias, value: value, atIndex: i + 1, path: path)
                return 2
            } else if arg.starts(with: alias + "=") {
                try checkMultiOption(arguments: arguments, atIndex: i, path: path)
                let value = arg.suffix(from: arg.index(after: arg.firstIndex(of: "=")!))
                try parseOption(alias, value: String(value), atIndex: i, path: path)
                return 1
            }
        }
        return 0
    }

    private func checkMultiOption(arguments: [String], atIndex i: Int, path: [ParsePathSegment]) throws {
        if !multiAllowed && values.count > 0 {
            // if the option has been parsed once, it is not allowed a second time, if not explicitly allowed
            // by multiAllowed
            logger.debug("not allowed to pass option '\(aliases)' multiple times at index \(i)")
            throw OptionParseError.optionAllowedOnlyOnce(option: self, atIndex: i)
        }
    }

    private func parseOption(_ option: String, value: String, atIndex i: Int, path: [ParsePathSegment]) throws {
        logger.debug("parsing option '\(option)' at index \(i), value is '\(value)'")
        if let converter = valueConverter {
            let value = try converter(value, i)
            self.appendValue(value)
            if let parsed = parsed {
                parsed(value, path)
            }
        }

    }

    public override var debugDescription: String {
        return "\(String(describing: OptionParser.self))(\(aliases))"
    }
}

public class Option: OptionParser<String>, @unchecked Sendable {
    public override init(longName: String? = nil,
                         shortName: String? = nil,
                         description: String? = nil,
                         longPrefix: String = "--",
                         shortPrefix: String = "-",
                         multiAllowed: Bool = false,
                         stopToken: String? = "--",
                         parsed: OnValueParsed<String>? = nil) {
        super.init(longName: longName,
            shortName: shortName,
            description: description,
            longPrefix: longPrefix,
            shortPrefix: shortPrefix,
            multiAllowed: multiAllowed,
            stopToken: stopToken,
            parsed: parsed)
        valueConverter = { value, _ in
            return value
        }
    }

    public override var debugDescription: String {
        return "\(String(describing: Option.self))(\(aliases))"
    }
}

public class IntOption: OptionParser<Int>, @unchecked Sendable {
    public override init(longName: String? = nil,
                         shortName: String? = nil,
                         description: String? = nil,
                         longPrefix: String = "--",
                         shortPrefix: String = "-",
                         multiAllowed: Bool = false,
                         stopToken: String? = "--",
                         parsed: OnValueParsed<Int>? = nil) {
        super.init(longName: longName,
            shortName: shortName,
            description: description,
            longPrefix: longPrefix,
            shortPrefix: shortPrefix,
            multiAllowed: multiAllowed,
            stopToken: stopToken,
            parsed: parsed)
        valueConverter = { [unowned self] value, i in
            if let value = Int(value) {
                return value
            }
            logger.debug("value '\(value)' cannot be converted to Int option")
            throw OptionParseError.valueNotIntConvertible(option: self, atIndex: i, value: value)
        }
    }

    public override var debugDescription: String {
        return "\(String(describing: IntOption.self))(\(aliases))"
    }
}

public class DoubleOption: OptionParser<Double>, @unchecked Sendable {
    public override init(longName: String? = nil,
                         shortName: String? = nil,
                         description: String? = nil,
                         longPrefix: String = "--",
                         shortPrefix: String = "-",
                         multiAllowed: Bool = false,
                         stopToken: String? = "--",
                         parsed: OnValueParsed<Double>? = nil) {
        super.init(longName: longName,
            shortName: shortName,
            description: description,
            longPrefix: longPrefix,
            shortPrefix: shortPrefix,
            multiAllowed: multiAllowed,
            stopToken: stopToken,
            parsed: parsed)
        valueConverter = { [unowned self] value, i in
            if let value = Double(value) {
                return value
            }
            logger.debug("value '\(value)' cannot be converted to Double option")
            throw OptionParseError.valueNotDoubleConvertible(option: self, atIndex: i, value: value)
        }
    }

    public override var debugDescription: String {
        return "\(String(describing: DoubleOption.self))(\(aliases))"
    }
}

/** allows to detect unexpected flags and convert them to errors */
public class UnexpectedOptionHandler: Parser {
    public var description: [(argument: String, description: String)] = []

    /** token after which all arguments will be treated as var args, instead of parsing them as e.g. flags */
    public var stopToken: String?

    private let longPrefix: String?
    private let shortPrefix: String?

    public init(longPrefix: String? = "--",
                shortPrefix: String? = "-",
                stopToken: String? = "--") {
        self.longPrefix = longPrefix
        self.shortPrefix = shortPrefix
        self.stopToken = stopToken
    }

    public func parse(arguments: [String], atIndex i: Int, path: [ParsePathSegment]) throws -> Int {
        let arg = arguments[i]
        if arg == stopToken {
            logger.debug("stopping parsing on stopToken '\(arg)'")
            return 0
        }
        if let longPrefix = longPrefix {
            if arg.starts(with: longPrefix) {
                logger.debug("handling unexpected option '\(arg)' at index \(i)")
                throw OptionParseError<Void>.unexpectedOption(option: arg, atIndex: i)
            }
        }
        if let shortPrefix = shortPrefix {
            if arg.starts(with: shortPrefix) {
                logger.debug("handling unexpected option '\(arg)' at index \(i)")
                throw OptionParseError<Void>.unexpectedOption(option: arg, atIndex: i)
            }
        }
        return 0
    }

    public var debugDescription: String {
        return "\(String(describing: UnexpectedOptionHandler.self))"
    }
}
