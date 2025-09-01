//
//  FormField.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/23/25.
//
import SwiftUI
import PhoneNumberKit

struct FormField: View {
    let field: FieldConfig
    @Binding var value: String
    let error: String?
    @FocusState private var isFocused: Bool
    
    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if field.type == .password {
                    SecureField(field.placeholder, text: $value)
                        .textFieldStyle(CustomTextFieldStyle(isFocused: isFocused, hasError: error != nil))
                        .focused($isFocused)
                        .textContentType(.password)
                } else if field.type == .email {
                    TextField(field.placeholder, text: $value)
                        .textFieldStyle(CustomTextFieldStyle(isFocused: isFocused, hasError: error != nil))
                        .focused($isFocused)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else if field.type == .firstName {
                    TextField(field.placeholder, text: $value)
                        .textFieldStyle(CustomTextFieldStyle(isFocused: isFocused, hasError: error != nil))
                        .focused($isFocused)
                        .textContentType(.givenName)
                } else if field.type == .lastName {
                    TextField(field.placeholder, text: $value)
                        .textFieldStyle(CustomTextFieldStyle(isFocused: isFocused, hasError: error != nil))
                        .focused($isFocused)
                        .textContentType(.familyName)
                } else if field.type == .verificationCode {
                    OTPField(code: $value)
                } else {
                    TextField(field.placeholder, text: $value)
                        .textFieldStyle(CustomTextFieldStyle(isFocused: isFocused, hasError: error != nil))
                        .focused($isFocused)
                        .autocapitalization(.none)
                }
            }
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
}
    
struct FieldConfig {
    let id: String
    let type: FieldType
    let placeholder: String
}

enum FieldType {
    case text
    case userId
    case email
    case phone
    case firstName
    case lastName
    case userName
    case password
    case verificationCode
}

struct CustomTextFieldStyle: TextFieldStyle {
    let isFocused: Bool
    let hasError: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .animation(.easeInOut(duration: 0.2), value: hasError)
            .accessibilityLabel("Text input field")
            .accessibilityHint(hasError ? "Field has an error" : "Field is ready for input")
    }
    
    private var borderColor: Color {
        if hasError {
            return .red
        } else if isFocused {
            return Color("PrimaryColor")
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        if isFocused || hasError {
            return 2
        } else {
            return 1
        }
    }
}

