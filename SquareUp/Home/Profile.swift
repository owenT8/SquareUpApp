//
//  Profile.swift
//  SquareUp
//
//  Created by Owen  Taylor on 9/6/25.
//

import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var items: [String: Any] = [:]
    @Published var isLoading: Bool = false

    init() {
        fetchData()
    }

    func fetchData() {
        isLoading = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            Task {
                self.items = try await SquareUpClient.shared.verifyToken().1
            }
            self.isLoading = false
        }
    }

    func refresh() {
        fetchData() // same function, could call API again
    }
}

struct Profile: View {
    @StateObject var profileViewModel: ProfileViewModel = .init()
    
    @EnvironmentObject var appState: AppState
    var body: some View {
        VStack{
            ScrollView {
                ForEach(Array(profileViewModel.items.keys), id: \.self) { key in
                    Text("\(key): \(profileViewModel.items[key] ?? "nil")")
                        .padding(.vertical , 8)
                }
                Button("Logout", action: {TokenManager.shared.clearTokens(); appState.currentScreenGroup = .login; appState.isLoggedIn = false})
            }
            .padding(.top, 60)
            .refreshable {
                profileViewModel.refresh()
            }
        }
        
        if profileViewModel.isLoading {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }
}

struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        Profile()
    }
}
