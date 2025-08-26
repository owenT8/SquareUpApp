//
//  CreateAccount.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/23/25.
//
import SwiftUI

enum CreateAccountScreen {
    case name, email, phone, verificationCode
}

struct CreateAccount: View {
    @Binding var currentMainScreen: AppScreen
    
    @State var screenStack: [CreateAccountScreen] = [.name]
    @State var fieldValues: [String: String] = [:]
    @State var fieldErrors: [String: String] = [:]
    
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
            }
//            else if screenStack.last == .phone {
//                CreateAccountForm(
//                    config: phoneConfig,
//                    fieldValues: $fieldValues,
//                    fieldErrors: $fieldErrors,
//                    screenStack: $screenStack
//                )
//                .transition(.opacity)
//            }
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
                currentMainScreen = .login
            }
        }
        .onChange(of: fieldValues) {
            print(fieldValues)
        }
    }
    
    let nameConfig: CreateAccountFormConfig = .init(
        name: "name",
        fields: [
            FieldConfig(id: "firstName", type: .firstName, placeholder: "First Name"),
            FieldConfig(id: "lastName", type: .lastName, placeholder: "Last Name"),
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
            ButtonConfig(id: "email", type: .primary, label: "Next", action: .goToVerificationCode),
//            ButtonConfig(id: "signUpWithPhone", type: .secondary, label: "Sign Up with Phone", action: .goToPhoneSignup)
        ]
    )
    
//    let phoneConfig: CreateAccountFormConfig = .init(
//        name: "phoneNumber",
//        fields: [
//            FieldConfig(id: "phoneNumber", type: .phone, placeholder: "Phone Number")
//        ],
//        buttons: [
//            ButtonConfig(id: "phoneNumber", type: .primary, label: "Next", action: .goToVerificationCode),
//            ButtonConfig(id: "signUpWithEmail", type: .secondary, label: "Sign Up with Email", action: .goToEmailSignup)
//        ]
//    )
//    
    let verifyUserId: CreateAccountFormConfig = .init(
        name: "verificationCode",
        fields: [
            FieldConfig(id: "verificationCode", type: .verificationCode, placeholder: "Verification Code")
        ],
        buttons: [
            ButtonConfig(id: "createPassword", type: .primary, label: "Verify", action: .goToPasswordSignup)
        ]
    )
    
    let passwordConfig: CreateAccountFormConfig = .init(
        name: "password",
        fields: [
            FieldConfig(id: "password", type: .password, placeholder: "Password")
        ],
        buttons: [
            ButtonConfig(id: "signUp", type: .primary, label: "Sign Up", action: .submitSignup)
        ]
    )
}

