//
//  ForgotPasswordForm.swift
//  SquareUp
//
//  Created by Owen  Taylor on 9/5/25.
//
import SwiftUI

struct UserIdForm: View {
    @Binding var fieldValues: [String: String]
    @Binding var fieldErrors: [String: String]
    @Binding var currentForgotPasswordScreen: ForgotPasswordScreen
    
    @EnvironmentObject var appState: AppState
    
    @State var isLoading: Bool = false
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: {
                        if (fieldValues["userId"] != nil) {
                            fieldValues["userId"] = nil
                        }
                        currentForgotPasswordScreen = .exit
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
                        }
                        .padding(.horizontal, 30)
                        
                        // Buttons
                        FormButton(
                            button: ButtonConfig(id: "submitUserId", type: .primary, label: "Send Verification Code", action: .submitPasswordReset),
                            isLoading: isLoading,
                            onTap: {
                                if validateForm(fieldValues: fieldValues, fieldErrors: &fieldErrors) {
                                    Task {
                                        do {
                                            isLoading = true
                                            let response = try await SquareUpClient.shared.sendOtpCode(data: fieldValues)
                                            isLoading = false
                                            if response == 200 {
                                                currentForgotPasswordScreen = .newPassword
                                            } else {
                                                showError(message: "Error sending verification. Please try again later.")
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

