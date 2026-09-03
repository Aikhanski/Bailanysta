//
//  PostService.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

protocol PostService {
    func fetch() async throws -> [Post]
    func create(text: String) async throws -> Post
    func update(id: Int, text: String) async throws -> Post
    func delete(id: Int) async throws
    func like(id: Int) async throws -> Post
    func unlike(id: Int) async throws -> Post
    func comments(postId: Int) async throws -> [Comment]
    func createComment(postId: Int, text: String) async throws -> Comment
}

struct PostServiceImpl: PostService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetch() async throws -> [Post] {
        try await client.request(PostEndpoint.fetch)
    }

    func create(text: String) async throws -> Post {
        try await client.request(PostEndpoint.create, body: NewPost(text: text))
    }

    func update(id: Int, text: String) async throws -> Post {
        try await client.request(PostEndpoint.update(id: id), body: NewPost(text: text))
    }

    func delete(id: Int) async throws {
        try await client.request(PostEndpoint.delete(id: id))
    }

    func like(id: Int) async throws -> Post {
        try await client.request(PostEndpoint.like(id: id))
    }

    func unlike(id: Int) async throws -> Post {
        try await client.request(PostEndpoint.unlike(id: id))
    }

    func comments(postId: Int) async throws -> [Comment] {
        try await client.request(PostEndpoint.comments(postId: postId))
    }

    func createComment(postId: Int, text: String) async throws -> Comment {
        try await client.request(
            PostEndpoint.createComment(postId: postId),
            body: NewPost(text: text)
        )
    }
}
