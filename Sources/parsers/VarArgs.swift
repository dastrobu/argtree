public enum ArgParseError: Error {
    case unexpectedArg(argument: String, atIndex: Int)
}

/**
 * Var arg parser, which collects all arguments, not parsed by other parsers.
 */
public class VarArgs: Parser {
    public private(set) var description: [(argument: String, description: String)] = []

    public var values: [String] = []

    /** token after which all arguments will be treated as var args, instead of parsing them as e.g. flags */
    public var stopToken: String?

    init(stopToken: String? = "--") {
        self.stopToken = stopToken
    }

    public func parse(arguments: [String], atIndex i: Int, path: [ParsePathSegment]) -> Int {
        let arg: String = arguments[i]
        if arg == stopToken {
            // take all remaining arguments as var args
            values.append(contentsOf: arguments[(i + 1)...])
            return arguments.count - i
        } else {
            values.append(arg)
            return 1
        }
    }
}

/** allows to detect unexpected arguments and convert them to errors */
public class UnexpectedArgHandler: Parser {
    public private(set) var description: [(argument: String, description: String)] = []

    /** token after which all arguments will be treated as var args, instead of parsing them as e.g. flags */
    public var stopToken: String?

    init(stopToken: String? = "--") {
        self.stopToken = stopToken
    }

    public func parse(arguments: [String], atIndex i: Int, path: [ParsePathSegment]) throws -> Int {
        let arg = arguments[i]
        if arg == stopToken {
            return 0
        }
        throw ArgParseError.unexpectedArg(argument: arg, atIndex: i)
    }
}
