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
    
    var body: some View {
        switch currentScreenGroup {
            case .splash:
                OpeningScreen(onNext: {currentScreenGroup = .login})
            case .login:
                Login(currentScreen: $currentScreenGroup)
            case .createAccount:
                CreateAccount(currentMainScreen: $currentScreenGroup)
            case .main:
                Text("MainView")
        
        }
    }
}

#Preview {
    ContentView()
}
