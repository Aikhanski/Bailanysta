//
//  CommentsView.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import SwiftUI

struct CommentsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CommentsViewModel

    let post: Post
    var onPostUpdated: (Post) -> Void

    init(post: Post, onPostUpdated: @escaping (Post) -> Void) {
        self.post = post
        self.onPostUpdated = onPostUpdated
        _viewModel = State(initialValue: CommentsViewModel(postID: post.id))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(spacing: 0) {
                commentsContent
                Divider()
                composer
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var commentsContent: some View {
        switch viewModel.state {
        case .loading:
            CommentsListSkeleton()

        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load comments", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") {
                    Task { await viewModel.load() }
                }
            }

        case .loaded(let comments) where comments.isEmpty:
            ContentUnavailableView(
                "No comments yet",
                systemImage: "text.bubble",
                description: Text("Be the first to comment.")
            )

        case .loaded(let comments):
            List(comments) { comment in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(comment.author.displayName)
                            .font(.subheadline.weight(.semibold))
                        Text("@\(comment.author.username)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(comment.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(comment.text)
                        .font(.body)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
        }
    }

    private var composer: some View {
        @Bindable var viewModel = viewModel

        return VStack(alignment: .leading, spacing: 8) {
            if let sendError = viewModel.sendError {
                Text(sendError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Write a comment", text: $viewModel.draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(viewModel.isSending)

                if viewModel.isSending {
                    ProgressView()
                        .padding(.bottom, 8)
                } else {
                    Button("Send") {
                        Task {
                            if let count = await viewModel.send() {
                                onPostUpdated(post.withCommentCount(count))
                            }
                        }
                    }
                    .disabled(!viewModel.canSend)
                }
            }
        }
        .padding()
    }
}

extension View {
    func commentsSheet(_ post: Binding<Post?>, onPostUpdated: @escaping (Post) -> Void) -> some View {
        sheet(item: post) { item in
            CommentsView(post: item, onPostUpdated: onPostUpdated)
        }
    }
}
