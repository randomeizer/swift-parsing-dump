# swift-parsing-dump

A utility to aid in dumping debug information within a [swift-parsing](https://github.com/pointfreeco/swift-parsing) `Parser`.

`Parser`s are composable, and sometimes determining exactly what is being consumed by a particular parser is tricky. 

This library makes it simple to dump the input and output of a `Parser` at any given stage.

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

In both cases, the result is the same: `myNumber` will be a parser of type `Dump<Parsers.IntParser<Substring, Int>>`. When calling `myNumber.parse(&input)`, it will dump something like the following to standard output:

```
PARSING DUMP:
INPUT:

```
