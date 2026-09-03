//
//  APIError.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidResponse
    case http(statusCode: Int, message: String?)
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .http(let statusCode, let message):
            if let message, !message.isEmpty {
                return message
            }
            return "The server returned status code \(statusCode)."
        case .decoding:
            return "The server response could not be read."
        case .network(let error):
            return error.localizedDescription
        }
    }
}
