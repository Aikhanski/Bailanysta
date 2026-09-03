//
//  Loadable.swift
//  Bailanysta
//
//  Created by Aikhan Khassenov on 03.09.2026.
//

enum Loadable<Value> {
    case loading
    case loaded(Value)
    case failed(String)

    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }
}
