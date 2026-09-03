//
//  APIRequest.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

enum APIMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

protocol NetworkRequestConvertible {
    var method: APIMethod { get }
    var path: String { get }
}
