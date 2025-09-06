//
//  NewPasswordForm.swift
//  SquareUp
//
//  Created by Owen  Taylor on 9/5/25.
//
import SwiftUI

struct NewPasswordForm: View {
    @Binding var fieldValues: [String: String]
    @Binding var fieldErrors: [String: String]
    @Binding var currentForgotPasswordScreen: ForgotPasswordScreen
    
    @EnvironmentObject var appState: AppState
    
    @State var isLoading: Bool = false
    var body: some View {
        ZStack {
            
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: {
                        if (fieldValues["otp"] != nil) {
                            fieldValues["otp"] = nil
                        }
                        if (fieldValues["password"] != nil) {
                            fieldValues["password"] = nil
                        }
                        currentForgotPasswordScreen = .userId
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
                        .padding(.top, 10)
                        
                        Spacer()
                        // Form Fields
                        VStack(spacing: 20) {
                            OTPField(code: Binding(
                                get: {
                                    fieldValues["otp"] ?? ""
                                },
                                set: {
                                    fieldValues["otp"] = $0
                                    // Clear error when user starts typing
                                    if fieldErrors["otp"] != nil {
                                        fieldErrors["otp"] = nil
                                    }
                                }
                            ))
                            FormField(
                                field: FieldConfig(id: "password", type: .password, placeholder: "New Password"),
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
                            button: ButtonConfig(id: "submitPasswordReset", type: .primary, label: "Submit Password Reset", action: .submitPasswordReset),
                            isLoading: isLoading,
                            onTap: {
                                if validateForm(fieldValues: fieldValues, fieldErrors: &fieldErrors) {
                                    Task {
                                        do {
                                            isLoading = true
                                            let response = try await SquareUpClient.shared.resetPassword(data: fieldValues)
                                            isLoading = false
                                            if response {
                                                showSuccess(message: "Password reset successful. Please login with your new password.")
                                                currentForgotPasswordScreen = .exit
                                            } else {
                                                showError(message: "Reset password failed. Please try again later.")
                                            }
                                        } catch {
                                            showError(message: "Something went wrong. Please try again later.")
                                        }
                                    }
                                }
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
        
        if fieldValues["password"] == nil || !(fieldValues["password"]?.isValidPassword() ?? false) {
            fieldErrors["password"] = "Password have at least 6 characters, one digit, and one special character"
            isValid = false
        }
        if fieldValues["otp"] == nil || (fieldValues["otp"]?.count ?? 0) != 6 {
            fieldErrors["otp"] = "This field is required"
            isValid = false
        }
        
        return isValid
    }
    
    private func showError(message: String) {
        appState.errorMessage = message
        appState.showErrorToast = true
        appState.currentScreenGroup = .login
    }
    private func showSuccess(message: String) {
        appState.successMessage = message
        appState.showSuccessToast = true
        appState.currentScreenGroup = .login
    }
}
