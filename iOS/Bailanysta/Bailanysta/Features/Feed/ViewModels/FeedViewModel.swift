//
//  FeedViewModel.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import Foundation
import Observation

@Observable
final class FeedViewModel {
    var state: Loadable<[Post]> = .loading
    var busyPostID: Int?
    var actionError: String?

    private let postService: any PostService

    init(postService: any PostService = AppComposition.postService) {
        self.postService = postService
    }

    func load() async {
        let isFirstLoad = !state.isLoaded
        if isFirstLoad {
            state = .loading
        }

        do {
            state = .loaded(try await postService.fetch())
        } catch {
            if isFirstLoad {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func replace(_ post: Post) {
        guard case .loaded(var posts) = state else { return }
        posts.replace(post)
        state = .loaded(posts)
    }

    func toggleLike(_ post: Post) async {
        replace(post.withLikeToggled())
        do {
            let updated: Post
            if post.isLiked {
                updated = try await postService.unlike(id: post.id)
            } else {
                updated = try await postService.like(id: post.id)
            }
            replace(updated)
        } catch {
            replace(post)
            actionError = error.localizedDescription
        }
    }

    func delete(_ post: Post) async {
        busyPostID = post.id
        actionError = nil
        defer { busyPostID = nil }

        do {
            try await postService.delete(id: post.id)
            if case .loaded(var posts) = state {
                posts.removeAll { $0.id == post.id }
                state = .loaded(posts)
            }
        } catch {
            actionError = error.localizedDescription
        }
    }
}
