import Logging

/** parser for mult flags */
public class MultiFlag: Parser, ParserNode, ParsePathSegment {

    fileprivate var parsers: [Parser] = []

    public var defaultAction: (() -> Void)?

    public var shortPrefix: Character

    public var stopToken: String?

    public init(shortPrefix: Character = "-",
                stopToken: String? = "--",
                parsers: [Flag] = []
    ) {
        self.stopToken = stopToken
        self.parsers = parsers
        self.shortPrefix = shortPrefix
    }

    public func parse(arguments: [String], atIndex i: Int, path: [ParsePathSegment]) throws -> Int {
        let arg = arguments[i]
        if arg == stopToken {
            logger.debug("stopping parsing on stopToken '\(arg)'")
            return 0
        }
        let prefixString = String(shortPrefix)
        if arg.starts(with: prefixString) {
            if let j: String.Index = arg.index(of: shortPrefix) {
                // create full flags
                let flags: [String] = arg.suffix(from: arg.index(after: j)).map({
                    prefixString + String($0)
                })
                // find a valid flag parser for each flag
#if swift(>=4.1)
                let matched: [(parser: Flag, flag: String)] = flags.compactMap({ flag in
                    if let parser = self.parsers
                        .compactMap({ $0 as? Flag })
                        .first(where: { parser in parser.aliases.contains(flag) }) {
                        return (parser: parser, flag: flag)
                    }
                    return nil
                })
#else
                let matched: [(parser: Flag, flag: String)] = flags.flatMap({ flag in
                    if let parser = self.parsers
                        .flatMap({ $0 as? Flag })
                        .first(where: { parser in parser.aliases.contains(flag) }) {
                        return (parser: parser, flag: flag)
                    }
                    return nil
                })
#endif
                // check if all flags are valid flags, do not treat this as multi flag otherwise
                if matched.count == flags.count {
                    logger.debug("handling '\(arg)' as multi flag, generated: \(flags)")
                    try matched.forEach { parser, flag in
                        _ = try parser.parse(arguments: arguments[..<i] + [flag], atIndex: i, path: path + [self])
                    }
                    return 1
                } else {
                    logger.debug(
                        """
                        '\(arg)' is not a valid multi flag since not all generated flags \(flags
                        ) can be parsed as individual flags
                        """)
                }
            }
        }
        // parse flag normally
        logger.debug("trying to parse '\(arg)' as normal flag ")
        for parser in parsers {
            let tokensConsumed = try parser.parse(arguments: arguments, atIndex: i, path: path + [self])
            if tokensConsumed > 0 {
                return tokensConsumed
            }
        }
        return 0
    }

    public var description: [(argument: String, description: String)] {
        return parsers.flatMap({ $0.description })
    }
}

/** extension to support collection protocols for parsers */
public extension MultiFlag {
    var indices: CountableRange<Int> {
        return parsers.indices

    }

    subscript(bounds: Range<Int>) -> ArraySlice<Parser> {
        get {
            return parsers[bounds]
        }
        set(newValue) {
            parsers[bounds] = newValue
        }
    }

    subscript(position: Int) -> Parser {
        get {
            return parsers[position]
        }
        set(newValue) {
            parsers[position] = newValue
        }
    }

    var startIndex: Int {
        return parsers.startIndex
    }

    var endIndex: Int {
        return parsers.endIndex
    }

    func append(_ parser: Parser) {
        parsers.append(parser)
    }

    func insert(_ parser: Parser, at i: Int) {
        parsers.insert(parser, at: i)
    }

    func insert(contentsOf parsers: Parser, at i: Int) {
        self.parsers.insert(parsers, at: i)
    }

    func remove(at i: Int) -> Parser {
        return parsers.remove(at: i)
    }

    func removeSubrange(_ bounds: Range<Int>) {
        parsers.removeSubrange(bounds)
    }

    func removeFirst() -> Parser {
        return parsers.removeFirst()
    }

    func removeFirst(_ n: Int) {
        parsers.removeFirst(n)
    }

    func removeAll(keepingCapacity keepCapacity: Bool = false) {
        parsers.removeAll()
    }

}
