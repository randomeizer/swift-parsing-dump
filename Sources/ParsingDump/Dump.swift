import CustomDump
import Foundation
import Parsing

/// Provides a way of dumping information about the current `Parser` context
/// when parsing or printing.
public struct Dump<Upstream: Parser>: Parser
{
  /// Determines the parse/print detail level. May be:
  ///
  /// - `minimal`: no type information about the parser or its input or output.
  /// - `inputOutput`: prints input/output types, but no parser information.
  /// - `full`: prints parser and input/output information.
  public enum Format {
    case minimal
    case inputOutput
    case full
  }
  
  public let upstream: Upstream
  
  public let label: String
  public let indent: Int
  public let maxDepth: Int
  public let format: Format
  
  /// Constructs a new `Dump` parser.
  ///
  /// - Parameters:
  ///   - label: The label to prefix the dump with. Defaults to `"DUMP"`.
  ///   - indent: The amount of indentation. Defaults to `0`.
  ///   - maxDepth: The maximum depth to dump down to. Defaults `Int.max`.
  ///   - format: The level of detail to output. Defaults to `Dump.Format.inputOutput`
  @inlinable
  public init(_ label: String = "DUMP", indent: Int = 0, maxDepth: Int = .max, format: Format = .inputOutput, @ParserBuilder _ build: () -> Upstream) {
    self.upstream = build()
    self.label = label
    self.indent = indent
    self.maxDepth = maxDepth
    self.format = format
  }
  
  @usableFromInline
  var upstreamName: String {
    switch format {
    case .full:
      return "\(String(describing: Upstream.self))."
    default:
      return ""
    }
  }
  
  @usableFromInline
  var inputName: String? {
    switch format {
    case .inputOutput, .full:
      return String(describing: Input.self)
    default:
      return nil
    }
  }
  
  @usableFromInline
  var outputName: String? {
    switch format {
    case .inputOutput, .full:
      return String(describing: Output.self)
    default:
      return nil
    }
  }
  
  @inlinable
  public func parse(_ input: inout Upstream.Input) throws -> Upstream.Output {
    #if DEBUG
    Swift.print("\(label): \(upstreamName)parse(\(inputName ?? "_")) -> \(outputName ?? "_")")
    do {
      let original = input
      let result = try upstream.parse(&input)
      Swift.print("input:")
      Swift.print(diff(original, input) ?? "<no change>")
      Swift.print("output:")
      return customDump(result, indent: indent, maxDepth: maxDepth)
    } catch {
      Swift.print("error:")
      throw customDump(error, indent: indent, maxDepth: maxDepth)
    }
    #else
    return try upstream.parse(&input)
    #endif
  }
}

// Adds dumping to `ParserPrinter` implementations.
extension Dump: ParserPrinter where Upstream: ParserPrinter {
  @inlinable
  public func print(_ output: Upstream.Output, into input: inout Upstream.Input) throws {
    #if DEBUG
    Swift.print("\(label): \(upstreamName)print(\(outputName ?? "_"), into: \(inputName ?? "_"))")
    Swift.print("output:")
    customDump(output, indent: indent, maxDepth: maxDepth)
    do {
      let original = input
      try upstream.print(output, into: &input)
      Swift.print("input:")
      Swift.print(diff(original, input) ?? "<no change>")
    } catch  {
      Swift.print("error:")
      throw customDump(error, indent: indent, maxDepth: maxDepth)
    }
    #else
    return try upstream.print(output, into: &input)
    #endif
  }
}


extension Parser {
  /// Transforms the `Parser` into a "dumping" parser. It will dump the input and output
  /// (and error, if relevant) to standard output when executed in DEBUG mode.
  ///
  ///
  func dump(_ label: String = "DUMP", indent: Int = 0, maxDepth: Int = .max, format: Dump<Self>.Format = .inputOutput) -> Dump<Self> {
    .init(label, indent: indent, maxDepth: maxDepth, format: format) {
      self
    }
  }
}

extension Parsers {
  /// The `Dump` parser type.
  typealias Dump = ParsingDump.Dump
}
