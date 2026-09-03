//
//  AppComposition.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

enum AppComposition {
    static let apiClient = APIClient()
    static let postService: any PostService = PostServiceImpl(client: apiClient)
    static let searchService = SearchService(client: apiClient)
    static let profileService = ProfileService(client: apiClient)
    static let aiService: any AIService = AIServiceImpl(client: apiClient)
}
