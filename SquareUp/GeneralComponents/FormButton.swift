//
//  FormButton.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/23/25.
//
import SwiftUI

struct FormButton: View {
    let button: ButtonConfig
    let isLoading: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            onTap()
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: buttonForeground))
                        .scaleEffect(0.8)
                } else {
                    Spacer()
                    Text(button.label)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .padding()
            .background(buttonBackground)
            .foregroundColor(buttonForeground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(buttonBorder, lineWidth: button.type == .secondary ? 1 : 0)
            )
            .shadow(color: button.type == .primary ? Color("PrimaryColor").opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .disabled(isLoading)
        }
        .disabled(button.type == .link || isLoading)
        .accessibilityLabel(button.label)
        .accessibilityHint(button.type == .primary ? "Primary action button" : "Secondary action button")
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var buttonBackground: Color {
        switch button.type {
        case .primary:
            return Color("ButtonColor")
        case .secondary:
            return Color.clear
        case .link:
            return Color.clear
        }
    }
    
    private var buttonForeground: Color {
        switch button.type {
        case .primary:
            return Color("ButtonTextColor")
        case .secondary:
            return Color("ButtonColor")
        case .link:
            return Color("PrimaryColor")
        }
    }
    
    private var buttonBorder: Color {
        switch button.type {
        case .primary:
            return Color.clear
        case .secondary:
            return Color("ButtonColor")
        case .link:
            return Color.clear
        }
    }
}

struct ButtonConfig {
    let id: String
    let type: ButtonType
    let label: String
    let action: ButtonAction
}

enum ButtonType {
    case primary
    case secondary
    case link
}

enum ButtonAction {
    case submitLogin
    case forgotPassword
    case createAccount
    case goToEmailSignup
    case goToPhoneSignup
    case goToPasswordSignup
    case goToVerificationCode
    case submitSignup
    case goToLogin
}
