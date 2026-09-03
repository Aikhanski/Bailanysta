//
//  FeedView.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import SwiftUI

struct FeedView: View {
    @State private var viewModel = FeedViewModel()
    @State private var composeSession: ComposeSession?
    @State private var postToDelete: Post?
    @State private var commentsPost: Post?

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    PostListSkeleton()

                case .failed(let message):
                    ContentUnavailableView {
                        Label("Couldn't load feed", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Retry") {
                            Task { await viewModel.load() }
                        }
                    }

                case .loaded(let posts) where posts.isEmpty:
                    ContentUnavailableView {
                        Label("No posts yet", systemImage: "text.bubble")
                    } description: {
                        Text("Write the first post to get started.")
                    } actions: {
                        Button("New Post") {
                            composeSession = .create
                        }
                    }

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
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        composeSession = .create
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create post")
                }
            }
            .postManagement(
                session: $composeSession,
                postToDelete: $postToDelete,
                actionError: $viewModel.actionError,
                onDelete: { await viewModel.delete($0) },
                onComposeFinished: { Task { await viewModel.load() } }
            )
            .commentsSheet($commentsPost) { viewModel.replace($0) }
            .task {
                await viewModel.load()
            }
            .onAppear {
                guard viewModel.state.isLoaded else { return }
                Task { await viewModel.load() }
            }
        }
    }
}

#Preview("Light") {
    FeedView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FeedView()
        .preferredColorScheme(.dark)
}
