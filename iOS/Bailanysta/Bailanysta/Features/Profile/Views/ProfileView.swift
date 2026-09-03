//
//  ProfileView.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import SwiftUI

struct ProfileView: View {
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system
    @State private var viewModel = ProfileViewModel()
    @State private var composeSession: ComposeSession?
    @State private var postToDelete: Post?
    @State private var commentsPost: Post?

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        ForEach(Appearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Appearance")
                }

                switch viewModel.state {
                case .loading:
                    Section {
                        ProfileHeaderSkeleton()
                    }
                    ForEach(0..<3, id: \.self) { _ in
                        PostSkeletonRow()
                    }

                case .failed(let message):
                    Section {
                        ContentUnavailableView {
                            Label("Couldn't load profile", systemImage: "wifi.exclamationmark")
                        } description: {
                            Text(message)
                        } actions: {
                            Button("Retry") {
                                Task { await viewModel.load() }
                            }
                        }
                        .listRowSeparator(.hidden)
                    }

                case .loaded(let content):
                    Section {
                        ProfileHeaderView(user: content.user)
                    }

                    if content.posts.isEmpty {
                        ContentUnavailableView(
                            "No posts yet",
                            systemImage: "text.bubble",
                            description: Text("Posts you write will show up here.")
                        )
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(content.posts) { post in
                            PostRowView(
                                post: post,
                                isBusy: viewModel.busyPostID == post.id,
                                onLike: { Task { await viewModel.toggleLike(post) } },
                                onComments: { commentsPost = post },
                                onEdit: { composeSession = .edit(post) },
                                onDelete: { postToDelete = post }
                            )
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.load()
            }
            .navigationTitle("Profile")
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

private struct ProfileHeaderView: View {
    let user: User

    var body: some View {
        VStack(spacing: 12) {
            Text(user.initials)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(.tint, in: Circle())

            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.title3.weight(.semibold))
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !user.bio.isEmpty {
                Text(user.bio)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

#Preview("Light") {
    ProfileView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ProfileView()
        .preferredColorScheme(.dark)
}
