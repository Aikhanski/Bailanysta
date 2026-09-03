//
//  ComposeView.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import SwiftUI

enum ComposeSession: Identifiable {
    case create
    case edit(Post)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let post):
            return "edit-\(post.id)"
        }
    }

    var post: Post? {
        switch self {
        case .create:
            return nil
        case .edit(let post):
            return post
        }
    }
}

struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreatePostViewModel

    var onPosted: () -> Void = {}

    init(post: Post? = nil, onPosted: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: CreatePostViewModel(post: post))
        self.onPosted = onPosted
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $viewModel.text)
                    .frame(minHeight: 180)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
                    .disabled(viewModel.isPublishing || viewModel.isGenerating)
                    .accessibilityLabel("Post text")

                if viewModel.isGenerating {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Improving with AI…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Improving with AI")
                } else {
                    Button("Improve with AI") {
                        Task { await viewModel.generate() }
                    }
                    .disabled(!viewModel.canGenerate)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .disabled(viewModel.isPublishing || viewModel.isGenerating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isPublishing {
                        ProgressView()
                    } else {
                        Button(viewModel.submitTitle) {
                            Task {
                                if await viewModel.publish() {
                                    onPosted()
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!viewModel.canPublish)
                    }
                }
            }
        }
    }
}

#Preview {
    ComposeView()
}

#Preview("Dark") {
    ComposeView()
        .preferredColorScheme(.dark)
}

extension View {
    func postManagement(
        session: Binding<ComposeSession?>,
        postToDelete: Binding<Post?>,
        actionError: Binding<String?>,
        onDelete: @escaping (Post) async -> Void,
        onComposeFinished: @escaping () -> Void
    ) -> some View {
        sheet(item: session) { target in
            ComposeView(post: target.post, onPosted: onComposeFinished)
        }
        .confirmationDialog(
            "Delete this post?",
            isPresented: Binding(
                get: { postToDelete.wrappedValue != nil },
                set: { if !$0 { postToDelete.wrappedValue = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let post = postToDelete.wrappedValue else { return }
                postToDelete.wrappedValue = nil
                Task { await onDelete(post) }
            }
            Button("Cancel", role: .cancel) {
                postToDelete.wrappedValue = nil
            }
        } message: {
            Text("This cannot be undone.")
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { actionError.wrappedValue != nil },
                set: { if !$0 { actionError.wrappedValue = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionError.wrappedValue ?? "")
        }
    }
}
