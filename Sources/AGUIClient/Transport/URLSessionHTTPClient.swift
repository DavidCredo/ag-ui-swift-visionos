// Copyright (c) 2025 Perfect Aduh. MIT License. See LICENSE for details.

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// URLSession-based HTTP client implementation.
///
/// `URLSessionHTTPClient` is the default HTTP client that uses Apple's
/// URLSession for networking. It supports full URLSession configuration
/// and can be injected with a custom session for testing.
///
public actor URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    /// Creates a new URLSession HTTP client with the specified session.
    ///
    /// This is the primary initializer that accepts a URLSession instance,
    /// enabling full control over session configuration and injection of
    /// mock sessions for testing.
    ///
    /// - Parameter session: The URLSession to use for requests
    ///
    /// ## Example
    ///
    /// ```swift
    /// let config = URLSessionConfiguration.default
    /// config.timeoutIntervalForRequest = 60
    /// let session = URLSession(configuration: config)
    /// let client = URLSessionHTTPClient(session: session)
    /// ```
    public init(session: URLSession) {
        self.session = session
    }

    /// Creates a new URLSession HTTP client with the specified configuration.
    ///
    /// This factory method provides a convenient way to create a client
    /// with custom URLSession configuration.
    ///
    /// - Parameter configuration: URLSession configuration (default: .default)
    /// - Returns: A new URLSession HTTP client
    ///
    /// ## Example
    ///
    /// ```swift
    /// let config = URLSessionConfiguration.ephemeral
    /// config.timeoutIntervalForRequest = 30
    /// let client = URLSessionHTTPClient.create(configuration: config)
    /// ```
    public static func create(
        configuration: URLSessionConfiguration = .default
    ) -> URLSessionHTTPClient {
        let session = URLSession(configuration: configuration)
        return URLSessionHTTPClient(session: session)
    }

    /// Executes an HTTP request using URLSession.
    ///
    /// - Parameter request: The URL request to execute
    /// - Returns: An HTTP response containing streaming bytes and metadata
    /// - Throws: `ClientError` if the request fails
    ///
    /// ## Error Mapping
    ///
    /// URLErrors are mapped to ClientError:
    /// - `.timedOut` → `.timeout`
    /// - `.cancelled` → `.cancelled`
    /// - Other errors → `.networkError`
    public func execute(_ request: URLRequest) async throws -> HTTPResponse {
        #if canImport(FoundationNetworking)
        // swift-corelibs-foundation has no `URLSession.bytes(for:)`, so on Linux
        // the body is buffered in full before it is handed out as a stream.
        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw mapURLError(error)
        } catch {
            throw ClientError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }

        let stream = AsyncThrowingStream<UInt8, Error> { continuation in
            for byte in data {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        return HTTPResponse(bytes: stream, httpResponse: httpResponse)
        #else
        let (bytes, response): (URLSession.AsyncBytes, URLResponse)

        do {
            (bytes, response) = try await session.bytes(for: request)
        } catch let error as URLError {
            throw mapURLError(error)
        } catch {
            throw ClientError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }

        // Bridge URLSession.AsyncBytes → AsyncThrowingStream<UInt8, Error> so that
        // HTTPResponse is decoupled from URLSession and can be mocked in tests.
        let stream = AsyncThrowingStream<UInt8, Error> { continuation in
            let task = Task {
                do {
                    for try await byte in bytes {
                        continuation.yield(byte)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel(); bytes.task.cancel() }
        }

        return HTTPResponse(bytes: stream, httpResponse: httpResponse)
        #endif
    }

    /// Maps URLError to ClientError.
    private func mapURLError(_ error: URLError) -> ClientError {
        switch error.code {
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        default:
            return .networkError(error)
        }
    }
}
