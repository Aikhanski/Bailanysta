//
//  User.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

import Foundation

struct User: Decodable, Identifiable {
    let id: Int
    let username: String
    let displayName: String
    let bio: String
    let createdAt: Date

    var initials: String {
        let letters = displayName.split(separator: " ").compactMap(\.first)
        let prefix = letters.prefix(2)
        if prefix.isEmpty {
            return "?"
        }
        return String(prefix).uppercased()
    }
}
