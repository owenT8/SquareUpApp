//
//  ContentView.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/23/25.
//

import SwiftUI

enum AppScreen {
    case splash, login, createAccount, main
    
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            if (appState.showSplash || appState.currentScreenGroup == .splash) {
                OpeningScreen(onNext: {appState.currentScreenGroup = .login})
            } else if appState.isLoggedIn {
                Home()
            } else if (appState.currentScreenGroup == .login) {
                Login()
                    .transition(.opacity)
            } else if (appState.currentScreenGroup == .createAccount) {
                CreateAccount()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.currentScreenGroup)
    }
}
