# swift-parsing-dump

A utility to aid in dumping debug information within a [swift-parsing](https://github.com/pointfreeco/swift-parsing) `Parser`.

`Parser`s are composable, and sometimes determining exactly what is being consumed by a particular parser is tricky. 

This library makes it simple to dump the input and output of a `Parser` at any given stage.

## Installation

This can be added to a Swift Package via the `dependencies`:

```swift
// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "my-cool-package",
  // ...
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.9.0"),
    .package(url: "https://github.com/randomeizer/swift-parsing-dump", from: "0.1.0"),
    // other dependencies...
  ],
  targets: [
    .target(
      name: "MyCoolPackage",
      dependencies: [
        .product(name: "Parsing", package: "swift-parsing"),
        .product(name: "ParsingDump", package: "swift-parsing-dump"),
      ]),
    ),
  ],
)
```

You can then import it into any file via:

```swift
import ParsingDump
```

## Usage

There are two methods available:

1. A parser containing other parsers:

```swift
let myNumber = Dump {
  Int.parser(of: Substring.self)
}
```

2. Via a method call on any parser:

```swift
let myNumber = Int.parser().dump()
```

The latter is the simplest to insert or drop from

In both cases, the result is the same: `myNumber` will be a parser of type `Dump<Parsers.IntParser<Substring, Int>>`. This will affect any function signatures further up the chain as well, unless you are using `.eraseToAnyParser()` or `.eraseToAnyParserPrinter()`.

When calling `myNumber.parse(&input)`, it will dump something like the following to standard output:

```
DUMP: parse(Substring) -> Int
input:
- "1234"
+ ""
output:
1234
```

## Options

There are several options for formatting the output.

* `_ label:` - if provided, the label is printed before the method call details. Defaults to "DUMP"
* `maxDepth:` - The depth to go when dumping the output and error values. Defaults to `Int.max`.
* `format:` - Either `.minimal` (no type information), `.inputOutput` (type information for the input and output only), or `.full` (type information for the `Parser` as well.) Defaults to `.inputOutput`.

For example, given:

```swift
struct EmailAddress: Equatable {
  let username: String
  let server: String
}
let email = Parse(EmailAddress.init(username:server:)) {
  PrefixUpTo("@").map(.string)
  "@"
  Rest().map(.string)
}
```

...we can dump it in a few ways. For example:

```swift
let _ try email.dump("email").parse("foo@bar.com")
```

...will dump this to `SDTOUT`:

```
email: parse(Substring) -> EmailAddress
input:
- "foo@bar.com"
+ ""
output:
EmailAddress(
  username: "foo",
  server: "bar.com"
)
```

Or:

```swift
let _ = try email.dump("email", maxDepth: 0, format: .minimal).parse("foo@bar.com")
```

...will dump this:

```
email: parse(_) -> _
input:
- "foo@bar.com"
+ ""
output:
EmailAddress(…)
```

Or you can go big and get the whole type signature with:

```swift
let _ = try email.dump("email", format: .full).parse("foo@bar.com")
```

...and dump this:

```
email: Parse<Map<ZipOVO<MapConversion<PrefixUpTo<Substring>, SubstringToString>, String, MapConversion<Rest<Substring>, SubstringToString>>, EmailAddress>>.parse(Substring) -> EmailAddress
input:
- "foo@bar.com"
+ ""
output:
EmailAddress(
  username: "foo",
  server: "bar.com"
)
```

## Errors

It will also handle errors, outputting structure of the error instead of just the description. For example, using our `email` parser from above with a `#` instead of an `@` in the email address like so:

```swift
let _ = try email.dump("email").parse("foo#bar.com")
```

...will still throw an error, but will also dump the following to `STDOUT`:

```
DUMP: parse(Substring) -> EmailAddress
input:
foo#bar.com
error:
ParsingError.failed(
  "expected prefix up to \"@\"",
  ParsingError.Context(
    debugDescription: "unexpected input",
    originalInput: "foo#bar.com",
    remainingInput: "foo#bar.com",
    underlyingError: nil
  )
)
```

If there is a difference between the input before being parsed and after being parsed, it will be output as a diff. For example,
we could capture the `username` with `Prefix` instead of `PrefixUpTo`, which will consume matching all characters instead of
reading ahead to the delimiter:

```swift
let email = Parse(EmailAddress.init(username:server:)) {
  Prefix { $0 != "@" }.map(.string)
  "@"
  Rest().map(.string)
}
let _ = try email.dump("email").parse("foo#bar.com")
```

...and instead, we get this output dumped:

```
email: parse(Substring) -> EmailAddress
input:
- "foo#bar.com"
+ ""
error:
ParsingError.failed(
  "expected \"@\"",
  ParsingError.Context(
    debugDescription: "unexpected input",
    originalInput: "",
    remainingInput: "",
    underlyingError: nil
  )
)
```

We get a difference this time, because `Prefix` consumed all the non-`@` characters.
