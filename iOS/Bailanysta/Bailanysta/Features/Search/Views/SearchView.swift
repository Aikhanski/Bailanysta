//
//  SearchView.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var composeSession: ComposeSession?
    @State private var postToDelete: Post?
    @State private var commentsPost: Post?

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if viewModel.trimmedQuery.isEmpty {
                    ContentUnavailableView(
                        "Search posts",
                        systemImage: "magnifyingglass",
                        description: Text("Try a word or #hashtag.")
                    )
                } else {
                    results
                }
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.query, prompt: "Posts and hashtags")
            .postManagement(
                session: $composeSession,
                postToDelete: $postToDelete,
                actionError: $viewModel.actionError,
                onDelete: { await viewModel.delete($0) },
                onComposeFinished: { Task { await viewModel.search() } }
            )
            .commentsSheet($commentsPost) { viewModel.replace($0) }
            .task(id: viewModel.trimmedQuery) {
                await viewModel.search()
            }
        }
    }

    @ViewBuilder
    private var results: some View {
        switch viewModel.state {
        case .loading:
            PostListSkeleton()

        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't search", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") {
                    Task { await viewModel.search() }
                }
            }

        case .loaded(let posts) where posts.isEmpty:
            ContentUnavailableView(
                "No posts found",
                systemImage: "text.magnifyingglass",
                description: Text("Nothing matched “\(viewModel.trimmedQuery)”.")
            )

        case .loaded(let posts):
            List(posts) { post in
                PostRowView(
                    post: post,
                    isBusy: viewModel.busyPostID == post.id,
                    onLike: { Task { await viewModel.toggleLike(post) } },
                    onComments: { commentsPost = post },
                    onEdit: { composeSession = .edit(post) },
                    onDelete: { postToDelete = post }
                )
            }
            .listStyle(.plain)
        }
    }
}

#Preview("Light") {
    SearchView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SearchView()
        .preferredColorScheme(.dark)
}
