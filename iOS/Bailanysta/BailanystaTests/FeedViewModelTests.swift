//
//  FeedViewModelTests.swift
//  BailanystaTests
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import XCTest
@testable import Bailanysta

@MainActor
final class FeedViewModelTests: XCTestCase {
    func testLoadSuccess() async {
        let post = Post.sample(text: "Hello from Almaty")
        var postService = StubPostService()
        postService.fetchHandler = { [post] }

        let viewModel = FeedViewModel(postService: postService)
        await viewModel.load()

        guard case .loaded(let posts) = viewModel.state else {
            return XCTFail("Expected loaded feed")
        }
        XCTAssertEqual(posts.count, 1)
        XCTAssertEqual(posts[0].text, "Hello from Almaty")
    }

    func testLoadError() async {
        var postService = StubPostService()
        postService.fetchHandler = { throw TestError.failed }

        let viewModel = FeedViewModel(postService: postService)
        await viewModel.load()

        guard case .failed(let message) = viewModel.state else {
            return XCTFail("Expected failed feed")
        }
        XCTAssertEqual(message, "Request failed")
    }

    func testDeletePost() async {
        let post = Post.sample(id: 7, text: "Remove me")
        var deletedID: Int?
        var postService = StubPostService()
        postService.fetchHandler = { [post] }
        postService.deleteHandler = { id in
            deletedID = id
        }

        let viewModel = FeedViewModel(postService: postService)
        await viewModel.load()
        await viewModel.delete(post)

        guard case .loaded(let posts) = viewModel.state else {
            return XCTFail("Expected loaded feed after delete")
        }
        XCTAssertEqual(deletedID, 7)
        XCTAssertTrue(posts.isEmpty)
        XCTAssertNil(viewModel.actionError)
    }
}
