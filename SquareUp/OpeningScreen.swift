//
//  OpeningScreen.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/23/25.
//

import SwiftUI

struct OpeningScreen: View {
    let onNext: () -> Void
    
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var logoRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo Container
                ZStack {
                    // Background circle
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // Logo
                    Image("SquareUpLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(logoRotation))
                }
                
                // App Name
                Text(Constants.appName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .opacity(textOpacity)
  
                Spacer()
            }
        }
        .onAppear {
            // Logo animation
            withAnimation(.easeOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Logo rotation
            withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
                logoRotation = 360
            }
            
            // Text animation
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                textOpacity = 1.0
            }
            
            // Auto-navigate after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    onNext()
                }
            }
        }
    }
}

#Preview {
    OpeningScreen(
        onNext: {}
    )
}
