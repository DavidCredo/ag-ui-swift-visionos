// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

import XCTest
@testable import AGUICore

final class JSONValueTests: XCTestCase {
    private func decode(_ json: String) throws -> JSONValue {
        try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
    }

    private func encode(_ value: JSONValue) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }

    // MARK: - Decoding

    func testDecodesBooleansAsBool() throws {
        XCTAssertEqual(try decode("true"), .bool(true))
        XCTAssertEqual(try decode("false"), .bool(false))
    }

    func testDecodesZeroAndOneAsNumbers() throws {
        XCTAssertEqual(try decode("1"), .number(1))
        XCTAssertEqual(try decode("0"), .number(0))
    }

    func testDecodesAllKinds() throws {
        let value = try decode(#"{"n":null,"b":false,"i":2,"d":2.5,"s":"x","a":[1,true,"y",null],"o":{"k":{}}}"#)
        XCTAssertEqual(value, .object([
            "n": .null,
            "b": .bool(false),
            "i": .number(2),
            "d": .number(2.5),
            "s": .string("x"),
            "a": .array([.number(1), .bool(true), .string("y"), .null]),
            "o": .object(["k": .object([:])]),
        ]))
    }

    // MARK: - Encoding

    func testEncodesBooleansAsBooleans() throws {
        XCTAssertEqual(try encode(["a": false, "b": true, "c": [false]]), #"{"a":false,"b":true,"c":[false]}"#)
    }

    func testEncodesIntegralNumbersWithoutFraction() throws {
        XCTAssertEqual(try encode([1, 0, -3, 1.0, 1_000_000]), "[1,0,-3,1,1000000]")
    }

    func testEncodesFractionalNumbers() throws {
        XCTAssertEqual(try encode([2.5, -0.25]), "[2.5,-0.25]")
    }

    func testEncodesNull() throws {
        XCTAssertEqual(try encode(["k": nil]), #"{"k":null}"#)
    }

    func testRoundTripIsLossless() throws {
        let json = #"{"a":[1,0,true,false,null,"s",2.5],"b":{"c":{"d":false}}}"#
        XCTAssertEqual(try encode(try decode(json)), json)
    }

    // MARK: - Literals

    func testLiterals() {
        let value: JSONValue = ["nil": nil, "bool": true, "int": 1, "double": 1.5, "string": "s", "array": [1, "a"]]
        XCTAssertEqual(value, .object([
            "nil": .null,
            "bool": .bool(true),
            "int": .number(1),
            "double": .number(1.5),
            "string": .string("s"),
            "array": .array([.number(1), .string("a")]),
        ]))
    }

    func testIsSendableAndHashable() {
        func requireSendable<T: Sendable>(_: T) {}
        let value: JSONValue = ["a": 1]
        requireSendable(value)
        XCTAssertEqual(Set([value, value]).count, 1)
    }
}
