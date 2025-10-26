//
//  OTPForm.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/31/25.
//
import SwiftUI

struct OTPForm: View {
    @Binding var fieldValues: [String : String]
    @Binding var fieldErrors: [String : String]
    @Binding var currentLoginScreen: LoginScreen
    
    @State var isLoading: Bool = false
            
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: {
                        if (fieldValues["otp"] != nil) {
                            fieldValues["otp"] = nil
                        }
                        currentLoginScreen = .login
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 15) {
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
                        .padding(.top, 5)
                        
                        Spacer()
           
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
                        }
                        .padding(.horizontal, 30)
                                              
                        VStack(spacing: 20) {
                            FormButton(button: ButtonConfig(id: "verify", type: .primary, label: "Verify", action: .goToHome), isLoading: isLoading, onTap: {
                                Task {
                                    do {
                                        isLoading = true
                                        let response = try await SquareUpClient.shared.login(data: fieldValues)
                                        isLoading = false
                                        if response == 200 {
                                            fieldValues = [:]
                                            
                                            appState.isLoggedIn = true
                                            appState.currentScreenGroup = .main
                                        } else {
                                            showError(message: "Invalid verification code. Please try again.")
                                        }
                                    } catch {
                                        showError(message: "Something went wrong. Please try again later.")
                                    }
                                }
                            })
                            .padding(.horizontal, 30)
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
    
    private func showError(message: String) {
        appState.errorMessage = message
        appState.showErrorToast = true
        appState.currentScreenGroup = .login
    }
}
