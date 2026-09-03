//
//  CreatePostViewModelTests.swift
//  BailanystaTests
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import XCTest
@testable import Bailanysta

@MainActor
final class CreatePostViewModelTests: XCTestCase {
    func testCreatePost() async {
        var createdText: String?
        var postService = StubPostService()
        postService.createHandler = { text in
            createdText = text
            return .sample(text: text)
        }

        let viewModel = CreatePostViewModel(postService: postService)
        viewModel.text = "  Hello world  "

        let published = await viewModel.publish()

        XCTAssertTrue(published)
        XCTAssertEqual(createdText, "Hello world")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isPublishing)
    }

    func testEditPost() async {
        var updated: (Int, String)?
        var postService = StubPostService()
        postService.updateHandler = { id, text in
            updated = (id, text)
            return .sample(id: id, text: text)
        }

        let viewModel = CreatePostViewModel(
            post: .sample(id: 4, text: "Old text"),
            postService: postService
        )
        XCTAssertFalse(viewModel.canPublish)

        viewModel.text = "Updated text"
        let published = await viewModel.publish()

        XCTAssertTrue(published)
        XCTAssertEqual(updated?.0, 4)
        XCTAssertEqual(updated?.1, "Updated text")
        XCTAssertEqual(viewModel.title, "Edit Post")
    }

    func testGenerateSuccess() async {
        var prompt: String?
        var aiService = StubAIService()
        aiService.generateHandler = { idea in
            prompt = idea
            return GeneratedPost(text: "Just landed in Vietnam — already in love with the food.")
        }

        let viewModel = CreatePostViewModel(
            postService: StubPostService(),
            aiService: aiService
        )
        viewModel.text = "I want to write about my trip to Vietnam"
        await viewModel.generate()

        XCTAssertEqual(prompt, "I want to write about my trip to Vietnam")
        XCTAssertEqual(
            viewModel.text,
            "Just landed in Vietnam — already in love with the food."
        )
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isGenerating)
        XCTAssertTrue(viewModel.canPublish)
    }

    func testGenerateErrorKeepsDraft() async {
        var aiService = StubAIService()
        aiService.generateHandler = { _ in throw TestError.failed }

        let viewModel = CreatePostViewModel(
            postService: StubPostService(),
            aiService: aiService
        )
        viewModel.text = "I want to write about my trip to Vietnam"
        await viewModel.generate()

        XCTAssertEqual(viewModel.text, "I want to write about my trip to Vietnam")
        XCTAssertEqual(viewModel.errorMessage, "Request failed")
        XCTAssertFalse(viewModel.isGenerating)
    }
}
