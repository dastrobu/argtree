import Foundation

/**
 * callback after a value was parsed
 *
 * - Parameters:
 *   - path: the path to the parser. If e.g. a flag is used on several commands, on can determine on which command the
 *           flag was parsed from the tree.
 */
public typealias OnParsed = ((_ path: [ParsePathSegment]) -> Void)

/**
 * callback after a value was parsed
 *
 * - Parameters:
 *   - value: the parsed value.
 *   - path: the path to the parser. If e.g. a flag is used on several commands, on can determine on which command the
 *           flag was parsed from the tree.
 */
public typealias OnValueParsed<T> = ((_ value: T, _ path: [ParsePathSegment]) -> Void)

/**
 * Parser base class for arbitrary argument parses, such as flags, key-value options or commands
 */
open class ValueParser<T>: Parser, ParsePathSegment, CustomDebugStringConvertible, @unchecked Sendable {

    private let lock = NSLock()

    /** token after which all arguments will be treated as var args, instead of parsing them as e.g. flags */
    public var stopToken: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _stopToken
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _stopToken = newValue
        }
    }
    private var _stopToken: String?

    private var _values: [T] = []
    public var values: [T] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _values
        }
    }

    internal func appendValue(_ value: T) {
        lock.lock()
        defer { lock.unlock() }
        _values.append(value)
    }

    internal func clearValues() {
        lock.lock()
        defer { lock.unlock() }
        _values.removeAll()
    }

    public let aliases: [String]

    public var valueConverter: ((String, Int) throws -> T)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _valueConverter
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _valueConverter = newValue
        }
    }
    private var _valueConverter: ((String, Int) throws -> T)?

    private let argumentDescription: String?

    public var parsed: OnValueParsed<T>? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _parsed
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _parsed = newValue
        }
    }
    private var _parsed: OnValueParsed<T>?

    /**
     * - Parameters:
     *   - aliases: all strings that should be matched by this parser, e.g. for a flag '-v' and '--verbose'
     *   - description: description for help text generation
     *   - stopToken: token, which causes parsing to stop. Subsequent arguments will be consumend by another parser.
     *   - parsed: call back closure, after the value was parsed
     */
    public init(aliases: [String],
                description: String?,
                stopToken: String? = "--",
                parsed: OnValueParsed<T>? = nil) {
        self.aliases = aliases
        self.argumentDescription = description
        self._parsed = parsed
        self._stopToken = stopToken
    }

    public func parse(arguments: [String], atIndex i: Int, path: [ParsePathSegment]) throws -> Int {
        let arg = arguments[i]

        lock.lock()
        let currentStopToken = _stopToken
        lock.unlock()

        if arg == currentStopToken {
            logger.debug("stopping parsing on stopToken '\(arg)'")
            return 0
        }
        for alias in aliases where arg == alias {
            logger.debug("\(self) parsing argument \(arg)")

            lock.lock()
            let converter = _valueConverter
            lock.unlock()

            if let converter = converter {
                let value = try converter(arg, i)

                lock.lock()
                self._values.append(value)
                let callback = _parsed
                lock.unlock()

                if let parsed = callback {
                    parsed(value, path)
                }
            }
            return 1
        }
        return 0
    }

    public var debugDescription: String {
        return "\(String(describing: ValueParser.self))(\(aliases))"
    }

    public var description: [(argument: String, description: String)] {
        if let argumentDescription = argumentDescription {
            return [(argument: aliases.joined(separator: ", "), description: argumentDescription)]
        } else {
            return []
        }
    }

    /**
     * - Returns: the parsed value, if exactly one value was parse, nil otherwise.
     */
    public var value: T? {
        lock.lock()
        defer { lock.unlock() }
        if _values.count == 1 {
            return _values.first
        }
        return nil
    }
}
