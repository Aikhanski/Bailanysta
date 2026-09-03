//
//  BailanystaApp.swift
//  Bailanysta
//
//  Created by Aikhan.Khassenov on 03.09.2026.
//

import SwiftUI

@main
struct BailanystaApp: App {
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}
