//
//  Comment.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import Foundation

struct Comment: Decodable, Identifiable {
    let id: Int
    let postId: Int
    let authorId: Int
    let text: String
    let createdAt: Date
    let author: User
}
