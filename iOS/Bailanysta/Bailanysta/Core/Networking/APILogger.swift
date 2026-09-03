//
//  APILogger.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import Foundation
import os

struct APILogger {
    private let logger = Logger(subsystem: "khassenovv.Bailanysta", category: "API")

    private var isEnabled: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    func logRequest(_ request: URLRequest) {
        guard isEnabled else { return }
        write(
            """
            ➡️ API REQUEST
            \(line(for: request))

            Headers:
            \(formattedHeaders(request.allHTTPHeaderFields))

            Body:
            \(prettyBody(request.httpBody))
            """
        )
    }

    func logResponse(
        _ request: URLRequest,
        response: HTTPURLResponse,
        data: Data,
        duration: Duration,
        succeeded: Bool,
        errorMessage: String? = nil
    ) {
        guard isEnabled else { return }
        let result: String
        if succeeded {
            result = "✅ SUCCESS"
        } else {
            result = """
            ❌ FAILURE
            APIError: HTTP \(response.statusCode)
            Message: \(errorMessage ?? "The server returned status code \(response.statusCode).")
            """
        }
        write(
            """
            ⬅️ API RESPONSE
            \(line(for: request))
            Status: \(response.statusCode)
            Duration: \(milliseconds(duration)) ms

            Headers:
            \(formattedHeaders(response.allHeaderFields))

            Body:
            \(prettyBody(data))

            \(result)
            """
        )
    }

    func logNetworkError(_ request: URLRequest, duration: Duration, error: Error) {
        guard isEnabled else { return }
        write(
            """
            ❌ NETWORK ERROR
            \(line(for: request))
            Duration: \(milliseconds(duration)) ms

            Error:
            \(error.localizedDescription)
            """
        )
    }

    func logInvalidResponse(_ request: URLRequest, duration: Duration) {
        guard isEnabled else { return }
        write(
            """
            ⬅️ API RESPONSE
            \(line(for: request))
            Duration: \(milliseconds(duration)) ms

            ❌ FAILURE
            APIError: Invalid response
            Message: The server returned an invalid response.
            """
        )
    }

    func logDecodingError(type: Any.Type, error: Error) {
        guard isEnabled else { return }
        write(
            """
            ❌ DECODING ERROR
            Could not decode \(type).
            \(String(describing: error))
            """
        )
    }

    private func write(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    private func line(for request: URLRequest) -> String {
        "\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "(unknown URL)")"
    }

    private func formattedHeaders(_ fields: [AnyHashable: Any]?) -> String {
        guard let fields, !fields.isEmpty else { return "(none)" }
        var mapped: [String: String] = [:]
        for (key, value) in fields {
            mapped["\(key)"] = "\(value)"
        }
        return formattedHeaders(mapped)
    }

    private func formattedHeaders(_ fields: [String: String]?) -> String {
        guard let fields, !fields.isEmpty else { return "(none)" }
        return fields.keys
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            .map { "\($0): \(masked(header: $0, value: fields[$0] ?? ""))" }
            .joined(separator: "\n")
    }

    private func masked(header: String, value: String) -> String {
        let name = header.lowercased()
        switch name {
        case "authorization":
            return value.lowercased().hasPrefix("bearer ") ? "Bearer ***" : "***"
        case "cookie", "set-cookie", "x-api-key", "api-key", "x-auth-token":
            return "***"
        default:
            return value
        }
    }

    private func prettyBody(_ data: Data?) -> String {
        guard let data, !data.isEmpty else { return "(empty)" }
        if let object = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
           ),
           let text = String(data: pretty, encoding: .utf8)
        {
            return text
        }
        return String(data: data, encoding: .utf8) ?? "(\(data.count) bytes)"
    }

    private func milliseconds(_ duration: Duration) -> Int {
        let parts = duration.components
        return Int(parts.seconds * 1000 + parts.attoseconds / 1_000_000_000_000_000)
    }
}
