//
//  ProfileViewModel.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import Foundation
import Observation

struct ProfileContent {
    var user: User
    var posts: [Post]
}

@Observable
final class ProfileViewModel {
    var state: Loadable<ProfileContent> = .loading
    var busyPostID: Int?
    var actionError: String?

    private let userID: Int
    private let profileService: ProfileService
    private let postService: any PostService

    init(
        userID: Int = APIConfig.currentUserID,
        profileService: ProfileService = AppComposition.profileService,
        postService: any PostService = AppComposition.postService
    ) {
        self.userID = userID
        self.profileService = profileService
        self.postService = postService
    }

    func load() async {
        let isFirstLoad = !state.isLoaded
        if isFirstLoad {
            state = .loading
        }

        do {
            async let user = profileService.user(id: userID)
            async let posts = profileService.posts(userId: userID)
            state = .loaded(ProfileContent(user: try await user, posts: try await posts))
        } catch {
            if isFirstLoad {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func replace(_ post: Post) {
        guard case .loaded(var content) = state else { return }
        content.posts.replace(post)
        state = .loaded(content)
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
            if case .loaded(var content) = state {
                content.posts.removeAll { $0.id == post.id }
                state = .loaded(content)
            }
        } catch {
            actionError = error.localizedDescription
        }
    }
}
