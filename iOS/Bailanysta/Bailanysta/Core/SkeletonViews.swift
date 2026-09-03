//
//  SkeletonViews.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import SwiftUI

struct SkeletonLine: View {
    var width: CGFloat?
    var height: CGFloat = 10

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.fill.tertiary)
            .frame(width: width, height: height)
    }
}

struct PostSkeletonRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(.fill.tertiary)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 8) {
                    SkeletonLine(width: 120, height: 12)
                    SkeletonLine(height: 12)
                    SkeletonLine(width: 180, height: 12)
                }
            }

            HStack(spacing: 20) {
                SkeletonLine(width: 36, height: 10)
                SkeletonLine(width: 36, height: 10)
            }
            .padding(.leading, 52)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
}

struct ProfileHeaderSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(.fill.tertiary)
                .frame(width: 72, height: 72)
            SkeletonLine(width: 140, height: 16)
            SkeletonLine(width: 88, height: 12)
            SkeletonLine(width: 200, height: 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading profile")
    }
}

struct CommentSkeletonRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonLine(width: 150, height: 10)
            SkeletonLine(height: 12)
            SkeletonLine(width: 220, height: 12)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
}

struct PostListSkeleton: View {
    var rowCount = 6

    var body: some View {
        List(0..<rowCount, id: \.self) { _ in
            PostSkeletonRow()
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        .accessibilityLabel("Loading posts")
    }
}

struct CommentsListSkeleton: View {
    var body: some View {
        List(0..<5, id: \.self) { _ in
            CommentSkeletonRow()
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        .accessibilityLabel("Loading comments")
    }
}
