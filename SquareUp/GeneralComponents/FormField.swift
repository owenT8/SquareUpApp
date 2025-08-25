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
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else if field.type == .phone {
                    TextField(field.placeholder, text: $value)
                        .textFieldStyle(CustomTextFieldStyle(isFocused: isFocused, hasError: error != nil))
                        .focused($isFocused)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
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
                    ForEach(0..<6, id: \.self) { index in
                        TextField("", text: $code[index])
                            .textContentType(.oneTimeCode)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 45, height: 55)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                            .focused($focusedIndex, equals: index)
                            .onChange(of: code[index]) { newValue, oldValue in
                                let filtered = newValue.filter { $0.isNumber }
                                
                                if filtered.count > 1 {
                                    for (i, char) in filtered.prefix(6).enumerated() {
                                        code[i] = String(char)
                                    }
                                    
                                    // Focus next empty box
                                    if let nextIndex = code.firstIndex(where: { $0.isEmpty }) {
                                        focusedIndex = nextIndex
                                    } else {
                                        focusedIndex = 5
                                    }
                                } else {
                                    // Normal typing
                                    code[index] = filtered
                                    
                                    if !filtered.isEmpty && index < 5 {
                                        focusedIndex = index + 1
                                    }
                                    
                                    if filtered.isEmpty && index > 0 {
                                        focusedIndex = index - 1
                                    }
                                }
                                
                                // Update joined code value
                                value = code.joined()
                            }
                    }
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
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .foregroundColor(Color("TextColor"))
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

