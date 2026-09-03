//
//  SearchService.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

enum SearchEndpoint: NetworkRequestConvertible {
    case search

    var method: APIMethod { .get }
    var path: String { "/search" }
}

struct SearchService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func posts(query: String) async throws -> [Post] {
        try await client.request(SearchEndpoint.search, query: ["q": query])
    }
}
