import XCTest
import Parsing
@testable import ParsingDump

struct EmailAddress: Equatable {
  let username: String
  let server: String
}

final class ParsingDumpTests: XCTestCase {
    func testIntParse() throws {
      let intParser = Dump {
        Int.parser(of: Substring.self)
      }
      var input = "1234"[...]
      let result = try intParser.parse(&input)
      XCTAssertEqual(1234, result)
    }
  
  func testIntPrint() throws {
    let intParser = Dump {
      Int.parser(of: Substring.self)
    }
    var input = ";other stuff"[...]
    try intParser.print(1234, into: &input)
    XCTAssertEqual("1234;other stuff", input)
  }
  
  func testWholeEmailParse() throws {
    let emailParser = Parse(EmailAddress.init(username:server:)) {
      PrefixUpTo("@").map(.string)
      "@"
      Rest().map(.string)
    }
    .dump()
    
    var input = "foo@bar.com"[...]
    let result = try emailParser.parse(&input)
    XCTAssertEqual(EmailAddress(username: "foo", server: "bar.com"), result)
  }
  
  func testPartialEmailParse() throws {
    let emailParser = Parse(EmailAddress.init(username:server:)) {
      PrefixUpTo("@").map(.string).dump("username")
      "@"
      Rest().map(.string)
    }
    
    var input = "foo@bar.com"[...]
    let result = try emailParser.parse(&input)
    XCTAssertEqual(EmailAddress(username: "foo", server: "bar.com"), result)
  }
  
  func testFailedEmailParse() throws {
    let emailParser = Parse(EmailAddress.init(username:server:)) {
      PrefixUpTo("@").map(.string)
      "@"
      Rest().map(.string)
    }.dump()
    
    var input = "foo#bar.com"[...]
    XCTAssertThrowsError(try emailParser.parse(&input))
  }
  
  func testWholeEmailPrint() throws {
    let emailParser = ParsePrint(.memberwise(EmailAddress.init(username:server:))) {
      PrefixUpTo("@").map(.string)
      "@"
      Rest().map(.string)
    }
    .dump()
    
    var input = ""[...]
    try emailParser.print(.init(username: "foo", server: "bar.com"), into: &input)
    XCTAssertEqual("foo@bar.com", input)
  }

  
  func testPartialEmailPrint() throws {
    let emailParser = ParsePrint(.memberwise(EmailAddress.init(username:server:))) {
      PrefixUpTo("@").map(.string).dump("username")
      "@"
      Rest().map(.string)
    }
    
    var input = ""[...]
    try emailParser.print(.init(username: "foo", server: "bar.com"), into: &input)
    XCTAssertEqual("foo@bar.com", input)
  }

  func testNoChangeOnParse() throws {
    let parser = Not { "foo" }.dump()
    var input = "bar"[...]
    try parser.parse(&input)
    XCTAssertEqual("bar", input)
  }
  
  func testParseMinimalFormat() throws {
    let emailParser = Parse(EmailAddress.init(username:server:)) {
      PrefixUpTo("@").map(.string)
      "@"
      Rest().map(.string)
    }.dump(format: .minimal)
    
    var input = "foo@bar.com"[...]
    let result = try emailParser.parse(&input)
    XCTAssertEqual(EmailAddress(username: "foo", server: "bar.com"), result)
  }
  
  func testParseFullFormat() throws {
    let emailParser = Parse(EmailAddress.init(username:server:)) {
      PrefixUpTo("@").map(.string)
      "@"
      Rest().map(.string)
    }.dump(format: .full)
    
    var input = "foo@bar.com"[...]
    let result = try emailParser.parse(&input)
    XCTAssertEqual(EmailAddress(username: "foo", server: "bar.com"), result)
  }
  
  func testPrintMinimalFormat() throws {
    let emailParser = ParsePrint(.memberwise(EmailAddress.init(username:server:))) {
      PrefixUpTo("@").map(.string)
      "@"
      Rest().map(.string)
    }.dump("email", format: .minimal)
    
    var input = ""[...]
    try emailParser.print(.init(username: "foo", server: "bar.com"), into: &input)
    XCTAssertEqual("foo@bar.com", input)
  }
  
  func testPrintFullFormat() throws {
    let emailParser = ParsePrint(.memberwise(EmailAddress.init(username:server:))) {
      PrefixUpTo("@").map(.string)
      "@"
      Rest().map(.string)
    }.dump("email", format: .full)
    
    var input = ""[...]
    try emailParser.print(.init(username: "foo", server: "bar.com"), into: &input)
    XCTAssertEqual("foo@bar.com", input)
  }

}
