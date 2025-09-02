//
//  CreateAccount.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/23/25.
//
import SwiftUI

enum CreateAccountScreen {
    case name, email, password, verificationCode, exit, error
}

struct CreateAccount: View {
    @State var screenStack: [CreateAccountScreen] = [.name]
    @State var fieldValues: [String: String] = [:]
    @State var fieldErrors: [String: String] = [:]
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            if screenStack.last == .name {
                CreateAccountForm(
                    config: nameConfig,
                    fieldValues: $fieldValues,
                    fieldErrors: $fieldErrors,
                    screenStack: $screenStack
                )
                .transition(.opacity)
            } else if screenStack.last == .email {
                CreateAccountForm(
                    config: emailConfig,
                    fieldValues: $fieldValues,
                    fieldErrors: $fieldErrors,
                    screenStack: $screenStack
                )
                .transition(.opacity)
            } else if screenStack.last == .password {
                CreateAccountForm(
                    config: passwordConfig,
                    fieldValues: $fieldValues,
                    fieldErrors: $fieldErrors,
                    screenStack: $screenStack
                )
                .transition(.opacity)
            }
            else if screenStack.last == .verificationCode {
                CreateAccountForm(
                    config: verifyUserId,
                    fieldValues: $fieldValues,
                    fieldErrors: $fieldErrors,
                    screenStack: $screenStack
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: screenStack.last)
        .onChange(of: screenStack) {
            if screenStack.isEmpty {
                appState.currentScreenGroup = .login
            }
            if screenStack.last == .exit {
                appState.isLoggedIn = true
            }
            if screenStack.last == .error {
                appState.currentScreenGroup = .login
            }
        }
    }
    
    let nameConfig: CreateAccountFormConfig = .init(
        name: "name",
        fields: [
            FieldConfig(id: "first_name", type: .firstName, placeholder: "First Name"),
            FieldConfig(id: "last_name", type: .lastName, placeholder: "Last Name"),
            FieldConfig(id: "username", type: .userName, placeholder: "Username")
        ],
        buttons: [
            ButtonConfig(id: "next", type: .primary, label: "Next", action: .goToEmailSignup)
        ]
    )
    
    let emailConfig: CreateAccountFormConfig = .init(
        name: "email",
        fields: [
            FieldConfig(id: "email", type: .email, placeholder: "Email Address")
        ],
        buttons: [
            ButtonConfig(id: "email", type: .primary, label: "Next", action: .goToPasswordSignup)
        ]
    )

    let passwordConfig: CreateAccountFormConfig = .init(
        name: "password",
        fields: [
            FieldConfig(id: "password", type: .password, placeholder: "Password")
        ],
        buttons: [
            ButtonConfig(id: "signUp", type: .primary, label: "Sign Up", action: .goToVerificationCode)
        ]
    )
    
    let verifyUserId: CreateAccountFormConfig = .init(
        name: "verificationCode",
        fields: [
            FieldConfig(id: "otp", type: .verificationCode, placeholder: "Verification Code")
        ],
        buttons: [
            ButtonConfig(id: "verify", type: .primary, label: "Verify", action: .goToHome)
        ]
    )

}

