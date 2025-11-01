//
//  OTPField.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/31/25.
//

import SwiftUI

struct OTPField: View {
    @Binding var code: String
    var length: Int = 6
    var onComplete: ((String) -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text("Check your email for a verification code")
            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isActive(index) ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: isActive(index) ? 2 : 1)
                            .frame(width: 44, height: 56)

                        Text(character(at: index))
                            .font(.system(size: 24, weight: .semibold, design: .monospaced))
                            .accessibilityHidden(true)
                    }
                    .accessibilityElement()
                    .accessibilityLabel("Digit \(index + 1)")
                    .accessibilityValue(character(at: index).isEmpty ? "Empty" : character(at: index))
                }
            }
            
            Button("Paste Code") {
                if let pasted = UIPasteboard.general.string {
                    let filtered = pasted.filter { $0.isNumber }
                    code = String(filtered.prefix(length))
                    if code.count == length {
                        onComplete?(code)
                    }
                }
            }

            TextField("", text: Binding(
                get: { code },
                set: { newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    let trimmed = String(filtered.prefix(length))
                    if trimmed != code {
                        code = trimmed
                        if code.count == length {
                            onComplete?(code)
                        }
                    }
                })
            )
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode) // enables iOS OTP autofill
            .focused($isFocused)
            .frame(width: 0, height: 0)       // visually hidden but accessible
            .opacity(0.01)                    // keep focus/interaction
            .accessibilityLabel("Verification code input")
        }
        .onAppear {
            // Auto-focus when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .contentShape(Rectangle()) // tap anywhere to focus
        .onTapGesture { isFocused = true }
        .onChange(of: isFocused) { focused, oldFocused in
            // If the user finishes and leaves, keep only digits & length
            if !focused {
                code = String(code.filter { $0.isNumber }.prefix(length))
            }
        }
        .toolbar { // adds a "Done" button above number pad on iPhone
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isFocused = false }
            }
        }
    }

    private func character(at index: Int) -> String {
        if index < code.count {
            let i = code.index(code.startIndex, offsetBy: index)
            return String(code[i])
        }
        return ""
    }

    private func isActive(_ index: Int) -> Bool {
        // The "active" box is the next position to fill (or the last one when full)
        let activeIndex = min(code.count, length - 1)
        return index == activeIndex && isFocused
    }
}
