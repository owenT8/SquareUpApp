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
    @State var currentScreenGroup: AppScreen = .splash
    @State var squareUpClient: SquareUpClient = .init()
    @State var keychainHelper: KeychainHelper = .init()
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.isLoggedIn {
            Text("MainView")
        } else if (currentScreenGroup == .splash) {
            OpeningScreen(onNext: {currentScreenGroup = .login})
        } else if (currentScreenGroup == .login) {
            Login(currentScreen: $currentScreenGroup, squareUpClient: $squareUpClient, keychainHelper: $keychainHelper)
            .environmentObject(appState)
        } else if (currentScreenGroup == .createAccount) {
            CreateAccount(currentMainScreen: $currentScreenGroup)
        }
    }
}

#Preview {
    ContentView()
}
