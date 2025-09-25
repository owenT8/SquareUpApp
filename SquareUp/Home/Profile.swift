//
//  Profile.swift
//  SquareUp
//
//  Created by Owen  Taylor on 9/6/25.
//

import SwiftUI

struct Item: Identifiable {
    let id = UUID()
    let firstName: String
    let lastName: String
    
    var initials: String {
        let firstInitial = firstName.first.map { String($0) } ?? ""
        let lastInitial = lastName.first.map { String($0) } ?? ""
        return firstInitial + lastInitial
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

let sampleItems: [Item] = [
    Item(firstName: "Emily", lastName: "Clark"),
    Item(firstName: "Michael", lastName: "Brown"),
    Item(firstName: "Sophia", lastName: "Davis"),
    Item(firstName: "James", lastName: "Wilson"),
    Item(firstName: "Olivia", lastName: "Martinez"),
    Item(firstName: "Liam", lastName: "Taylor"),
    Item(firstName: "Ava", lastName: "Anderson"),
]

class ProfileViewModel: ObservableObject {
    @Published var items: [String: Any] = [:]
    @Published var isLoading: Bool = false
    @Published var searchQuery: String = ""
    @Published var searchResults: [String] = []
    @Published var searching: Bool = false
    @Published var addFriendLoading: Bool = false
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var friends: [String] = []
    private var searchTask: Task<Void, Never>? = nil

    init() {
        if let savedUsername = UserDefaults.standard.string(forKey: "profile_username") {
            username = savedUsername
        }
        if let savedEmail = UserDefaults.standard.string(forKey: "profile_email") {
            email = savedEmail
        }
        fetchData()
        fetchFriends()
    }

    func fetchData() {
        isLoading = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            Task {
                do {
                    let (_, data) = try await SquareUpClient.shared.verifyToken()
                    await MainActor.run {
                        self.items = data
                        if let username = data["username"] as? String {
                            self.username = username
                            UserDefaults.standard.set(username, forKey: "profile_username")
                        }
                        if let email = data["email"] as? String {
                            self.email = email
                            UserDefaults.standard.set(email, forKey: "profile_email")
                        }
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    func fetchFriends() {
        Task {
            do {
                let friendsList = try await SquareUpClient.shared.fetchFriends()
                await MainActor.run {
                    self.friends = friendsList
                }
            } catch {
                await MainActor.run {
                    self.friends = []
                }
            }
        }
    }

    func refresh() {
        fetchData() // same function, could call API again
        fetchFriends()
    }

    @MainActor
    func updateSearchQuery(_ query: String) {
        searchQuery = query
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        searchTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            } catch { /* ignore cancellation */ }
            guard !Task.isCancelled else { return }
            await self?.performSearch(query: trimmed)
        }
    }

    @MainActor
    func performSearch(query: String) async {
        searching = true
        defer { searching = false }
        do {
            let results = try await SquareUpClient.shared.searchUsernames(query: query)
            self.searchResults = results
        } catch {
            self.searchResults = []
        }
    }

    @MainActor
    func addFriend(username: String, appState: AppState) async {
        addFriendLoading = true
        defer { addFriendLoading = false }
        do {
            let ok = try await SquareUpClient.shared.addFriend(username: username)
            if ok {
                appState.successMessage = "Friend request sent to \(username)"
                appState.showSuccessToast = true
            } else {
                appState.errorMessage = "Could not add \(username). Please try again."
                appState.showErrorToast = true
            }
        } catch {
            appState.errorMessage = "Something went wrong. Please try again later."
            appState.showErrorToast = true
        }
    }
}

struct Profile: View {
    @StateObject var profileViewModel: ProfileViewModel = .init()
    @State private var showFriendsSheet: Bool = false

    @EnvironmentObject var appState: AppState
    var body: some View {
        ZStack {
            VStack {
                // Profile Avatar
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundColor(.accentColor)
                    .background(Circle().fill(Color(.systemBackground)).shadow(radius: 8))
                    .padding(.top, 32)

                // Username
                Text(profileViewModel.username.isEmpty ? "Username" : profileViewModel.username)
                    .font(.title2.bold())
                    .padding(.top, 8)
                
                // Email
                Text(profileViewModel.email.isEmpty ? "email@example.com" : profileViewModel.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // New Top Friends Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Friends")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(sampleItems.prefix(5)) { friend in
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.2))
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Text(friend.initials)
                                                .font(.title3.bold())
                                                .foregroundColor(.accentColor)
                                        )
                                    Text(friend.fullName)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .frame(width: 70)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel(friend.fullName)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 30)
                
                // My Friends Section
                Button {
                    showFriendsSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Text("My Friends")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                let displayedFriends = profileViewModel.friends.prefix(5)
                                ForEach(Array(displayedFriends), id: \.self) { friend in
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text(friend.prefix(1).uppercased())
                                                .font(.headline)
                                                .foregroundColor(.accentColor)
                                        )
                                        .accessibilityLabel(friend)
                                }
                                if profileViewModel.friends.count > 5 {
                                    Text("+\(profileViewModel.friends.count - 5) more")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 12)
                .padding(.bottom, 20)
                .padding(.horizontal, 30)

                ScrollView {
                    VStack(spacing: 12) {
                        Spacer(minLength: 40)
                        Button("Logout") {
                            TokenManager.shared.clearTokens()
                            appState.currentScreenGroup = .login
                            appState.isLoggedIn = false
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                        .padding(.vertical)
                    }
                }
                .refreshable { profileViewModel.refresh() }
            }
            .sheet(isPresented: $showFriendsSheet) {
                FriendsListSheet(vm: profileViewModel)
                    .environmentObject(appState)
            }
            
            if profileViewModel.isLoading || profileViewModel.addFriendLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}

struct FriendsListSheet: View {
    @ObservedObject var vm: ProfileViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showAddFriendSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if vm.friends.isEmpty {
                    Spacer()
                    Text("You have no friends yet.")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(vm.friends, id: \.self) { friend in
                        Text(friend)
                    }
                    .listStyle(.plain)
                }
                
                Button {
                    showAddFriendSheet = true
                } label: {
                    Label("Add Friend", systemImage: "person.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddFriendSheet) {
                AddFriendSheet(vm: vm)
                    .environmentObject(appState)
            }
        }
    }
}

struct AddFriendSheet: View {
    @ObservedObject var vm: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search username", text: Binding(
                        get: { vm.searchQuery },
                        set: { vm.updateSearchQuery($0) }
                    ))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)

                if vm.searching {
                    ProgressView("Searching…")
                        .padding(.top, 8)
                }

                List(vm.searchResults, id: \.self) { username in
                    Button {
                        Task { await vm.addFriend(username: username, appState: appState); dismiss() }
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.accentColor)
                            Text(username)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Add Friend")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        Profile()
    }
}
