//
//  SquareUpApp.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/23/25.
//

import SwiftUI

@main
struct SquareUpApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
