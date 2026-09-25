// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

import Foundation

/// Defines a tool or function that agents can invoke.
///
/// Tools represent capabilities that agents can use to:
/// - Request specific information from external systems
/// - Perform actions in external systems
/// - Ask for human input or confirmation
/// - Access specialized capabilities beyond the agent's core knowledge
///
public struct Tool: Sendable, Codable, Hashable {
    /// The unique identifier for this tool.
    ///
    /// Tool names should be descriptive and follow snake_case convention
    /// (e.g., "get_weather", "send_email", "execute_query"). The name is
    /// used by agents to identify and invoke the tool.
    public let name: String

    /// Human-readable description of what this tool does.
    ///
    /// The description helps agents understand:
    /// - What the tool can do
    /// - When to use the tool
    /// - What results to expect
    ///
    /// Good descriptions are clear, concise, and action-oriented:
    /// - ✓ "Get the current weather in a given location"
    /// - ✓ "Send an email to a specified recipient"
    /// - ✗ "Weather" (too vague)
    /// - ✗ "This tool can be used to retrieve weather data..." (too verbose)
    public let description: String

    /// JSON Schema defining the tool's parameters.
    ///
    /// This schema describes the structure and constraints of the arguments
    /// the tool expects. It should be a valid JSON Schema (Draft 7 or later).
    ///
    /// Common schema patterns:
    /// - Empty parameters: `[:]`
    /// - Simple parameters: Object type with properties and required fields
    /// - Complex parameters: Nested objects, arrays, enums, validation rules
    ///
    /// ```swift
    /// let tool = Tool(
    ///     name: "get_weather",
    ///     description: "Get the current weather in a given location",
    ///     parameters: [
    ///         "type": "object",
    ///         "properties": ["location": ["type": "string"]],
    ///         "required": ["location"],
    ///         "additionalProperties": false,
    ///     ]
    /// )
    /// ```
    public let parameters: JSONValue

    /// Optional metadata as arbitrary JSON.
    ///
    /// Used by A2UI schema extensions and tool registry annotations.
    /// Corresponds to the `metadata` field in the AG-UI protocol spec.
    public let metadata: JSONValue?

    /// Creates a new tool definition.
    ///
    /// - Parameters:
    ///   - name: Unique identifier for the tool
    ///   - description: Human-readable explanation of the tool's purpose
    ///   - parameters: JSON Schema defining the tool's parameters
    ///   - metadata: Optional metadata
    ///
    /// - Note: The parameters should contain valid JSON Schema. Invalid schema
    ///   may cause validation errors during tool execution.
    public init(
        name: String,
        description: String,
        parameters: JSONValue,
        metadata: JSONValue? = nil
    ) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.metadata = metadata
    }

    /// Creates a new tool definition from raw JSON bytes.
    ///
    /// - Parameters:
    ///   - name: Unique identifier for the tool
    ///   - description: Human-readable explanation of the tool's purpose
    ///   - parameters: JSON Schema as UTF-8 JSON bytes
    ///   - metadata: Optional metadata as UTF-8 JSON bytes
    ///
    /// - Note: Bytes that are not valid JSON are replaced with an empty schema (`{}`)
    ///   for `parameters` and `nil` for `metadata`. Use the `JSONValue` initializer,
    ///   or decode with `JSONDecoder` yourself, to handle invalid input explicitly.
    @available(*, deprecated, message: "Use init(name:description:parameters:metadata:) with JSONValue")
    public init(
        name: String,
        description: String,
        parameters: Data,
        metadata: Data? = nil
    ) {
        let decoder = JSONDecoder()
        self.init(
            name: name,
            description: description,
            parameters: (try? decoder.decode(JSONValue.self, from: parameters)) ?? [:],
            metadata: metadata.flatMap { try? decoder.decode(JSONValue.self, from: $0) }
        )
    }
}
