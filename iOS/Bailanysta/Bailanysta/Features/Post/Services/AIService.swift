//
//  AIService.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

protocol AIService {
    func generatePost(prompt: String) async throws -> GeneratedPost
}

enum AIEndpoint: NetworkRequestConvertible {
    case generatePost

    var method: APIMethod { .post }
    var path: String { "/ai/generate-post" }
}

struct AIServiceImpl: AIService {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func generatePost(prompt: String) async throws -> GeneratedPost {
        try await client.request(
            AIEndpoint.generatePost,
            body: GeneratePostRequest(prompt: prompt)
        )
    }
}
