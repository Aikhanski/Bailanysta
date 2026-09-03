//
//  PostRowView.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import SwiftUI

struct PostRowView: View {
    let post: Post
    var isBusy = false
    var onLike: (() -> Void)?
    var onComments: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(post.author.initials)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.tint, in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(post.author.displayName)
                            .font(.subheadline.weight(.semibold))
                        Text("@\(post.author.username)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(post.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(post.text)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 20) {
                Button {
                    onLike?()
                } label: {
                    Label(
                        "\(post.likeCount)",
                        systemImage: post.isLiked ? "heart.fill" : "heart"
                    )
                    .foregroundStyle(post.isLiked ? Color.red : Color.secondary)
                }
                .accessibilityLabel(post.isLiked ? "Unlike" : "Like")
                .accessibilityValue("\(post.likeCount) likes")

                Button {
                    onComments?()
                } label: {
                    Label("\(post.commentCount)", systemImage: "bubble.right")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Comments")
                .accessibilityValue("\(post.commentCount) comments")
            }
            .buttonStyle(.borderless)
            .font(.subheadline)
            .padding(.leading, 52)
        }
        .padding(.vertical, 4)
        .opacity(isBusy ? 0.4 : 1)
        .overlay {
            if isBusy {
                ProgressView()
            }
        }
        .modifier(PostOwnerActions(
            enabled: post.isOwnedByCurrentUser && !isBusy,
            onEdit: onEdit,
            onDelete: onDelete
        ))
        .disabled(isBusy)
    }
}

private struct PostOwnerActions: ViewModifier {
    let enabled: Bool
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    func body(content: Content) -> some View {
        if enabled {
            content
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    buttons
                }
                .contextMenu {
                    buttons
                }
        } else {
            content
        }
    }

    @ViewBuilder
    private var buttons: some View {
        Button("Delete", role: .destructive) {
            onDelete?()
        }
        Button("Edit") {
            onEdit?()
        }
    }
}
