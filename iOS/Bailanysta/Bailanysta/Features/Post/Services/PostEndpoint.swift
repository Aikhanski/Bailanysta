//
//  PostEndpoint.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

enum PostEndpoint: NetworkRequestConvertible {
    case fetch
    case create
    case update(id: Int)
    case delete(id: Int)
    case like(id: Int)
    case unlike(id: Int)
    case comments(postId: Int)
    case createComment(postId: Int)

    var method: APIMethod {
        switch self {
        case .fetch, .comments:
            return .get
        case .create, .like, .createComment:
            return .post
        case .update:
            return .patch
        case .delete, .unlike:
            return .delete
        }
    }

    var path: String {
        switch self {
        case .fetch, .create:
            return "/posts"
        case let .update(id), let .delete(id):
            return "/posts/\(id)"
        case let .like(id), let .unlike(id):
            return "/posts/\(id)/like"
        case let .comments(postId), let .createComment(postId):
            return "/posts/\(postId)/comments"
        }
    }
}
