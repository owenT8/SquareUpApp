//
//  CreateAccountForm.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/23/25.
//
import SwiftUI
import PhoneNumberKit

struct CreateAccountForm: View {
    let config: CreateAccountFormConfig
    @Binding var fieldValues: [String : String]
    @Binding var fieldErrors: [String : String]
    @Binding var screenStack: [CreateAccountScreen]
    
    @State private var isLoading: Bool = false
    @State private var tempValues: [String : String]
    
    let phoneNumberKit = PhoneNumberUtility()
        
    @EnvironmentObject var appState: AppState
        
    init(config: CreateAccountFormConfig, fieldValues: Binding<[String : String]>, fieldErrors: Binding<[String : String]>, screenStack: Binding<[CreateAccountScreen]>) {
        self.config = config
        _fieldValues = fieldValues
        _fieldErrors = fieldErrors
        _screenStack = screenStack
        // initialize state once
        _tempValues = State(initialValue: Dictionary(uniqueKeysWithValues: config.fields.map { ($0.id, "") }))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: {
                        for field in config.fields {
                            fieldValues[field.id] = nil
                        }
                        screenStack.popLast()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 5) {
                            // Logo
                            ZStack {
                                Image("SquareUpLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 130, height: 130)
                            }
                                
                            Text(Constants.appName)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                        // Form Fields
                        let fields = config.fields
                        
                        VStack(spacing: 20) {
                            ForEach(fields, id: \.id) { field in
                                FormField(
                                    field: field,
                                    value: Binding(
                                        get: {
                                            fieldValues[field.id] ?? ""
                                        },
                                        set: {
                                            fieldValues[field.id] = $0
                                            // Clear error when user starts typing
                                            if fieldErrors[field.id] != nil {
                                                fieldErrors[field.id] = nil
                                            }
                                        }
                                    ),
                                    error: fieldErrors[field.id]
                                )
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        let buttons = config.buttons
                        
                        VStack(spacing: 20) {
                            ForEach(buttons, id: \.id) { button in
                                FormButton(
                                    button: button,
                                    isLoading: isLoading,
                                    onTap: {
                                        if button.id == "signUp" {
                                            let data = ["email": fieldValues["email"] ?? ""]
                                            Task {
                                                do {
                                                    isLoading = true
                                                    let response = try await SquareUpClient.shared.sendOtpCode(data: data)
                                                    isLoading = false
                                                    if response == 200 {
                                                        screenStack.append(.verificationCode)
                                                    } else {
                                                        showError()
                                                    }
                                                } catch {
                                                    showError()
                                                }
                                            }
                                        } else if button.id == "verify" {
                                            Task {
                                                do {
                                                    isLoading = true
                                                    let response = try await SquareUpClient.shared.signUp(data: fieldValues)
                                                    isLoading = false
                                                    if response == 201 {
                                                        fieldValues = [:]
                                                        appState.isLoggedIn = true
                                                        screenStack.append(.exit)
                                                    } else {
                                                        showError()
                                                    }
                                                } catch {
                                                    showError()
                                                }
                                            }
                                        } else if button.type != .primary {
                                            for field in config.fields {
                                                fieldValues[field.id] = nil
                                            }
                                            buttonAction(button, screenStack: &screenStack)
                                        } else if validateForm(fieldValues: &fieldValues, fieldErrors: &fieldErrors) {
                                            buttonAction(button, screenStack: &screenStack)
                                        }
                                    }
                                )
                                .padding(.horizontal, 30)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func showError() {
        appState.errorMessage = "Something went wrong. Please try again later."
        appState.showErrorToast = true
        screenStack.append(.exit)
    }

    private func isPrimaryButton(_ button: ButtonConfig) -> Bool {
        return button.type == .primary
    }
    
    private func buttonAction(_ button: ButtonConfig, screenStack: inout [CreateAccountScreen]) {
        switch button.action {
            case .goToEmailSignup:
                if screenStack.last == .phone {
                    screenStack.popLast()
                }
                screenStack.append(.email)
            case .goToPhoneSignup:
                screenStack.popLast()
                screenStack.append(.phone)
            case .goToPasswordSignup: screenStack.append(.password)
            case .goToVerificationCode: screenStack.append(.verificationCode)
            default: break
        }
    }
    
    private func validateForm(fieldValues: inout [String : String], fieldErrors: inout [String : String]) -> Bool {
        fieldErrors.removeAll()
        var isValid = true
        
        for field in config.fields {
            let key = field.id
            let value = fieldValues[field.id] ?? ""
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fieldErrors[key] = "This field is required"
                isValid = false
            } else if value.contains(" ") {
                fieldErrors[key] = "This field cannot contain spaces"
                isValid = false
            } else if key == "email" && !value.isValidEmail() {
                fieldErrors[key] = "Enter valid email address"
                isValid = false
            } else if key == "password" && !value.isValidPassword() {
                fieldErrors[key] = "Password have at least 6 characters, one digit, and one special character"
                isValid = false
            }
        }
        
        return isValid
    }
    
    private func verifyOTP(fieldValues: inout [String : String], fieldErrors: inout [String : String]) async -> Bool {
        fieldErrors.removeAll()
        var isValid = true
        
        if fieldValues["verificationCode"] == "123456" {
            fieldValues["verificationCode"] = nil
            print("OTP verified successfully")
        } else {
            fieldErrors["verifiationCoed"] = "Invalid OTP"
            isValid = false
        }
        
        return isValid
    }
}
