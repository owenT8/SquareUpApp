//
//  Home.swift
//  SquareUp
//
//  Created by Owen Taylor on 9/6/25.
//

import SwiftUI

struct Home: View {
    @State private var selection = 0
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                SocialFeedView(appState: appState)
                    .tag(0)
                TransactionsView(appState: appState)
                    .tag(1)
                Profile()
                    .tag(2)
            }
            // Swipe horizontally between pages
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selection)
            .ignoresSafeArea(.all)
            
            VStack {
                Spacer()
                FloatingTabBar(selection: $selection)
                    .padding(.bottom, 30)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .ignoresSafeArea(.all)
    }
}

struct FloatingTabBar: View {
    @Binding var selection: Int
    
    var body: some View {
        HStack(spacing: 40) {
            TabBarButton(icon: "house.fill", index: 0, selection: $selection)
            TabBarButton(icon: "dollarsign.circle.fill", index: 1, selection: $selection)
            TabBarButton(icon: "person.crop.circle.fill", index: 2, selection: $selection)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selection)
    }
}

struct TabBarButton: View {
    let icon: String
    let index: Int
    @Binding var selection: Int
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selection = index
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(selection == index ? Color("PrimaryColor") : .gray)
                    .scaleEffect(selection == index ? 1.2 : 1.0)
                    .shadow(color: selection == index ? .accentColor.opacity(0.3) : .clear, radius: 6)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    Home()
}
