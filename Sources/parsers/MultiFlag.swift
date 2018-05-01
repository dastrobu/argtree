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
            return 0
        }
        if let j: String.Index = arg.index(of: shortPrefix) {
            let prefixString = String(shortPrefix)
            // create full flags
            let flags: [String] = arg.suffix(from: arg.index(after: j)).map({
                prefixString + String($0)
            })
            // find a valid flag parser for each flag
            let matched: [(parser: Flag, flag: String)] =
                flags.compactMap({ flag in
                    if let parser = parsers
                        .compactMap({ $0 as? Flag })
                        .first(where: { parser in parser.aliases.contains(flag) }) {
                        return (parser: parser, flag: flag)
                    }
                    return nil
                })
            // check if all flags are valid flags, do not treat this as multi flag otherwise
            if matched.count == flags.count {
                try matched.forEach { parser, flag in
                    _ = try parser.parse(arguments: arguments[..<i] + [flag], atIndex: i, path: path + [self])
                }
                return 1
            }
        }
        return try parseTree(arguments: arguments, atIndex: i, path: path + [self], childParsers: parsers)
    }

    public var description: [(argument: String, description: String)] {
        return parsers.flatMap({ $0.description })
    }
}

/** extension to support collection protocols for parsers */
public extension MultiFlag {
    public var indices: CountableRange<Int> {
        return parsers.indices

    }

    public subscript(bounds: Range<Int>) -> ArraySlice<Parser> {
        get {
            return parsers[bounds]
        }
        set(newValue) {
            parsers[bounds] = newValue
        }
    }

    public subscript(position: Int) -> Parser {
        get {
            return parsers[position]
        }
        set(newValue) {
            parsers[position] = newValue
        }
    }

    public var startIndex: Int {
        return parsers.startIndex
    }

    public var endIndex: Int {
        return parsers.endIndex
    }

    public func append(_ parser: Parser) {
        parsers.append(parser)
    }

    public func insert(_ parser: Parser, at i: Int) {
        parsers.insert(parser, at: i)
    }

    public func insert(contentsOf parsers: Parser, at i: Int) {
        self.parsers.insert(parsers, at: i)
    }

    public func remove(at i: Int) -> Parser {
        return parsers.remove(at: i)
    }

    public func removeSubrange(_ bounds: Range<Int>) {
        parsers.removeSubrange(bounds)
    }

    public func removeFirst() -> Parser {
        return parsers.removeFirst()
    }

    public func removeFirst(_ n: Int) {
        parsers.removeFirst(n)
    }

    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        parsers.removeAll()
    }

}
