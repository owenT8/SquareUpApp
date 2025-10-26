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

class ProfileViewModel: ObservableObject {
    @Published var items: [String: Any] = [:]
    @Published var isLoading: Bool = false
    @Published var searchQuery: String = ""
    @Published var searchResults: [Friend] = []
    @Published var searching: Bool = false
    @Published var addFriendLoading: Bool = false
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var user_id: String = ""
    @Published var friends: [Friend] = []
    @Published var incomingFriendRequests: [Friend] = []
    @Published var outgoingFriendRequests: [Friend] = []
    
    private var searchTask: Task<Void, Never>? = nil

    init() {
        if let savedUsername = UserDefaults.standard.string(forKey: "profile_username") {
            username = savedUsername
        }
        if let savedEmail = UserDefaults.standard.string(forKey: "profile_email") {
            email = savedEmail
        }
        if let savedUserid = UserDefaults.standard.string(forKey: "profile_user_id") {
            user_id = savedUserid
        }
        fetchFriends()
        fetchFriendRequests()
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
    
    func fetchFriendRequests() {
        Task {
            do {
                let (incomingRequestList, outgoingRequestList) = try await SquareUpClient.shared.fetchFriendRequests()
                await MainActor.run {
                    self.incomingFriendRequests = incomingRequestList
                    self.outgoingFriendRequests = outgoingRequestList
                }
            } catch {
                await MainActor.run {
                    self.incomingFriendRequests = []
                    self.outgoingFriendRequests = []
                }
            }
        }
    }
    
    func fetchFriendsAsync() async throws {
        let friendsList = try await SquareUpClient.shared.fetchFriends()
        let (incomingRequestList, outgoingRequestList) = try await SquareUpClient.shared.fetchFriendRequests()
        await MainActor.run {
            self.friends = friendsList
            self.incomingFriendRequests = incomingRequestList
            self.outgoingFriendRequests = outgoingRequestList
        }
    }

    func refresh() {
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
                fetchFriendRequests()
            } else {
                appState.errorMessage = "Could not add user as friend. Please try again."
                appState.showErrorToast = true
            }
        } catch {
            appState.errorMessage = "Something went wrong. Please try again later."
            appState.showErrorToast = true
        }
    }
    
    @MainActor
    func acceptFriendRequest(username: String, appState: AppState) async {
        addFriendLoading = true
        defer { addFriendLoading = false }
        do {
            let ok = try await SquareUpClient.shared.acceptFriendRequest(forUserId: username)
            if ok {
                fetchFriends()
                fetchFriendRequests()
            } else {
                appState.errorMessage = "Could not add user as friend. Please try again."
                appState.showErrorToast = true
            }
        } catch {
            appState.errorMessage = "Something went wrong. Please try again later."
            appState.showErrorToast = true
        }
    }
    
    @MainActor
    func rejectFriendRequest(username: String, appState: AppState) async {
        addFriendLoading = true
        defer { addFriendLoading = false }
        do {
            let ok = try await SquareUpClient.shared.rejectFriendRequest(forUserId: username)
            if ok {
                fetchFriends()
                fetchFriendRequests()
            } else {
                appState.errorMessage = "Could not reject user. Please try again."
                appState.showErrorToast = true
            }
        } catch {
            appState.errorMessage = "Something went wrong. Please try again later."
            appState.showErrorToast = true
        }
    }
    
    @MainActor
    func removeOutgoingFriendRequest(username: String, appState: AppState) async {
        addFriendLoading = true
        defer { addFriendLoading = false }
        do {
            let ok = try await SquareUpClient.shared.removeOutgoingFriendRequest(forUserId: username)
            if ok {
                fetchFriends()
                fetchFriendRequests()
            } else {
                appState.errorMessage = "Could not reject user. Please try again."
                appState.showErrorToast = true
            }
        } catch {
            appState.errorMessage = "Something went wrong. Please try again later."
            appState.showErrorToast = true
        }
    }
    
    @MainActor
    func removeFriend(username: String, appState: AppState) async {
        addFriendLoading = true
        defer { addFriendLoading = false }
        do {
            let ok = try await SquareUpClient.shared.removeFriend(username: username)
            if ok {
                fetchFriends()
            } else {
                appState.errorMessage = "Could not unfriend user. Please try again."
                appState.showErrorToast = true
            }
        } catch {
            appState.errorMessage = "Something went wrong. Please try again later."
            appState.showErrorToast = true
        }
    }
    
}

enum ProfileSheet: Identifiable {
    case friends
    case incomingFriendRequests
    case outgoingFriendRequests
    
    var id: Self { self }
}

