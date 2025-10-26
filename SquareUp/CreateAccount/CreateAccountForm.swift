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
                                        if (validateForm(fieldValues: &fieldValues, fieldErrors: &fieldErrors)) {
                                            buttonPress(button: button)
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
        
        if isLoading {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }
    
    private func showError(message: String = "Something went wrong. Please try again later.", returnToHome: Bool = true) {
        appState.errorMessage = message
        appState.showErrorToast = true
        if (returnToHome) {
            screenStack.append(.error)
        }
    }

    private func isPrimaryButton(_ button: ButtonConfig) -> Bool {
        return button.type == .primary
    }
    
    private func buttonAction(_ button: ButtonConfig, screenStack: inout [CreateAccountScreen]) {
        switch button.action {
            case .goToEmailSignup:
                screenStack.append(.email)
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
    
    private func buttonPress(button: ButtonConfig) {
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
        } else if button.id == "username" {
            let data = ["username": fieldValues["username"] ?? ""]
            Task {
                do {
                    isLoading = true
                    let response = try await SquareUpClient.shared.verifyUsername(data: data)
                    isLoading = false
                    if response {
                        buttonAction(button, screenStack: &screenStack)
                    } else {
                        showError(message: "Username is already in use.", returnToHome: false)
                    }
                } catch {
                    showError()
                }
            }
        } else if button.id == "email" {
            let data = ["email": fieldValues["email"] ?? ""]
            if !validateForm(fieldValues: &fieldValues, fieldErrors: &fieldErrors) {
                showError(message: "Invalid email.", returnToHome: false)
            } else {
                Task {
                    do {
                        isLoading = true
                        let response = try await SquareUpClient.shared.verifyEmail(data: data)
                        isLoading = false
                        if response && validateForm(fieldValues: &fieldValues, fieldErrors: &fieldErrors) {
                            buttonAction(button, screenStack: &screenStack)
                        } else {
                            showError(message: "Email is already in use.", returnToHome: false)
                        }
                    } catch {
                        showError()
                    }
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
                        screenStack.append(.exit)
                    } else {
                        showError(message: "Incorrect verification code.", returnToHome: false)
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
}
