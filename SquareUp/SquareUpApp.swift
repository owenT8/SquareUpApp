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
    
    init() {
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .toast(message: (appState.errorMessage ?? ""), isPresented: $appState.showErrorToast, duration: 3)
                .task {
                    if let _ = TokenManager.shared.accessToken {
                        Task {
                            do {
                                appState.isLoggedIn = try await SquareUpClient.shared.verifyToken()
                                print(appState.isLoggedIn)
                            } catch {
                                print("Token verification failed: \(error)")
                            }
                            appState.showSplash = false
                        }
                    } else {
                        appState.showSplash = false
                    }
                }
        }
    }
}

extension View {
    func toast(message: String, isPresented: Binding<Bool>, duration: Double = 2) -> some View {
        self.modifier(AutoDismissToast(message: message, isPresented: isPresented, duration: duration))
    }
}

struct AutoDismissToast: ViewModifier {
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
