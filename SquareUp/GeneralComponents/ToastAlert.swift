//
//  ToastAlert.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/31/25.
//
import SwiftUI

struct ToastAlert: View {
    let message: String

    var body: some View {
        Text(message)
            .padding()
            .background(Color.red.opacity(0.9))
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding(.horizontal, 20)
    }
}
