//
//  APIClient.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import Foundation

struct APIClient {
    var baseURL: URL
    var session: URLSession
    var headers: [String: String]
    private let logger = APILogger()

    init(
        baseURL: URL = APIConfig.baseURL,
        session: URLSession = .shared,
        headers: [String: String] = ["X-User-Id": String(APIConfig.currentUserID)]
    ) {
        self.baseURL = baseURL
        self.session = session
        self.headers = headers
    }

    func request<T: Decodable>(
        _ endpoint: some NetworkRequestConvertible,
        query: [String: String] = [:]
    ) async throws -> T {
        let data = try await perform(endpoint, query: query, bodyData: nil)
        return try decode(data)
    }

    func request<T: Decodable, Body: Encodable>(
        _ endpoint: some NetworkRequestConvertible,
        body: Body
    ) async throws -> T {
        let data = try await perform(
            endpoint,
            query: [:],
            bodyData: try Self.encoder.encode(body)
        )
        return try decode(data)
    }

    func request(_ endpoint: some NetworkRequestConvertible) async throws {
        _ = try await perform(endpoint, query: [:], bodyData: nil)
    }

    private func perform(
        _ endpoint: some NetworkRequestConvertible,
        query: [String: String],
        bodyData: Data?
    ) async throws -> Data {
        var urlRequest = URLRequest(url: makeURL(path: endpoint.path, query: query))
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        for (field, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }

        if let bodyData {
            urlRequest.httpBody = bodyData
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        logger.logRequest(urlRequest)
        let started = ContinuousClock.now

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            logger.logNetworkError(urlRequest, duration: ContinuousClock.now - started, error: error)
            throw APIError.network(error)
        }

        let duration = ContinuousClock.now - started

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.logInvalidResponse(urlRequest, duration: duration)
            throw APIError.invalidResponse
        }

        let succeeded = (200..<300).contains(httpResponse.statusCode)
        let errorMessage = succeeded ? nil : Self.message(from: data)
        logger.logResponse(
            urlRequest,
            response: httpResponse,
            data: data,
            duration: duration,
            succeeded: succeeded,
            errorMessage: errorMessage
        )

        guard succeeded else {
            throw APIError.http(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return data
    }

    private func makeURL(path: String, query: [String: String] = [:]) -> URL {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = baseURL.appending(path: trimmed)
        guard !query.isEmpty, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url ?? url
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            logger.logDecodingError(type: T.self, error: error)
            throw APIError.decoding(error)
        }
    }

    private static func message(from data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let detail = object["detail"] as? String
        else {
            return String(data: data, encoding: .utf8)
        }
        return detail
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = fractionalISO8601.date(from: value) ?? iso8601.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date: \(value)"
            )
        }
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fractionalISO8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
