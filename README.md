# argtree

[![Swift Version](https://img.shields.io/badge/swift-4.1-blue.svg)](https://swift.org) 
![Platform](https://img.shields.io/badge/platform-osx--64|linux--64-lightgrey.svg)
[![Build Travis-CI Status](https://travis-ci.org/dastrobu/argtree.svg?branch=master)](https://travis-ci.org/dastrobu/argtree) 

Command line argument parser package in Swift.

The basic idea is to define a tree structure of parsers which then parses all command line arguments.
This approach is very flexible and allows for quick and easy flag parsing for a simple scirpt, as well as 
complicated parse trees for big command command line programs.

## Table of Contents

  * [Installation](#installation)
     * [Swift Package Manager](#swift-package-manager)
     * [Dependencies](#dependencies)
  * [Getting started](#getting-started)
     * [Help Text generation](#help-text-generation)
  * [Parsers](#parsers)
     * [Flag](#flag)
     * [Option](#option)
     * [Command](#command)
     * [Var Args](#var-args)
     * [Handling Unexpected Arguments](#handling-unexpected-arguments)
  * [Default Action](#default-action-1)
  * [Error Handling](#error-handling)
  * [Logging](#logging)
  * [Architecture](#architecture)
     * [Parse Path](#parse-path)

## Installation

### Swift Package Manager
    dependencies: [
            .package(url: "https://github.com/dastrobu/argtree.git", from: "1.0.0"),
        ],
        
### Dependencies
At least `clang-3.6` is required. On linux one might need to install it explicitly.
There are no dependencies on macOS.

## Getting started
The following example shows a hello world script with one flag (no option or command) and generated help.

```swift
// global modal for the application
var verbose = false

try! ArgTree(description:
"""
usage: \(CommandLine.arguments[0])) [flags...]

hello world demo

flags:
""",
    parsers: [
        Flag(longName: "verbose", shortName: "v", description: "print verbose output") { _ in
            verbose = true
        }
    ]).parse()
    
// here comes the real program code after parsing the command line arguments
if verbose {
    print("hello world")
} else {
    print("hi")
}
```

### Help Text generation
Help texts can be generated automatically (partially), detailed in [Automatic Help Flag](#automatic-help-flag).
This is only true for global help. 
Help on individual commands is not generated, can however, easily be implemented by adding a `Help` flag to the command.

## Parsers
There are a variaty of parsers implemented to compose the parser tree. 
 * [Flag](#flag)
 * [Option](#option)
 * [Command](#command)
 * [VarArgs](#varargs)
 
If those are not sufficient, it is easy to implement a custom parser. Therefore, the `Parser` interface must be 
implemented, see [Architecture](#architecture) for details.

### Flag
A flag is a boolean property like `-v` or `--verbose`. A flag has a long and a short name, both are optional 
(however, not setting any of them does not make sense).
Handling a flag can either be done via the `parsed` closure
```swift
let verbose = false
try! ArgTree(parsers: [
    Flag(longName: "verbose", shortName: "v") { value, path in verbose = true }
]).parse()
```
or by accessing the parsed values later.
```swift
let verboseFlag = Flag(longName: "verbose", shortName: "v")
try! ArgTree(parsers: [verboseFlag]).parse()
let verbose = verboseFlag.value != nil
```

#### Flag Prefixes
By default long names get the prefix "--" and short names get the prefix "-". 
Other prefixes, to handle e.g. `+a`, can be specified.
```swift
let a = Flag(shortName: "a", shortPrefix: "+")
```
The same can be done for long prefixes.

#### Passing a Flag Multiple Times
By default passing the same flag multiple times is reported as error (`FlagParseError.flagAllowedOnlyOnce`). 
Sometimes it is, however, useful to be able to pass the same flag multiple times, e.g. if `-v` should print
a verbose output and `-v -v` should print a very verbose output. In this case the flag should have set the 
property `multiAllowed` to true. 
```swift
let verboseFlag = Flag(longName: "verbose", shortName: "v", multiAllowed: true)
try! ArgTree(parsers: [verboseFlag]).parse()
let verbosity = verboseFlag.values.count
```
The number of times the value was parsed can be accassed via the `values` property. It is up to the implementation
to decide if passing the same flag multiple times is simply ignored or meaning something useful.

#### Handling Unexpected Flags
By default, nothing happens if a flag was set at the command line, that has no meaning, i.e. that is not parsed.
To report all flag like arguments that have not meaning as errors, simply add the `UnexpectedFlagHandler` to 
the parsers. The handler must be added after the flag parsers, to report errors correctly.
```swift
try! ArgTree(parsers: [
        Flag(longName: "verbose", shortName: "v")
        UnexpectedFlagHandler()
]).parse()
```
In this case, all arguments starting with either the long or short prefix will be reported as errors. 
The `UnexpectedFlagHandler` supports a [Stop Token](#stop-token), to allow for flag like var args. Also, 
the `longPrefix` and `shortPrefix` can be customized. 
If flags with different prefixes are used, e.g. `-a` and `+a`, two seperate `UnexpectedFlagHandler` can be added, 
one for the standard prefix and one for the `+` prefix.

#### Multi Flags
Multi flags are combined flags (for short names). For example if there are flags `-a` and `-b` one could also 
pass the combined flag `-ab` or `-ba`, which is equivalent to `-a -b`. 

To achieve this kind of parsing use the `MultiFlag`.
```swift
try! ArgTree(parsers: [
    MultiFlag(parsers: [
        Flag(shortName: "a")
        Flag(shortName: "b")
    ])
]).parse()
```
Note that the mulit flag and all the added flags must have the same `shortPrefix` to get the expected result.

#### Automatic Help Flag
If initializing `ArgTree` with a `description` or `helpText` a help flag
is automatically added, which will show a help text. 
A minimal example would be:
```swift
try! ArgTree(helpText: "usage...").parse()
```
The call to the script with `-h` or `--help` passed as flag will print
```
usage...
```
and exit afterwards.

If a `helpText` is passed it will simply be printed. 
Alternatively, a `description` can be passed, which will generate a 
help text from the description and all descriptions of the passed flags and 
options.
```swift
try! ArgTree(description: 
"""
usage: \(CommandLine.arguments[0]) [flags...]

flags:
""", 
parsers: [
    Flag(longName: "foo", shortName: "f", description: "a foo flag"),
]).parse()
```
This example will print
```
usage: my_script [flags...]

flags:
--foo, -f a foo flag
```

##### Parse Order
The generated help flag is always added as first parser to make sure it plays together with 
[Var Args](#varargs) nicely. 
The order of the parsers can be changed after creation of the `ArgTree` object by manipulating its elements via the 
`MutableCollection` protocol (like an array). For example, to move the auto generated help flag parser to the end, do:
```swift
var argTree = ArgTree(description: "foo")
argTree.append(argTree.removeFirst())
```

##### Default Action
Generated help is set as default action automatically. If this is not intended, the default action
can be unset or set to something else. 
```swift
let argTree = ArgTree(description: "usage...")
argTree.defaultAction = nil
try! argtree.parse()
```

##### Exit After Help Printed
The generated help flag parser always exits with code 0 after printing the help text. If this
is not the intended behaviour one can pass a closure, which is called after the help text is printed.
The following example shows how to continue without any specific action after printing help.
```swift
let argTree = ArgTree(description: "usage...") { /* do nothing after help was printed */ }
try! argtree.parse()
```

##### Output Stream
Help text is printed to `stdout` by default. This can be customized, by setting 
the `writeToOutStream` delegate. For example one could redirect the output to a string.
```swift
let argTree = ArgTree(description: "usage...")
var out = ""
argTree.writeToOutStream = { s in
    print(s, to: &out)
}
```

### Option
An option is a key value property like `--foo=bar` or `--foo bar`. 
An option has a long and a short name, both are optional. 
Two syntaxes are supported, i.e. a key value pair can be passed separated by `=` or by passing the value as subsequent 
argument to the key. If the value to a key cannot be parsed, it will be reported as error 
(`OptionParseError.missingValueForOption`).
The following example shows the basic usage of options.
```swift
var foo: String = "default"
try! ArgTree(parsers: [
    Option(longName: "foo") {value, _ in foo = value}
]).parse()
```

#### Option Prefixes
Prefixes can be changed as for flags, see [Flag Prefixes](#flag-prefixes).

#### Passing an Option Multiple Times
Options can be passed multiples times, specifying different values. By default, passing an option multiple times
is reported as error (`OptionParseError.optionAllowedOnlyOnce`), 
as for flags, see [Passing a Flag Multiple Times](#passing-a-flag-multiple-times).
The following example shows how to implement an options, for which different values can be passed.
```swift
let fooOption = Option(longName: "foo", multiAllowed: true)
try! ArgTree(parsers: [fooOption]).parse()
fooOption.values.forEach{ value in /* ... */ }
```
In this case, it makes sense to handle the parsed options via `values` after parsing instead of handling them via
a closure. Although this is possible as well.
```swift
var foo: [String] = []
try! ArgTree(parsers: [
    Option(longName: "foo", multiAllowed: true) { value, _ in 
        foo.append(value)
    }
]).parse()
```

#### Int Option and Double Option
If only integers or floating point values are allowed for an option, 
the convenience parsers `IntOption` and `DoubleOption` can be employed. They work exactly like `Option` except 
that all values not parsable to an `Int` or `Double` will be reported as 
`OptionParseError.valueNotIntConvertible` or `OptionParseError.valueNotDoubleConvertible`, respectively.

#### Handling Unexpected Options
The mechanism is the same as for flags, see [Handling Unexpected Flags](#handling-unexpected-flags). 
Simply add a `UnexpectedOptionHandler` to the parsers.

### Command
A command is a special argument to change control flow of the program. Simple scripts or programs like e.g. `rm` 
often do not have commands, more advanced command line programs, like. e.g. `git` support a variety of commands 
and even sub-commands.
The following example shows an implementation of a program, handling the command `foo`.
```swift
try! ArgTree(parsers: [
    Command(name: "foo") { path in 
        /* handle foo command */ }
]).parse()
```
When it comes to handling commands, quickly things get complicated. For example the following questions arise:
 * Should a flag be supported only on the global level, or also on the level of each command?
   * For example, the `--verbose` flag might be supported on any level and have the same effect on any level, 
     i.e. setting the output to verbose for the whole program. 
   * The `--help` flag, on the other hand, might also be supported on every command, should however
     print a different help for each command.
   * Additional flags should only be supported for certain commands and for others not.
 * The same questions arises for options.
 * How are var args handled?
   * Some commands may take var args, others don't.
 * Must var args be handled on the global level and also on the command level?
 * Can commands be nested?
   * If there exist commands, there should be also sub-commands and sub-sub-commands.

The good thing is, everything can be done with ArgTree. However, it requires a bit of an understanding, how
the parsing works, since the order in which parses are added to the parse tree matters.
To support finding out the correct order, consider to switch on logging while parsing, see [Logging](#logging).

Some of the cases listed above are detailed in examples in the following sections.

#### Global Flags (or Options)
A global flag, that does the same for every command is easy to implement. Just add it before all commands.
```swift
var verbose = false;
try! ArgTree(parsers: [
    Flag(longName: "verbose", shortName: "v") { _ in verbose = true }
    Command(name: "foo") 
]).parse()
```
The same can be done for options.

#### Semi-Global Flags (or Options)
A so called semi-global flag is one that can be set on any level, but has different effects. 
The following example shows how to implement a custom help flag, if the generated help should not be used.
```swift
try! ArgTree(parsers: [
        Command(name: "foo", parsers: [
            Flag(longName: "help", shortName: "h") { _ in print("help for foo") }
        ]) 
        Flag(longName: "help", shortName: "h") { _ in print("global help") }
    ]).parse()
```
The corresponding parse tree is
```
argTree
  +-- foo
  |   +-- help(1)
  +-- help(2)
```
Here two differnt `Flag` instances (`help(1)` and `help(2)`) are employed to parse the help flags.

Instead of defining separate Flag instances, different actions can also be performed, based on the 
[parse path](#parse-path).
```swift
let help = Flag(longName: "help", shortName: "h")
let foo = Command(name: "foo", parsers: [help])
help.parsed = { _, path in
    switch path.last {
        case let cmd as Command where cmd === foo:
            print("foo help")
        // case let cmd as Command where ...  (other commands)
        default:
            print("global help")
        }
        exit(0)
    }
try! ArgTree(parsers: [help foo]).parse()
```
By using the path, to determine the context of a flag, very generic implementations are possible. 

The corresponding parse tree is
```
argTree
  +-- foo
  |   +-- help
  +-- help
```

Which strategy is better depends on the use case. If the flag should have the same description on evey command, 
it might be better to use the same instance everywhere and implement the logic based on the path segment. 
On the other hand, the description is different for all commands, it might be simpler to use different instances.

#### Var Args on Commands
For var args in general see [Var Args](#varargs). 
If var args should be passed to a specific command, it can be done simply by adding the var args on the command.
```swift
let fooVarArgs = VarArgs()
try! ArgTree(parsers: [
    Command(name: "foo", parsers: [fooVarArgs]) 
]).parse()
```
To add support for var args also on the global level, simply another var args object can be added at this level. 
It must be added after the command, otherwise the command will be parsed as var arg.
```swift
let globalVarArgs = VarArgs()
let fooVarArgs = VarArgs()
try! ArgTree(parsers: [
    Command(name: "foo", parsers: [fooVarArgs]),
    globalVarArgs,
]).parse()
```
Look at some examples, how var args will be parsed in this case.
```bash
my_script a b         # a and b parsed by globalVarArgs
my_script foo a b     # a and b parsed by fooVarArgs
my_script a foo b     # a parsed by globalVarArgs and b parsed by fooVarArgs
```
This is straightforward, when looking a the parse tree.
```
argTree
  +-- foo
  |   +-- globalVarArgs
  +-- fooVarArgs
```

#### Command Default Action
As on the root node `ArgTree` of the parse tree, there is an optional default action on each command. 
The default action is called, if no child parser consumed any further argument. 
The default action can be set on the command directly.

```swift
let foo = Command(name: "foo" parsers: [
        Flag(longName: "bar") { _ in print("--bar parsed") }
    ]) { _ in 
    print("foo (maybe also --bar parsed)") 
}
foo.defaultAction = { () in print("foo (--bar not parsed)") }
try! ArgTree(parsers: [foo, baz]).parse()
```

#### `parsed` and `afterChildrenParsed`
The command has two optional delegates: `parsed` and `afterChildrenParsed`.
The first, `parsed` is called, directly after the command was parsed, as for flags and options. At this time, 
however, no further arguments are parsed by parsers in the `parsers` property. 
The second delegate `afterChildrenParsed` is called, when the command was parsed and also all subsequent arguments
are parsed by parsers from the `parsers` property. So when a command is defined like in the following example
```swift
let bar = Flag(longName: "bar")
let foo = Command(name: "foo", parsers: [bar]) { _ in print("bar?: \(bar.value)") }
```
the trailing closure refers to `afterChildrenParsed` and all parsed values from any child parser can be accessed.

#### Nested Commands
`Commands`, `Flags`, `Options` and so on can be nested to arbitrary depth. 
This is why the package is called `ArgTree`. 
Here is a simple example.
```swift
let bar = Command(name: "bar") { _ in print("foo bar") }
let foo = Command(name: "foo", parsers: [foo])
let baz = Command(name: "baz") { _ in print("baz") }
foo.defaultAction = { () in print("foo (no sub command)") }
try! ArgTree(parsers: [foo, baz]).parse()
```
Here is the parse tree.
```
argTree
  +-- foo
  |   +-- bar
  +-- baz
```

### Var Args
Var args are all arguments, that are not specifically parsed by any other parser. 
Quite often, a script takes an arbitrary number of files as var args. 
Consider the following example
```bash
my_script -v file1 file2
my_script file1 file2 --verbose
```
Both scripts should process `file1` and `file2` as var args and handle `-v` or `--verbose` as flag, 
regardless of its position (to handle `-v` or `--verbose` as file, see [Stop Token](#stop-token)). 
This can be achieved, by defining the following parse tree.
```swift
let varArgs = VarArgs()
let argTree = ArgTree(parsers: [
    Flag(longName: "verbose", shortName: "-v", description: "verbose output") { _ _ in }
    varArgs
])
```
As can be seen in the example, defining `VarArgs` inline, as for `Flag` is possible but does not make sense.
Notice that it is important to place `varArgs` after the `Flag`, otherwise every argument would be parsed as
var arg instead of parsing it as flag. So usually `VarArgs` is added last in the `parsers` array. 
Parsed var args are usually handled, after the parsing was completed via the `RandomAccessCollection` protocol 
(like an array).
```swift
try! argTree.parse()
varArgs.values.forEach{ value in /* ... */ }
```

### Handling Unexpected Arguments 
If no var args are used, it might by helpful to report all errors as unexpected arg. 
In this case the `UnexpectedArgHandler` can be added as last parser. This will report any arg, not parsed by
another parser before as `ArgParseError.unexpectedArg`.

See also [Handling Unexpected Flags](#handling-unexpected-flags) and 
[Handling Unexpected Options](#handling-unexpected-options).

#### Stop Token
A stop token stops parsing subsequent arguments as they would normally be parsed. 
By default `--` is used as stop token. This means, all arguments passed after `--` will be parsed as var args.
This is helpful, if e.g. files with names that clash with a command or flag name should 
be passed as arguments. An example would be handling a file with name `-h`
```bash
my_script -- -h
```
which would normally print the help text. In this case `-h` is treated as var arg, e.g. a file name.

## Default Action
If no argument could be parsed, a default action can be performed. If there is a generated help flag, the default 
action will be set to printing the help text and exit. This can be customized by setting (or unsetting) a default 
action.
```swift
let argTree = ArgTree()
argTree.defaultAction = { () in print("this is the default") }
```
See also [Command Default Action](#command-default-action).

## Error Handling
The `parse` is supposed to throw errors on parsing the arguments. A variety of errors can be thrown and in simple 
scripts, it may be sufficient to force try the parse call (as in all examples in this document).
Any parse error will be reported to stderr and the program will exit. 
While this default behaviour is sufficient for simple scripts and programs, more suffisticated programs, might 
print nice error messages. This can be done by catching errors and doing some nice error handling.
```swift
do {
    try ArgTree(parsers: [UnexpectedArgHandler()]).parse()
} catch ArgParseError.unexpectedArg(argument:let arg, atIndex:_) {
    print("got an unexpected argument: \(arg)")
    exit(1)
} catch let error {
    print("unknown error \(error)")
    exit(99)
}

```

## Logging
To get a deeper understanding of why a certain argument is parsed or not parsed it can be very helpful to switch 
on logging.

Logging is done via the [LoggerAPI](https://github.com/IBM-Swift/LoggerAPI). So by default nothing is logged. 
To activate logging, one must configure a logger. A simple logger is e.g. 
[HeliumLogger](https://github.com/IBM-Swift/HeliumLogger) which can be employed in the following way.
```swift
import LoggerAPI
import HeliumLogger
Log.log = HeliumLogger(.debug)

let argTree = ArgTree()
try! argtree.parse()
```
Note that most of the logging is done on debug level, so this level should be activated to see any log output.

## Architecture

The basic idead it so define a tree of parsers, which then consume argument after argument. This package helps to
define the parser tree and invoke it. Each node in the parser tree usually parses specific types of arguments, e.g. 
flags or options. To understand, how the parser tree must be set up, it is important to know how the tree is 
traversed. Consider the following example
```
arguments = ['arg_0', 'arg_1', 'arg_2']
```
The first argument is always ignored, since it refers to the script name. Parsing is started at `arg_1`.
Now, if there is the following tree
```
argTree
  +-- parser_0
  |   +-- parser_0_1
  +-- parser_1
```
first, `arg_1` will be parsed. Thereby `argTree` calls each child parser with the arguments array and the index `i`, 
where parsing should be done. 
Each child parser, `parser_0` and `parser_1` in this case can decidide to consume any number of arguments 
starting from `i` and returns how many arguments it consumed. Hence, if `parser_0` decides to consume all arguments,
`parser_1` will never get called, since there are no arguments left. If `parser_0` consumes no argument, `parser_1` get
called on the same index `i` and may also consume an arbitrary amount of arguments. 
For any index `i` calling subsequent child parsers is stopped, as soon as one child parser consumes a non-zero amount
of argumts. After that, the index `i` is incremented by the number of consumed arguments and the list of child parsers
ist iterated again from the beginning.
So if `parser_0` consumes `arg_1`, `parser_1` is not called. Instead `i` is incremented by one and `parser_0` is called
again for `arg_2`. So it is important to understand that parsers with low indices always have higher precedence 
than the following parsers. 
One corner case is, if an argument is not consumed by any parser. In this case `i` is incremented by one and the 
next argument is parsed. This means that the argument not parsed is simply ignored. If ignoring arguments is not 
the expected behaviour, an `UnexpectedArgHandler` can be added to throw an error. 
It should be clear now that the `UnexpectedArgHandler` must be added as last parser, since it simply consumes any
argument and converts it into an error.

Having understood the parsing process for one node, it is straightforward to understand the whole tree. Since every 
parser node can consume any number of arguments, it is not important how the node parses arguments. So each node
may can itself delegate to child parses in the described way. This makes it very easy to reuse simple parsers 
for flags and options. 
Here is a short example for a command line program, which takes a global flag `-v` and two commands `foo` and `bar`
which themselves take flags `-f` and `-b` respectively. 
```
argTree
  +-- -v
  +-- foo
  |   +-- -f
  +-- bar
      +-- -b
```

### Parse Path

To define the context of a parsed argument, a parse path is always specified. This is simply an array of parsers in 
the call chain. Note, that the root parser is not added to the path.
So for the following example 
```
argTree
  +-- -v
  +-- foo
  |   +-- -f
  +-- bar
      +-- -b
```
there would be the folowing paths when parsing
```
[] : -v
[foo] : -f
[bar] : -b
```
This path can be used, if a parser should be used multiple times, but should act context aware. If e.g. `-v` should 
do something different for the `foo` and for `bar` the following tree should be defined
```
argTree
  +-- foo
  |   +-- -v
  |   +-- -f
  +-- bar
      +-- -v
      +-- -b
```
Or, alternatively
```
argTree
  +-- -v
  +-- foo
  |   +-- -v
  |   +-- -f
  +-- bar
      +-- -v
      +-- -b
```
if `-v` should also be supported on the global level. 
For an example on path specific actions see [Semi Global Flags (or Options)](#semi-global-flags-or-options).

