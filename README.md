# argtree

[![Swift Version](https://img.shields.io/badge/swift-4.1-blue.svg)](https://swift.org) 
![Platform](https://img.shields.io/badge/platform-osx--64|linux--64-lightgrey.svg)
[![Build Travis-CI Status](https://travis-ci.org/dastrobu/argtree.svg?branch=master)](https://travis-ci.org/dastrobu/argtree) 

Command line argument parser package in swift.

## Installation

### Dependencies
At least `clang-3.6` is required. On linux one might need to install it explicitly.
There are no dependencies on macOS.

### Swift Package Manager

    dependencies: [
            .package(url: "https://github.com/dastrobu/argtree.git", from: "1.0.0"),
        ],

## Getting started
The following example shows a hello world script wiht one flag (no option or command) and a generated help.

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
Help texts can be generated automatically (partially), detaild in [Automatic Help Flag](#automatic-help-flag)

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
Other prefixed can be specified via
```swift
let a = Flag(shortName: "a", shortPrefix: "+")
```
to handle the flag `+a`. The same can be done for long prefixes.

#### Passing a Flag Multiple Times
By default passing the same flag multiple times is reported as error (`FlagParseError.flagAllowedOnlyOnce`). 
Sometimes it is, however, useful to be able to pass the same flag multiple times, e.g. if `-v` should print
a verbose output and `-v -v` should print a very verbose output. In this case the flag should have set the 
property `multiAllowed` to true. 
```swift
let verboseFlag = Flag(longName: "verbose", shortName: "v")
try! ArgTree(parsers: [verboseFlag]).parse()
let verbosity = verboseFlag.values.count
```
The number of times the value was parsed can be accassed via the `values` property. It is up to the implementation
to decide if passing the same flag multiple times is simply ignored or meaning something useful.

#### Handling Unexpected Flags
By default, nothing happens if a flag was set at the command line, that has no meaning, i.e. that is not parsed.
To report all flag like arguments, that have not meaning as errors, simply add the `UnexpectedFlagHandler` to 
the parsers, after all flag parsers.
```swift
try! ArgTree(parsers: [
        Flag(longName: "verbose", shortName: "v")
        UnexpectedFlagHandler()
]).parse()
```
In this case, all arguments starting with either the long or short prefix will reported as error. 
The `UnexpectedFlagHandler` supports a [Stop Token](#stop-token), to allow for flag like var args. Also, 
the `longPrefix` and `shortPrefix` can be customized. 
If Flags with different prefixes are used, e.g. `-a` and `+a`, two seperate `UnexpectedFlagHandler` can be added, 
one for the standard prefix and one for the `+` prefix.

#### Multi Flags
TODO

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
Two syntaxes are supported, i.e. a key value pair can be passed separated by `=` or by passing them as subsequent 
arguments. If the value to a key cannot be parsed, it will be reported as error 
(`OptionParseError.missingValueForOption`).
The following example shows the basic usage of options.
```swift
var foo: String = "default"
try! ArgTree(parsers: [
    Option(longName: "foo") {value, path in 
        foo = value}
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
the convenience parsers `IntOption` and `DoubleOption` can be employed. They works exactly like `Option` except 
that all values, not parsable to an `Int` or `Double` will be reported as 
`OptionParseError.valueNotIntConvertible` or `OptionParseError.valueNotDoubleConvertible`, respectively.

#### Handling Unexpected Options
The mechanism is the same as for flags, see [Handling Unexpected Flags](#handling-unexpected-flags). 
Simply add a `UnexpectedOptionHandler` to the parsers.

### Command
A command is a special argument to change control flow of the program. Simple scripts or programs like e.g. `rm` 
often do not have commands, more advanced command line programs, like. e.g. `git` support a variaty of commands 
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
   * The `--help` flag, on the other hand, might also be supported on every command, should however, 
     print a different help for each command.
   * Additional flags should only be supported for certain commands and for others not.
 * The same questions arise for options.
 * How are var args handled?
   * Some commands may take var args, others don't.
 * Must var args be handled on the global level and also on the command level?
 * Can commands be nested?
   * If there exist commands, there should be also sub-commands and sub-sub-commands.

The good thing is, everything can be done with ArgTree. However, it requires a bit of an understanding, how
the parsing works, since the order in which parses are added to the parse tree matters.
To support finding out the correct order, consider to switch on logging while parsing, to get a deeper 
understanding of why a certain argument is parsed or not parsed, see [Logging](#logging).

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

Instead of defining separate Flag instances, different actions can also be performed, based on the parse path.
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
By using the path, to determine the context of a flag, very generic implementations of a flag are possible. 
The same can be done for options.

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
To add support for var args also on the global level, simply add another var args object at this level. 
Make sure to add it after the command. 
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
however, no further arguments are parsed by parsers in on the `parsers` property. 
The second delegate `afterChildrenParsed` is called, when the command was parsed and also all subsequent arguments
are parsed by parsers from the `parsers` property. So when a command is defined like in the following example
```swift
let bar = Flag(longName: "bar")
let foo = Command(name: "foo", parsers: [bar]) { _ in print("bar?: \(bar.value)") }
```
the trailing closure refers to `afterChildrenParsed` and one could access parsed values from any child parser.

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
This can be achived, by defining the following parse tree.
```swift
let varArgs = VarArgs()
let argTree = ArgTree(parsers: [
    Flag(longName: "verbose", shortName: "-v", description: "verbose output") {_ _ in }
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

## Logging
TODO

## Architecture
TODO
