//
//  ProfileService.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

enum UserEndpoint: NetworkRequestConvertible {
    case profile(id: Int)
    case posts(userId: Int)

    var method: APIMethod { .get }

    var path: String {
        switch self {
        case let .profile(id):
            return "/users/\(id)"
        case let .posts(userId):
            return "/users/\(userId)/posts"
        }
    }
}

struct ProfileService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func user(id: Int) async throws -> User {
        try await client.request(UserEndpoint.profile(id: id))
    }

    func posts(userId: Int) async throws -> [Post] {
        try await client.request(UserEndpoint.posts(userId: userId))
    }
}
