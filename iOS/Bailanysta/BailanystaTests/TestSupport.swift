//
//  TestSupport.swift
//  BailanystaTests
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import Foundation
@testable import Bailanysta

enum TestError: Error, LocalizedError {
    case failed

    var errorDescription: String? {
        "Request failed"
    }
}

extension User {
    static func sample(
        id: Int = 1,
        username: String = "aikhan",
        displayName: String = "Aikhan"
    ) -> User {
        User(
            id: id,
            username: username,
            displayName: displayName,
            bio: "",
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }
}

extension Post {
    static func sample(
        id: Int = 1,
        authorId: Int = 1,
        text: String = "Hello",
        likeCount: Int = 0,
        commentCount: Int = 0,
        isLiked: Bool = false
    ) -> Post {
        Post(
            id: id,
            authorId: authorId,
            text: text,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            author: .sample(id: authorId),
            likeCount: likeCount,
            commentCount: commentCount,
            isLiked: isLiked
        )
    }
}

struct StubPostService: PostService {
    var fetchHandler: () async throws -> [Post] = { [] }
    var createHandler: (String) async throws -> Post = { _ in throw TestError.failed }
    var updateHandler: (Int, String) async throws -> Post = { _, _ in throw TestError.failed }
    var deleteHandler: (Int) async throws -> Void = { _ in }
    var likeHandler: (Int) async throws -> Post = { _ in throw TestError.failed }
    var unlikeHandler: (Int) async throws -> Post = { _ in throw TestError.failed }
    var commentsHandler: (Int) async throws -> [Comment] = { _ in [] }
    var createCommentHandler: (Int, String) async throws -> Comment = { _, _ in throw TestError.failed }

    func fetch() async throws -> [Post] {
        try await fetchHandler()
    }

    func create(text: String) async throws -> Post {
        try await createHandler(text)
    }

    func update(id: Int, text: String) async throws -> Post {
        try await updateHandler(id, text)
    }

    func delete(id: Int) async throws {
        try await deleteHandler(id)
    }

    func like(id: Int) async throws -> Post {
        try await likeHandler(id)
    }

    func unlike(id: Int) async throws -> Post {
        try await unlikeHandler(id)
    }

    func comments(postId: Int) async throws -> [Comment] {
        try await commentsHandler(postId)
    }

    func createComment(postId: Int, text: String) async throws -> Comment {
        try await createCommentHandler(postId, text)
    }
}

struct StubAIService: AIService {
    var generateHandler: (String) async throws -> GeneratedPost = { _ in throw TestError.failed }

    func generatePost(prompt: String) async throws -> GeneratedPost {
        try await generateHandler(prompt)
    }
}
