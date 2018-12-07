#if os(macOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

import LoggerAPI

/**
 * A parse path segment can be used to form a parse path
 */
public protocol ParsePathSegment {

}

/**
 * A parser tree consists of nodes (in order) which allow to construct complex parser trees.
 */
public protocol Parser {
    /**
     * description, which may be used for help texts
     */
    var description: [(argument: String, description: String)] { get }

    /**
     * parser method
     *
     * - Parameters:
     *   - args: arguments to be parsed
     *   - atIndex: index to be parsed
     * - Returns: number of tokens consumed while parsing
     */
    func parse(arguments: [String], atIndex i: Int, path: [ParsePathSegment]) throws -> Int
}

/**
 * Parser which acts as a (non-leaf) node in the parser tree and delegates to other parsers
 */
public protocol ParserNode: RandomAccessCollection, MutableCollection {

    /** default action to be called if no token was consumed by any parser */
    var defaultAction: (() -> Void)? { get set }

    mutating func append(_ parser: Parser)

    mutating func insert(_ parser: Parser, at i: Int)

    mutating func insert(contentsOf parsers: Parser, at i: Int)

    mutating func remove(at i: Int) -> Parser

    mutating func removeSubrange(_ bounds: Range<Int>)

    mutating func removeFirst() -> Parser

    mutating func removeFirst(_ n: Int)

    mutating func removeAll(keepingCapacity keepCapacity: Bool)
}

/**
 * Parser that handles arguments from the command line.
 */
public class ArgTree: ParserNode {

    /** delegate to write to an output stream, defaults to stdout. */
    public var writeToOutStream: (_ s: String) -> Void = { s in
        print(s)
    }

    /** all child parsers to which parsing is delegated */
    fileprivate var parsers: [Parser] = []

    public var defaultAction: (() -> Void)?

    public init(parsers: [Parser] = []) {
        self.parsers = parsers
    }

    /**
     * - Parameters:
     *   - helpText: help text to display on --help or -h (no automatic argument description)
     */
    public convenience init(helpText: String,
                            parsers: [Parser] = [],
                            helpPrinted: @escaping () -> Void = {
                                exit(0)
                            }) {
        self.init(parsers: parsers)
        let writeHelp: () -> Void = {
            self.writeToOutStream(helpText)
            helpPrinted()
        }
        // add help as first parse, to play together with the var arg parser
        Log.debug("creating generated help flag as first parser")
        insert(Help(longName: "help", shortName: "h", parsed: { _ in writeHelp() }), at: 0)
        defaultAction = writeHelp
    }

    /**
     * - Parameters:
     *   - description: description to create a help text from (description for individual arguments will be generated)
     */
    public convenience init(description: String,
                            parsers: [Parser] = [],
                            helpPrinted: @escaping () -> Void = {
                                exit(0)
                            }) {
        self.init(parsers: parsers)
        let printHelp: () -> Void = {
            [unowned self] in
            var rows: [[String]] = []
            self.flatMap({ $0.description })
                .forEach({ (argument: String, description: String) in
                    rows.append(["   ", argument, description])
                })
            self.writeToOutStream(
                "\(description)\n\(Help.createTable(rows))")
            helpPrinted()
        }
        // add help as first parse, to play together with the var arg parser
        Log.debug("creating generated help flag as first parser")
        insert(Help(longName: "help", shortName: "h", parsed: { _ in printHelp() }), at: 0)
        defaultAction = printHelp
    }

    @discardableResult
    public func parse(arguments: [String] = CommandLine.arguments) throws -> Int {
        // start parsing from argument 1, since 0 is the name of the script
        Log.debug("parsing arguments \(arguments) starting from index 1")
        return try parse(arguments: arguments, atIndex: 1, path: []) + 1

    }

    public func parse(arguments: [String], atIndex i: Int, path: [ParsePathSegment]) throws -> Int {
        if i >= arguments.count {
            Log.debug("parse index \(i) is out of bounds, number of arguments is \(arguments.count)")
            if let defaultAction = defaultAction {
                Log.debug("calling default action")
                defaultAction()
            } else {
                Log.debug("no default action set, doing nothing")
            }
            return 0
        }
        return try parseTree(arguments: arguments, atIndex: i, path: path, childParsers: parsers)
    }

}

internal func parseTree(arguments: [String],
                        atIndex i: Int,
                        path: [ParsePathSegment],
                        childParsers: [Parser]) throws -> Int {
    Log.debug("parse path is \(path)")
    var i = i
    var totalTokensConsumed = 0
    argumentLoop: while i < arguments.count {
        Log.debug("next argument to consume is '\(arguments[i])' at index \(i)")
        for parser in childParsers {
            let tokensConsumed = try parser.parse(arguments: arguments, atIndex: i, path: path)
            if tokensConsumed > 0 {
                Log.debug("child parser \(parser) consumed \(tokensConsumed) arguments")
                i += tokensConsumed
                totalTokensConsumed += tokensConsumed
                continue argumentLoop
            }
        }
        i += 1
    }
    return totalTokensConsumed
}

/** extension to support collection protocols for parsers */
public extension ArgTree {
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

    @discardableResult
    public func remove(at i: Int) -> Parser {
        return parsers.remove(at: i)
    }

    public func removeSubrange(_ bounds: Range<Int>) {
        parsers.removeSubrange(bounds)
    }

    @discardableResult
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
