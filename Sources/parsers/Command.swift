#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public enum CommandParseError: Error {
    case commandAllowedOnlyOnce(command: Command, atIndex: Int)
}

/**
 * command parser for sub-commands in the command tree
 */
open class Command: ValueParser<Bool>, ParserNode {

    fileprivate var parsers: [Parser] = []

    /** delegate to write to an output stream, defaults to stdout. */
    public var writeToOutStream: (_ s: String) -> Void = { s in
        print(s)
    }

    public var defaultAction: (() -> Void)?

    /** callback invoked after all child parsers where invoked */
    public var afterChildrenParsed: OnParsed?

    /**
     * Create a Command.
     * - Parameters:
     *   - aliases: all strings that should be matched by this parser, e.g. for a flag '-v' and '--verbose'
     *   - description: description to be shown in the global help
     *                  (will also be used for generated help on the command, if `helpText` is not given)
     *   - helpTest: help text for the generated help
     */
    public init(name: String,
                aliases: [String] = [],
                description: String = "",
                helpText: String? = nil,
                stopToken: String? = "--",
                parsed: OnParsed? = nil,
                parsers: [Parser] = [],
                helpPrinted: @escaping () -> Void = {
                    exit(0)
                },
                afterChildrenParsed: OnParsed? = nil) {

        self.afterChildrenParsed = afterChildrenParsed
        super.init(aliases: [name] + aliases, description: description, stopToken: stopToken, parsed: { _, path in
            if let parsed = parsed {
                parsed(path)
            }
        })

        valueConverter = { _, _ in
            return true
        }

        self.parsers = parsers

        let printHelp: () -> Void = {
            [unowned self] in
            var rows: [[String]] = []
            self.flatMap({ $0.description })
                .forEach({ (argument: String, description: String) in
                    rows.append(["   ", argument, description])
                })
            self.writeToOutStream(
                "\(helpText ?? description)\n\(Help.createTable(rows))")
            helpPrinted()
        }
        // add help as first parse, to play together with the var arg parser
        logger.debug("creating generated help flag as first parser")
        insert(Help(longName: "help", shortName: "h", parsed: { _ in printHelp() }), at: 0)
        defaultAction = printHelp
    }

    open override func parse(arguments: [String], atIndex i: Int, path: [ParsePathSegment]) throws -> Int {
        let tokensConsumed = try super.parse(arguments: arguments, atIndex: i, path: path)
        if tokensConsumed > 0 {
            if values.count > 1 {
                // do not parse the same command twice
                throw CommandParseError.commandAllowedOnlyOnce(command: self, atIndex: i)
            }
            let tokensConsumedByChildren = try parseTree(arguments: arguments,
                atIndex: i + tokensConsumed,
                path: path + [self],
                childParsers: parsers)
            if let afterChildrenParsed = self.afterChildrenParsed {
                afterChildrenParsed(path)
            }
            if let defaultAction = defaultAction {
                if tokensConsumedByChildren == 0 {
                    defaultAction()
                }
            }

            return tokensConsumed + tokensConsumedByChildren
        }
        return tokensConsumed
    }

    public override var debugDescription: String {
        return "\(String(describing: Command.self))(\(aliases))"
    }
}

/** extension to support collection protocols for parsers */
public extension Command {
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

    @discardableResult
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
