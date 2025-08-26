//
//  Login.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/23/25.
//

import SwiftUI
import AuthenticationServices

struct Login: View {
    @Binding var currentScreen: AppScreen
    @Binding var squareUpClient: SquareUpClient
    @Binding var keychainHelper: KeychainHelper
    
    @State private var fieldValues: [String : String] = [:]
    @State private var isLoading: Bool = false
    @State private var fieldErrors: [String : String] = [:]
    @State private var errorMessage: String?
    @State private var loginData: [String: String]?
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Background
            Color("BackgroundColor")
                .ignoresSafeArea()
            
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
                        .padding(.top, 20)
                        
                        Spacer()
                        // Form Fields
                        VStack(spacing: 20) {
                            FormField(
                                field: FieldConfig(id: "userId", type: .userId, placeholder: "email, phone, or username"),
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
                                            let loginResponse = await submitLogin()
                                            print(loginData)
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
                        
                        SignInWithAppleButton(.continue, onRequest: { request in
                            // Handle the request
                        }, onCompletion: { result in
                            // Handle the result
                        })
                        .signInWithAppleButtonStyle(.black)
                        .padding(.horizontal, 30)
                        .frame(height: 48) // A standard height for buttons
                        .cornerRadius(12)
                    }
                }
                VStack(spacing: 10) {
                    FormButton(
                        button: ButtonConfig(id: "createAccount", type: .secondary, label: "Create Account", action: .createAccount),
                        isLoading: isLoading,
                        onTap: {
                            currentScreen = .createAccount
                        }
                    )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
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
    
    private func submitLogin() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        let data = [
            "username" : fieldValues["userId"],
            "password" : fieldValues["password"]
        ]
        
        do {
            let result: [String : String] = try await squareUpClient.login(data: data)
            guard let token = result["token"] else {
                print("Error parsing login response")
                return false
            }
            loginData = result
            KeychainHelper.save(token, service: "squareup.server", account: "squareUp")
        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
        }
        
        isLoading = false
        appState.isLoggedIn = true
        return true
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

