public enum OptionParseError<T>: Error {
    case optionAllowedOnlyOnce(option: OptionParser<T>, atIndex: Int)
    case missingValueForOption(option: OptionParser<T>, atIndex: Int, key: String)
    case valueNotIntConvertible(option: OptionParser<T>, atIndex: Int, value: String)
    case valueNotDoubleConvertible(option: OptionParser<T>, atIndex: Int, value: String)
    // TODO:
    case unexpectedOption(option: String, atIndex: Int)
}

// TODO: implement multi options (one option can be passed several times)
open class OptionParser<T>: ValueParser<T> {
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
        if stopToken != nil && arg == stopToken {
            return 0
        }
        for alias in aliases {
            if arg == alias {
                try checkMultiOption(atIndex: i)
                if i + 1 >= arguments.count {
                    throw OptionParseError.missingValueForOption(option: self, atIndex: i, key: arg)
                }
                let value = arguments[i + 1]
                try parseValue(value, atIndex: i + 1, path: path)
                return 2
            } else if arg.starts(with: alias + "=") {
                try checkMultiOption(atIndex: i)
                let value = arg.suffix(from: arg.index(after: arg.index(of: "=")!))
                try parseValue(String(value), atIndex: i, path: path)
                return 1
            }
        }
        return 0
    }

    private func checkMultiOption(atIndex i: Int) throws {
        if !multiAllowed && values.count > 0 {
            // if the option has been parsed once, it is not allowed a second time, if not explicitly allowed
            // by multiAllowed
            throw OptionParseError.optionAllowedOnlyOnce(option: self, atIndex: i)
        }
    }

    private func parseValue(_ value: String, atIndex i: Int, path: [ParsePathSegment]) throws {
        if let converter = valueConverter {
            let value = try converter(value, i)
            self.values.append(value)
            if let parsed = parsed {
                parsed(value, path)
            }
        }

    }
}

public class Option: OptionParser<String> {
    override init(longName: String? = nil,
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
}

public class IntOption: OptionParser<Int> {
    override init(longName: String? = nil,
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
        valueConverter = { value, i in
            if let value = Int(value) {
                return value
            }
            throw OptionParseError.valueNotIntConvertible(option: self, atIndex: i, value: value)
        }
    }
}

public class DoubleOption: OptionParser<Double> {
    override init(longName: String? = nil,
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
        valueConverter = { value, i in
            if let value = Double(value) {
                return value
            }
            throw OptionParseError.valueNotDoubleConvertible(option: self, atIndex: i, value: value)
        }
    }
}
