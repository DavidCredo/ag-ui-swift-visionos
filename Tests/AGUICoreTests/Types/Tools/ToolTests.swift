// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

import XCTest
@testable import AGUICore

/// Tests for the Tool type
final class ToolTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitWithBasicSchema() throws {
        let schema: JSONValue = [
            "type": "object",
            "properties": [
                "location": ["type": "string"]
            ],
            "required": ["location"]
        ]

        let tool = Tool(
            name: "get_weather",
            description: "Get the current weather for a location",
            parameters: schema
        )

        XCTAssertEqual(tool.name, "get_weather")
        XCTAssertEqual(tool.description, "Get the current weather for a location")
        XCTAssertEqual(tool.parameters, schema)
    }

    func testInitWithEmptySchema() {
        let emptySchema: JSONValue = [:]

        let tool = Tool(
            name: "ping",
            description: "Simple ping tool with no parameters",
            parameters: emptySchema
        )

        XCTAssertEqual(tool.name, "ping")
        XCTAssertEqual(tool.parameters, emptySchema)
    }

    func testInitWithComplexSchema() throws {
        let complexSchema: JSONValue = [
            "type": "object",
            "properties": [
                "query": [
                    "type": "string",
                    "description": "The SQL query to execute"
                ],
                "database": [
                    "type": "string",
                    "enum": ["production", "staging", "development"]
                ],
                "limit": [
                    "type": "integer",
                    "minimum": 1,
                    "maximum": 1000,
                    "default": 100
                ]
            ],
            "required": ["query", "database"]
        ]

        let tool = Tool(
            name: "execute_sql",
            description: "Execute a SQL query on a specified database",
            parameters: complexSchema
        )

        XCTAssertEqual(tool.name, "execute_sql")
        XCTAssertTrue(tool.description.contains("SQL"))
    }

    // MARK: - Deprecated Data Initializer Tests

    @available(*, deprecated)
    func testDeprecatedDataInitDecodesIntoJSONValue() {
        let tool = Tool(
            name: "legacy",
            description: "Legacy",
            parameters: Data(#"{"type":"object","additionalProperties":false,"properties":{}}"#.utf8),
            metadata: Data(#"{"v":1}"#.utf8)
        )

        XCTAssertEqual(tool.parameters, ["type": "object", "additionalProperties": false, "properties": [:]])
        XCTAssertEqual(tool.metadata, ["v": 1])
    }

    @available(*, deprecated)
    func testDeprecatedDataInitWithInvalidJSONFallsBack() {
        let tool = Tool(
            name: "legacy",
            description: "Legacy",
            parameters: Data("not json".utf8),
            metadata: Data("not json".utf8)
        )

        XCTAssertEqual(tool.parameters, [:])
        XCTAssertNil(tool.metadata)
    }

    // MARK: - Encoding Tests

    func testEncodingBasic() throws {
        let tool = Tool(
            name: "test_tool",
            description: "A test tool",
            parameters: ["type": "object"]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(tool)
        let json = String(data: encoded, encoding: .utf8)

        XCTAssertEqual(json, #"{"description":"A test tool","name":"test_tool","parameters":{"type":"object"}}"#)
    }

    func testEncodedStructure() throws {
        let tool = Tool(
            name: "sample",
            description: "Sample tool",
            parameters: ["type": "object"]
        )

        let encoded = try JSONEncoder().encode(tool)
        let json = try JSONDecoder().decode(JSONValue.self, from: encoded)

        XCTAssertEqual(json, [
            "name": "sample",
            "description": "Sample tool",
            "parameters": ["type": "object"]
        ])
    }

    // MARK: - Decoding Tests

    func testDecodingBasic() throws {
        let json = """
        {
            "name": "send_email",
            "description": "Send an email to a recipient",
            "parameters": {
                "type": "object",
                "properties": {
                    "to": {"type": "string"},
                    "subject": {"type": "string"}
                }
            }
        }
        """

        let decoder = JSONDecoder()
        let tool = try decoder.decode(Tool.self, from: Data(json.utf8))

        XCTAssertEqual(tool.name, "send_email")
        XCTAssertEqual(tool.description, "Send an email to a recipient")
        XCTAssertEqual(tool.parameters, [
            "type": "object",
            "properties": [
                "to": ["type": "string"],
                "subject": ["type": "string"]
            ]
        ])
    }

    func testDecodingWithEmptyParameters() throws {
        let json = """
        {
            "name": "no_params",
            "description": "Tool with no parameters",
            "parameters": {}
        }
        """

        let decoder = JSONDecoder()
        let tool = try decoder.decode(Tool.self, from: Data(json.utf8))

        XCTAssertEqual(tool.name, "no_params")
        XCTAssertEqual(tool.parameters, [:])
    }

    func testDecodingFailsWithoutName() {
        let json = """
        {
            "description": "Missing name",
            "parameters": {}
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(Tool.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecodingFailsWithoutDescription() {
        let json = """
        {
            "name": "test",
            "parameters": {}
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(Tool.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecodingFailsWithoutParameters() {
        let json = """
        {
            "name": "test",
            "description": "Test tool"
        }
        """

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(Tool.self, from: Data(json.utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Round-trip Tests

    func testRoundTrip() throws {
        let original = Tool(
            name: "search",
            description: "Search for information",
            parameters: [
                "type": "object",
                "properties": [
                    "query": ["type": "string"]
                ]
            ]
        )

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Tool.self, from: encoded)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Equatable Tests

    func testEquality() {
        let schema1: JSONValue = ["type": "object"]
        let schema2: JSONValue = ["type": "object"]
        let schema3: JSONValue = ["type": "string"]

        let tool1 = Tool(name: "tool", description: "desc", parameters: schema1)
        let tool2 = Tool(name: "tool", description: "desc", parameters: schema2)
        let tool3 = Tool(name: "other", description: "desc", parameters: schema1)
        let tool4 = Tool(name: "tool", description: "different", parameters: schema1)
        let tool5 = Tool(name: "tool", description: "desc", parameters: schema3)

        XCTAssertEqual(tool1, tool2)
        XCTAssertNotEqual(tool1, tool3)
        XCTAssertNotEqual(tool1, tool4)
        XCTAssertNotEqual(tool1, tool5)
    }

    // MARK: - Hashable Tests

    func testHashable() {
        let tool1 = Tool(name: "tool1", description: "First", parameters: [:])
        let tool2 = Tool(name: "tool2", description: "Second", parameters: [:])

        let set: Set<Tool> = [tool1, tool2]
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(tool1))
        XCTAssertTrue(set.contains(tool2))
    }

    // MARK: - Sendable Tests

    func testSendableConformance() {
        let tool = Tool(name: "test", description: "Test", parameters: [:])

        Task {
            let capturedTool = tool
            XCTAssertEqual(capturedTool.name, "test")
        }
    }

    // MARK: - Parameter Schema Tests

    func testParametersAsValidJSONSchema() throws {
        let tool = Tool(
            name: "create_user",
            description: "Create a new user",
            parameters: [
                "type": "object",
                "properties": [
                    "name": ["type": "string"],
                    "age": ["type": "integer"]
                ],
                "required": ["name"]
            ]
        )

        guard case .object(let schema) = tool.parameters else {
            return XCTFail("Expected an object schema")
        }
        XCTAssertEqual(schema["type"], "object")
        XCTAssertNotNil(schema["properties"])
    }

    // MARK: - Real-world Usage Tests

    func testWeatherTool() throws {
        let weatherTool = Tool(
            name: "get_current_weather",
            description: "Get the current weather in a given location",
            parameters: [
                "type": "object",
                "properties": [
                    "location": [
                        "type": "string",
                        "description": "City and state, e.g., San Francisco, CA"
                    ],
                    "unit": [
                        "type": "string",
                        "enum": ["celsius", "fahrenheit"],
                        "default": "fahrenheit"
                    ]
                ],
                "required": ["location"]
            ]
        )

        XCTAssertEqual(weatherTool.name, "get_current_weather")
        XCTAssertTrue(weatherTool.description.contains("weather"))

        guard case .object(let schema) = weatherTool.parameters,
              case .object(let properties)? = schema["properties"] else {
            return XCTFail("Expected object schema with properties")
        }
        XCTAssertNotNil(properties["location"])
    }

    func testDatabaseTool() throws {
        let dbTool = Tool(
            name: "execute_sql_query",
            description: "Execute a SQL query on the specified database",
            parameters: [
                "type": "object",
                "properties": [
                    "query": [
                        "type": "string",
                        "description": "SQL query to execute"
                    ],
                    "database": [
                        "type": "string",
                        "description": "Target database name"
                    ]
                ],
                "required": ["query", "database"]
            ]
        )

        XCTAssertEqual(dbTool.name, "execute_sql_query")
    }

    func testToolArray() {
        let tools: [Tool] = [
            Tool(name: "tool1", description: "First tool", parameters: [:]),
            Tool(name: "tool2", description: "Second tool", parameters: [:]),
            Tool(name: "tool3", description: "Third tool", parameters: [:])
        ]

        XCTAssertEqual(tools.count, 3)
        XCTAssertEqual(tools[0].name, "tool1")
        XCTAssertEqual(tools[1].name, "tool2")
        XCTAssertEqual(tools[2].name, "tool3")
    }

    func testNoParametersTool() {
        let pingTool = Tool(
            name: "ping",
            description: "Check if the service is alive",
            parameters: [:]
        )

        XCTAssertEqual(pingTool.name, "ping")
        XCTAssertEqual(pingTool.parameters, [:])
    }

    // MARK: - metadata Tests

    func test_toolWithMetadata_init() {
        let metadata: JSONValue = ["category": "weather"]

        let tool = Tool(
            name: "get_weather",
            description: "Get weather",
            parameters: [:],
            metadata: metadata
        )

        XCTAssertEqual(tool.metadata, metadata)
    }

    func test_toolWithoutMetadata_metadataIsNil() {
        let tool = Tool(name: "ping", description: "Ping", parameters: [:])
        XCTAssertNil(tool.metadata)
    }

    func test_encodingWithMetadata_includesMetadataKey() throws {
        let tool = Tool(name: "search", description: "Search", parameters: [:], metadata: ["category": "search"])

        let encoded = try JSONEncoder().encode(tool)
        let json = try JSONDecoder().decode([String: JSONValue].self, from: encoded)

        XCTAssertEqual(json["metadata"], ["category": "search"], "Encoded JSON must contain 'metadata' key")
    }

    func test_encodingWithoutMetadata_omitsMetadataKey() throws {
        let tool = Tool(name: "ping", description: "Ping", parameters: [:])

        let encoded = try JSONEncoder().encode(tool)
        let json = try JSONDecoder().decode([String: JSONValue].self, from: encoded)

        XCTAssertNil(json["metadata"], "Encoded JSON must NOT contain 'metadata' when nil")
    }

    func test_decodingWithMetadata_populatesMetadata() throws {
        let json = """
        {
            "name": "search",
            "description": "Search tool",
            "parameters": {},
            "metadata": {"category": "search", "version": 2}
        }
        """

        let tool = try JSONDecoder().decode(Tool.self, from: Data(json.utf8))

        XCTAssertEqual(tool.metadata, ["category": "search", "version": 2])
    }

    func test_decodingWithNullMetadata_metadataIsNil() throws {
        let json = #"{"name":"t","description":"d","parameters":{},"metadata":null}"#

        let tool = try JSONDecoder().decode(Tool.self, from: Data(json.utf8))
        XCTAssertNil(tool.metadata)
    }

    func test_decodingWithoutMetadata_metadataIsNil() throws {
        // Existing format without metadata — must remain backward compatible
        let json = """
        {
            "name": "legacy_tool",
            "description": "Legacy tool",
            "parameters": {}
        }
        """

        let tool = try JSONDecoder().decode(Tool.self, from: Data(json.utf8))
        XCTAssertNil(tool.metadata)
    }

    func test_roundTripWithMetadata() throws {
        let original = Tool(
            name: "get_weather",
            description: "Weather",
            parameters: [:],
            metadata: ["category": "weather", "priority": 1]
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Tool.self, from: encoded)

        XCTAssertEqual(decoded.metadata, original.metadata)
    }

    func test_equalityWithDifferentMetadata_notEqual() {
        let tool1 = Tool(name: "t", description: "d", parameters: [:], metadata: ["v": 1])
        let tool2 = Tool(name: "t", description: "d", parameters: [:], metadata: ["v": 2])

        XCTAssertNotEqual(tool1, tool2)
    }
}
