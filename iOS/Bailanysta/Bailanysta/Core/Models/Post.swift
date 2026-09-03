//
//  Post.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import Foundation

struct Post: Decodable, Identifiable {
    let id: Int
    let authorId: Int
    let text: String
    let createdAt: Date
    let updatedAt: Date
    let author: User
    var likeCount: Int
    var commentCount: Int
    var isLiked: Bool

    var isOwnedByCurrentUser: Bool {
        authorId == APIConfig.currentUserID
    }

    func withLikeToggled() -> Post {
        var copy = self
        copy.isLiked.toggle()
        copy.likeCount += copy.isLiked ? 1 : -1
        copy.likeCount = max(0, copy.likeCount)
        return copy
    }

    func withCommentCount(_ count: Int) -> Post {
        var copy = self
        copy.commentCount = count
        return copy
    }
}

struct NewPost: Encodable {
    let text: String
}

struct GeneratePostRequest: Encodable {
    let prompt: String
}

struct GeneratedPost: Decodable {
    let text: String
}

extension Array where Element == Post {
    mutating func replace(_ post: Post) {
        guard let index = firstIndex(where: { $0.id == post.id }) else { return }
        self[index] = post
    }
}
