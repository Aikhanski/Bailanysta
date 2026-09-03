//
//  CommentsViewModel.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import Foundation
import Observation

@Observable
final class CommentsViewModel {
    var state: Loadable<[Comment]> = .loading
    var draft = ""
    var isSending = false
    var sendError: String?

    private let postID: Int
    private let postService: any PostService
    private let maxLength = 500

    init(postID: Int, postService: any PostService = AppComposition.postService) {
        self.postID = postID
        self.postService = postService
    }

    var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSend: Bool {
        let count = trimmedDraft.count
        return count > 0 && count <= maxLength && !isSending
    }

    func load() async {
        state = .loading
        sendError = nil
        do {
            state = .loaded(try await postService.comments(postId: postID))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func send() async -> Int? {
        isSending = true
        sendError = nil
        defer { isSending = false }

        do {
            let comment = try await postService.createComment(postId: postID, text: trimmedDraft)
            draft = ""
            var comments: [Comment] = []
            if case .loaded(let existing) = state {
                comments = existing
            }
            comments.append(comment)
            state = .loaded(comments)
            return comments.count
        } catch {
            sendError = error.localizedDescription
            return nil
        }
    }
}
