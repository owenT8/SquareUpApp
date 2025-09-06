//
//  ForgotPassword.swift
//  SquareUp
//
//  Created by Owen  Taylor on 9/5/25.
//
import SwiftUI

enum ForgotPasswordScreen {
    case userId, newPassword, exit
}

struct ForgotPassword: View {
    @Binding var currentLoginScreen: LoginScreen
    
    @State var fieldValues: [String: String] = [:]
    @State var fieldErrors: [String: String] = [:]
    @State var currentForgotPasswordScreen: ForgotPasswordScreen = .userId
    
    @EnvironmentObject var appState: AppState
    
    @State var isLoading: Bool = false
    var body: some View {
        ZStack {
            if currentForgotPasswordScreen == .userId {
                UserIdForm(fieldValues: $fieldValues, fieldErrors: $fieldErrors, currentForgotPasswordScreen: $currentForgotPasswordScreen)
                    .transition(.opacity)
            } else if currentForgotPasswordScreen == .newPassword {
                NewPasswordForm(fieldValues: $fieldValues, fieldErrors: $fieldErrors, currentForgotPasswordScreen: $currentForgotPasswordScreen)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: currentForgotPasswordScreen)
        .onChange(of: currentForgotPasswordScreen) {
            if currentForgotPasswordScreen == .exit {
                currentLoginScreen = .login
            }
        }
        
        if isLoading {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }
    
    private func validateForm(fieldValues: [String : String], fieldErrors: inout [String : String]) -> Bool {
        fieldErrors.removeAll()
        
        var isValid = true
        
        for (key, value) in fieldValues {
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fieldErrors[key] = "This field is required"
                isValid = false
            }
        }
        
        return isValid
    }
    
    private func showError(message: String) {
        appState.errorMessage = message
        appState.showErrorToast = true
        appState.currentScreenGroup = .login
    }
}