struct Profile: View {
    @StateObject var profileViewModel: ProfileViewModel = .init()
    @State var currentSheet: ProfileSheet? = nil
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Wrap content in ScrollView so refreshable works
                // Profile Avatar
                VStack {
                    VStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .foregroundColor(Color("PrimaryColor"))
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
                    }
                    ScrollView {
                        VStack(spacing: 8) {
                            // My Friends Section
                            // Friends Button
                            FriendListButton(
                                title: "My Friends",
                                friends: profileViewModel.friends,
                                onTap: { currentSheet = .friends }
                            )
                            
                            // Incoming Friend Requests Button
                            FriendListButton(
                                title: "Friend Requests",
                                friends: profileViewModel.incomingFriendRequests,
                                onTap: { currentSheet = .incomingFriendRequests }
                            )
                            
                            // Outgoing Friend Requests Button
                            FriendListButton(
                                title: "Sent Requests",
                                friends: profileViewModel.outgoingFriendRequests,
                                onTap: { currentSheet = .outgoingFriendRequests }
                            )
                            
                            Spacer(minLength: 50)
                        }
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity)
                        .sheet(item: $currentSheet) { sheet in
                            switch sheet {
                            case .friends:
                                FriendsListSheet(vm: profileViewModel)
                                    .environmentObject(appState)
                            case .incomingFriendRequests:
                                IncomingFriendRequestsSheet(vm: profileViewModel)
                                    .environmentObject(appState)
                            case .outgoingFriendRequests:
                                OutgoingFriendRequestsSheet(vm: profileViewModel)
                                    .environmentObject(appState)
                            }
                        }
                    }
                    .refreshable {
                        do {
                            try await profileViewModel.fetchFriendsAsync()
                        } catch {
                            appState.errorMessage = "Failed to refresh"
                            appState.showErrorToast = true
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                TokenManager.shared.clearTokens()
                                appState.currentScreenGroup = .login
                                appState.isLoggedIn = false
                            } label: {
                                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .imageScale(.large)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            if profileViewModel.isLoading || profileViewModel.addFriendLoading {
                Color.black.opacity(0.3) // optional dim background
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                    .zIndex(1) // make sure it's on top
            }
        }
    }
}

struct FriendListButton: View {
    let title: String
    let friends: [Friend]
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Title with fixed width for alignment
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Friend avatars or count
                HStack(spacing: 8) {
                    if friends.isEmpty {
                        Text("0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        let displayedFriends = friends.prefix(3)
                        ForEach(displayedFriends, id: \.id) { friend in
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("PrimaryColor").opacity(0.9),
                                                Color("PrimaryColor").opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Text(friend.firstName.prefix(1).uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        if friends.count > 3 {
                            Text("+\(friends.count - 3)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 56) // Fixed height for consistency
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
}

struct FriendsListSheet: View {
    @ObservedObject var vm: ProfileViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showAddFriendSheet: Bool = false
    @State private var friendToRemove: Friend? = nil
    
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
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("PrimaryColor").opacity(0.9),
                                                Color("PrimaryColor").opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                                Text(friend.firstName.prefix(1).uppercased() + friend.lastName.prefix(1).uppercased())
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("@\(friend.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            HStack {
                                Button {
                                    friendToRemove = friend // Set the friend to show confirmation
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.red)
                                        )
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .listRowSeparator(.hidden)
                    .listStyle(.plain)
                }
                
                Button {
                    showAddFriendSheet = true
                } label: {
                    Label("Add Friend", systemImage: "person.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("PrimaryColor"))
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
            .confirmationDialog(
                "Are you sure you want to unfriend this user?",
                isPresented: Binding(
                    get: { friendToRemove != nil },
                    set: { if !$0 { friendToRemove = nil } }
                ),
                presenting: friendToRemove
            ) { friend in
                Button("Unfriend", role: .destructive) {
                    Task {
                        await vm.removeFriend(username: friend.id, appState: appState)
                        friendToRemove = nil
                        dismiss()
                    }
                }
                Button("Don't unfriend", role: .cancel) {
                    friendToRemove = nil
                }
            } message: { friend in
                Text("Are you sure you want to unfriend \(friend.name)?")
            }
            .sheet(isPresented: $showAddFriendSheet) {
                AddFriendSheet(vm: vm)
                    .environmentObject(appState)
            }
        }
        .listRowSeparator(.hidden)
    }
}

struct IncomingFriendRequestsSheet: View {
    @ObservedObject var vm: ProfileViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if vm.incomingFriendRequests.isEmpty {
                    Spacer()
                    Text("You have no friend requests yet.")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(vm.incomingFriendRequests, id: \.self) { friend in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("PrimaryColor").opacity(0.9),
                                                Color("PrimaryColor").opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                                Text(friend.firstName.prefix(1).uppercased() + friend.lastName.prefix(1).uppercased())
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("@\(friend.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            HStack {
                                Button {
                                    Task {
                                        await vm.acceptFriendRequest(username: friend.id, appState: appState)
                                        dismiss()
                                    }
                                } label: {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.green)
                                        )
                                }
                                
                                Button {
                                    Task {
                                        await vm.rejectFriendRequest(username: friend.id, appState: appState)
                                        dismiss()
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.red)
                                        )
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .listRowSeparator(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Friend Requests")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .listRowSeparator(.hidden)
    }
}

struct OutgoingFriendRequestsSheet: View {
    @ObservedObject var vm: ProfileViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if vm.outgoingFriendRequests.isEmpty {
                    Spacer()
                    Text("You haven't sent any friend requests yet.")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(vm.outgoingFriendRequests, id: \.self) { friend in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("PrimaryColor").opacity(0.9),
                                                Color("PrimaryColor").opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                                Text(friend.firstName.prefix(1).uppercased() + friend.lastName.prefix(1).uppercased())
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("@\(friend.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            HStack {
                                Button {
                                    Task {
                                        await vm.removeOutgoingFriendRequest(username: friend.id, appState: appState)
                                        dismiss()
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.red)
                                        )
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .listRowSeparator(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Pending Requests")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .listRowSeparator(.hidden)
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

                List(vm.searchResults, id: \.id) { user in
                    HStack {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color("PrimaryColor").opacity(0.9),
                                            Color("PrimaryColor").opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                            Text(user.firstName.prefix(1).uppercased() + user.lastName.prefix(1).uppercased())
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack {
                            Button {
                                Task {
                                    await vm.addFriend(username: user.id, appState: appState)
                                    vm.searchQuery = ""
                                    dismiss()
                                }
                            } label: {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color("PrimaryColor"))
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .listStyle(.plain)
            }
            .navigationTitle("Send Friend Request")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    Profile()
}
