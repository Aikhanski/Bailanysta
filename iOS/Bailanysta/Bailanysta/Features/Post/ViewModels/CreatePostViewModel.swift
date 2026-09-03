//
//  CreatePostViewModel.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import Foundation
import Observation

@Observable
final class CreatePostViewModel {
    var text: String
    var isPublishing = false
    var isGenerating = false
    var errorMessage: String?

    private let postID: Int?
    private let originalText: String
    private let postService: any PostService
    private let aiService: any AIService
    private let maxLength = 1000

    init(
        post: Post? = nil,
        postService: any PostService = AppComposition.postService,
        aiService: any AIService = AppComposition.aiService
    ) {
        self.postID = post?.id
        self.originalText = post?.text ?? ""
        self.text = post?.text ?? ""
        self.postService = postService
        self.aiService = aiService
    }

    var title: String {
        postID == nil ? "New Post" : "Edit Post"
    }

    var submitTitle: String {
        postID == nil ? "Post" : "Save"
    }

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canPublish: Bool {
        let count = trimmedText.count
        let hasChanges = postID == nil || trimmedText != originalText
        return count > 0 && count <= maxLength && hasChanges && !isPublishing && !isGenerating
    }

    var canGenerate: Bool {
        let count = trimmedText.count
        return count > 0 && count <= maxLength && !isPublishing && !isGenerating
    }

    func publish() async -> Bool {
        isPublishing = true
        errorMessage = nil
        defer { isPublishing = false }

        do {
            if let postID {
                _ = try await postService.update(id: postID, text: trimmedText)
            } else {
                _ = try await postService.create(text: trimmedText)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func generate() async {
        guard canGenerate else { return }

        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            let generated = try await aiService.generatePost(prompt: trimmedText)
            text = generated.text
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
