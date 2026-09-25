// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

import XCTest
@testable import AGUICore

/// Regression tests: `JSONSerialization` yields `NSNumber` for both booleans and
/// numbers, and `NSNumber(1) as? Bool` / `NSNumber(false) as? Int` both succeed.
/// These tests guard every place that re-encodes such values.
final class JSONNumberBooleanFidelityTests: XCTestCase, AGUIEventDecoderTestHelpers {
    private func encodeSorted(_ value: some Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }

    // MARK: - RunAgentInput

    func testRunAgentInputPreservesNumbersAndBooleansInState() throws {
        let input = RunAgentInput(
            threadId: "t",
            runId: "r",
            state: Data(#"{"count":1,"zero":0,"on":true,"off":false,"nested":{"n":[1,0,true,false]}}"#.utf8)
        )
        let output = try encodeSorted(input)

        XCTAssertTrue(
            output.contains(#""state":{"count":1,"nested":{"n":[1,0,true,false]},"off":false,"on":true,"zero":0}"#),
            output
        )
    }

    func testRunAgentInputPreservesNumbersAndBooleansInForwardedProps() throws {
        let input = RunAgentInput(
            threadId: "t",
            runId: "r",
            forwardedProps: Data(#"{"one":1,"yes":true}"#.utf8)
        )
        let output = try encodeSorted(input)

        XCTAssertTrue(output.contains(#""forwardedProps":{"one":1,"yes":true}"#), output)
    }

    // MARK: - Event DTOs with primitive payloads

    func testStateSnapshotPrimitiveNumberIsNotDecodedAsBoolean() throws {
        let event = try makeStrictDecoder().decode(Data(#"{"type":"STATE_SNAPSHOT","snapshot":1}"#.utf8))
        let snapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        XCTAssertEqual(String(decoding: snapshot.snapshot, as: UTF8.self), "1")
    }

    func testStateSnapshotPrimitiveBooleanStaysBoolean() throws {
        let event = try makeStrictDecoder().decode(Data(#"{"type":"STATE_SNAPSHOT","snapshot":false}"#.utf8))
        let snapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        XCTAssertEqual(String(decoding: snapshot.snapshot, as: UTF8.self), "false")
    }

    func testCustomEventPrimitiveZeroIsNotDecodedAsBoolean() throws {
        let event = try makeStrictDecoder().decode(Data(#"{"type":"CUSTOM","name":"n","value":0}"#.utf8))
        let custom = try XCTUnwrap(event as? CustomEvent)
        XCTAssertEqual(String(decoding: custom.value, as: UTF8.self), "0")
    }

    func testRawEventPrimitiveOneIsNotDecodedAsBoolean() throws {
        let event = try makeStrictDecoder().decode(Data(#"{"type":"RAW","event":1}"#.utf8))
        let raw = try XCTUnwrap(event as? RawEvent)
        XCTAssertEqual(String(decoding: raw.data, as: UTF8.self), "1")
    }

    func testStateSnapshotObjectPreservesNumbersAndBooleans() throws {
        let json = #"{"type":"STATE_SNAPSHOT","snapshot":{"a":1,"b":false,"c":[0,true]}}"#
        let event = try makeStrictDecoder().decode(Data(json.utf8))
        let snapshot = try XCTUnwrap(event as? StateSnapshotEvent)
        let reparsed = try JSONDecoder().decode(JSONValue.self, from: snapshot.snapshot)
        XCTAssertEqual(reparsed, ["a": 1, "b": false, "c": [0, true]])
    }

    func testStateDeltaPreservesNumbersAndBooleans() throws {
        let json = #"{"type":"STATE_DELTA","delta":[{"op":"add","path":"/a","value":false},{"op":"add","path":"/b","value":1}]}"#
        let event = try makeStrictDecoder().decode(Data(json.utf8))
        let delta = try XCTUnwrap(event as? StateDeltaEvent)
        let reparsed = try JSONDecoder().decode(JSONValue.self, from: delta.delta)
        XCTAssertEqual(reparsed, [
            ["op": "add", "path": "/a", "value": false],
            ["op": "add", "path": "/b", "value": 1],
        ])
    }
}
