//
//  SquareUpApp.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/23/25.
//

import SwiftUI

@main
struct SquareUpApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .toast(message: (appState.errorMessage ?? ""), isPresented: $appState.showErrorToast, duration: 3)
                .toastSuccess(message: (appState.successMessage ?? ""), isPresented: $appState.showSuccessToast, duration: 3)
                .task {
                    if let _ = TokenManager.shared.accessToken {
                        Task {
                            do {
                                let response = try await SquareUpClient.shared.verifyToken()
                                appState.isLoggedIn = response.0
                                appState.userInfo = response.1
                            } catch {
                                showError()
                            }
                            appState.showSplash = false
                        }
                    } else {
                        appState.showSplash = false
                    }
                }
        }
    }
    private func showError() {
        appState.errorMessage = "Something went wrong. Please try again later."
        appState.showErrorToast = true
        appState.currentScreenGroup = .login
    }
}

enum toastType {
    case error, success
}

extension View {
    func toast(message: String, isPresented: Binding<Bool>, duration: Double = 2) -> some View {
        self.modifier(AutoDismissToastError(message: message, isPresented: isPresented, duration: duration))
    }
    func toastSuccess(message: String, isPresented: Binding<Bool>, duration: Double = 2) -> some View {
        self.modifier(AutoDismissToastSuccess(message: message, isPresented: isPresented, duration: duration))
    }
}

struct AutoDismissToastError: ViewModifier {
    let message: String
    @Binding var isPresented: Bool
    let duration: Double

    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                VStack {
                    Text(message)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding(.top, 40)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: isPresented)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation { isPresented = false }
                    }
                }
            }
        }
    }
}

struct AutoDismissToastSuccess: ViewModifier {
    let message: String
    @Binding var isPresented: Bool
    let duration: Double

    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                VStack {
                    Text(message)
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding(.top, 40)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: isPresented)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation { isPresented = false }
                    }
                }
            }
        }
    }
}
