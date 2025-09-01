//
//  Login.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/23/25.
//

import SwiftUI
import AuthenticationServices

enum LoginScreen {
    case login, verify
}

struct Login: View {
    @Binding var currentScreen: AppScreen
    @Binding var squareUpClient: SquareUpClient
    @Binding var keychainHelper: KeychainHelper
    
    @State private var fieldValues: [String : String] = [:]
    @State private var isLoading: Bool = false
    @State private var fieldErrors: [String : String] = [:]
    @State private var errorMessage: String?
    @State private var loginData: [String: String]?
    @State private var loginScreen: LoginScreen = .login
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            if loginScreen == .login {
                LoginForm(fieldValues: $fieldValues, fieldErrors: $fieldErrors, currentScreen: $loginScreen, currentAppScreen: $currentScreen)
                    .transition(.opacity)
            } else {
                OTPForm(fieldValues: $fieldValues, fieldErrors: $fieldErrors, currentScreen: $loginScreen, currentAppScreen: $currentScreen)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: loginScreen)
        .onChange(of: fieldValues) { screen, oldScreen in
            print(fieldValues)
        }
    }
}


extension String {
    func isValidPassword() -> Bool {
        let passwordRegex = "^(?=.*\\d)(?=.*[^A-Za-z0-9]).{6,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: self)
    }
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
}

