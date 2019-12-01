import Logging

public enum FlagParseError: Error {
    case flagAllowedOnlyOnce(flag: Flag, atIndex: Int)
    case unexpectedFlag(flag: String, atIndex: Int)
}

/**
 * Flags such as e.g. -v or --verbose
 */
public class Flag: ValueParser<Bool> {

    /** flag to indicate if passing a flag more that once is an error */
    public var multiAllowed = false

    public override func parse(arguments: [String], atIndex i: Int, path: [ParsePathSegment]) throws -> Int {
        let tokensConsumed: Int = try super.parse(arguments: arguments, atIndex: i, path: path)
        if !multiAllowed && values.count > 1 {
            // if the flag has been parsed once, it is not allowed a second time, if not explicitly allowed
            // by multiAllowed
            throw FlagParseError.flagAllowedOnlyOnce(flag: self, atIndex: i)
        }
        return tokensConsumed
    }

    public init(longName: String? = nil,
                shortName: Character? = nil,
                description: String? = nil,
                longPrefix: String = "--",
                shortPrefix: Character = "-",
                multiAllowed: Bool = false,
                stopToken: String? = "--",
                parsed: OnParsed? = nil) {
        self.multiAllowed = multiAllowed
        var aliases: [String] = []
        if let longName = longName {
            aliases.append(longPrefix + longName)
        }
        if let shortName = shortName {
            aliases.append(String(shortPrefix) + String(shortName))
        }
        super.init(aliases: aliases, description: description, stopToken: stopToken, parsed: { _, path in
            if let parsed = parsed {
                parsed(path)
            }
        })
        valueConverter = { value, _ in
            return true
        }
    }

    public override var debugDescription: String {
        return "\(String(describing: Flag.self))(\(aliases))"
    }
}

/** allows to detect unexpected flags and convert them to errors */
public class UnexpectedFlagHandler: Parser {
    public var description: [(argument: String, description: String)] = []

    /** token after which all arguments will be treated as var args, instead of parsing them as e.g. flags */
    var stopToken: String?

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
                logger.debug("handling unexpected flag '\(arg)' at index \(i)")
                throw FlagParseError.unexpectedFlag(flag: arg, atIndex: i)
            }
        }
        if let shortPrefix = shortPrefix {
            if arg.starts(with: shortPrefix) {
                logger.debug("handling unexpected flag '\(arg)' at index \(i)")
                throw FlagParseError.unexpectedFlag(flag: arg, atIndex: i)
            }
        }
        return 0
    }

    public var debugDescription: String {
        return "\(String(describing: UnexpectedFlagHandler.self))(\(String(describing: shortPrefix)), " +
            "\(String(describing: longPrefix)))"
    }
}
