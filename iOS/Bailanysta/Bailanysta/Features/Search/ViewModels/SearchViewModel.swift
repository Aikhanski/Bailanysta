//
//  SearchViewModel.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import Foundation
import Observation

@Observable
final class SearchViewModel {
    var query = ""
    var state: Loadable<[Post]> = .loaded([])
    var busyPostID: Int?
    var actionError: String?

    private let searchService: SearchService
    private let postService: any PostService

    init(
        searchService: SearchService = AppComposition.searchService,
        postService: any PostService = AppComposition.postService
    ) {
        self.searchService = searchService
        self.postService = postService
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func search() async {
        let term = trimmedQuery
        guard !term.isEmpty else {
            state = .loaded([])
            return
        }

        state = .loading
        do {
            try await Task.sleep(for: .milliseconds(250))
            state = .loaded(try await searchService.posts(query: term))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.localizedDescription)
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
