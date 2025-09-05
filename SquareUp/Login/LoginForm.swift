//
//  LoginForm.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/31/25.
//
import SwiftUI

struct LoginForm: View {
    @Binding var fieldValues: [String: String]
    @Binding var fieldErrors: [String: String]
    @Binding var currentLoginScreen: LoginScreen
    
    @EnvironmentObject var appState: AppState
    
    @State var isLoading: Bool = false
    var body: some View {
        ZStack {
            VStack {
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
                        .padding(.top, 10)
                        
                        Spacer()
                        // Form Fields
                        VStack(spacing: 20) {
                            FormField(
                                field: FieldConfig(id: "userId", type: .email, placeholder: "email or username"),
                                value: Binding(
                                    get: { fieldValues["userId"] ?? "" },
                                    set: {
                                        fieldValues["userId"] = $0
                                        // Clear error when user starts typing
                                        if fieldErrors["userId"] != nil {
                                            fieldErrors["userId"] = nil
                                        }
                                    }
                                ),
                                error: fieldErrors["userId"]
                            )
                            FormField(
                                field: FieldConfig(id: "password", type: .password, placeholder: "password"),
                                value: Binding(
                                    get: { fieldValues["password"] ?? "" },
                                    set: {
                                        fieldValues["password"] = $0
                                        // Clear error when user starts typing
                                        if fieldErrors["password"] != nil {
                                            fieldErrors["password"] = nil
                                        }
                                    }
                                ),
                                error: fieldErrors["password"]
                            )
                            
                        }
                        .padding(.horizontal, 30)
                        
                        // Buttons
                        FormButton(
                            button: ButtonConfig(id: "submitLogin", type: .primary, label: "Login", action: .submitLogin),
                            isLoading: isLoading,
                            onTap: {
                                if validateForm(fieldValues: fieldValues, fieldErrors: &fieldErrors) {
                                    Task {
                                        do {
                                            let userId = ["userId" : fieldValues["userId"] ?? ""]
                                            isLoading = true
                                            let checkResponse = try await SquareUpClient.shared.verifyLoginDetails(data: fieldValues)
                                            if checkResponse {
                                                let response = try await SquareUpClient.shared.sendOtpCode(data: userId)
                                                isLoading = false
                                                if response == 200 {
                                                    currentLoginScreen = .verify
                                                } else {
                                                    showError(message: "Error sending verification. Please try again later.")
                                                }
                                            } else {
                                                isLoading = false
                                                showError(message: "Wrong username or password. Please try again.")
                                            }
                                            
                                        } catch {
                                            showError(message: "Something went wrong. Please try again later.")
                                        }
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, 30)
                        
                        FormButton(
                            button: ButtonConfig(id: "forgotPassword", type: .secondary, label: "Forgot Password", action: .forgotPassword),
                            isLoading: isLoading,
                            onTap: {
                                print("Forgot password")
                            }
                        )
                        .padding(.horizontal, 30)
                        
                        Spacer(minLength: 60)
                        
                        FormButton(
                            button: ButtonConfig(id: "createAccount", type: .secondary, label: "Create Account", action: .createAccount),
                            isLoading: isLoading,
                            onTap: {
                                appState.currentScreenGroup = .createAccount
                            }
                        )
                        .padding(.horizontal, 30)
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
