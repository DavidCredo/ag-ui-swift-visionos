// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

import XCTest
@testable import AGUICore

/// Regression tests: JSON booleans in tool schemas must survive encoding as
/// booleans (not `0`/`1`), top-level and nested.
final class ToolBooleanEncodingTests: XCTestCase {
    private let toolJSON = """
    {
        "name": "set_light",
        "description": "Toggle a light",
        "parameters": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
                "on": {"type": "boolean", "default": true},
                "room": {"type": "object", "additionalProperties": false, "properties": {}}
            },
            "flags": [true, false, 1, 0]
        },
        "metadata": {"a2ui": true, "hidden": false}
    }
    """

    private func encodeSorted(_ value: some Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }

    func testRoundTripPreservesBooleansAndNumbers() throws {
        let tool = try JSONDecoder().decode(Tool.self, from: Data(toolJSON.utf8))
        let output = try encodeSorted(tool)

        XCTAssertEqual(
            output,
            #"{"description":"Toggle a light","metadata":{"a2ui":true,"hidden":false},"name":"set_light","#
                + #""parameters":{"additionalProperties":false,"flags":[true,false,1,0],"#
                + #""properties":{"on":{"default":true,"type":"boolean"},"#
                + #""room":{"additionalProperties":false,"properties":{},"type":"object"}},"type":"object"}}"#
        )
    }

    func testTopLevelFalseIsEncodedAsFalse() throws {
        let json = #"{"name":"t","description":"d","parameters":{"type":"object","additionalProperties":false,"properties":{}}}"#
        let tool = try JSONDecoder().decode(Tool.self, from: Data(json.utf8))
        let output = try encodeSorted(tool)

        XCTAssertTrue(output.contains(#""additionalProperties":false"#), output)
        XCTAssertFalse(output.contains(#""additionalProperties":0"#), output)
    }

    func testEncodeDecodeEncodeIsStable() throws {
        let first = try JSONDecoder().decode(Tool.self, from: Data(toolJSON.utf8))
        let firstOutput = try encodeSorted(first)
        let second = try JSONDecoder().decode(Tool.self, from: Data(firstOutput.utf8))

        XCTAssertEqual(try encodeSorted(second), firstOutput)
        XCTAssertEqual(first, second)
    }
}
