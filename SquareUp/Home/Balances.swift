//
//  Balances.swift
//  SquareUp
//
//  Created by Owen  Taylor on 9/6/25.
//

import SwiftUI

@MainActor
class TransactionViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var transactions: [Transaction] = []
    @Published var transactionFriends: [Friend] = []
    @Published var allFriends: [Friend] = []
    @Published var showLastDeleteConfirmation = false
    @Published var pendingDeleteTransaction: Transaction?
    var pendingDeleteCancelCallback: (() -> Void)?
    
    @Published var myself: Friend = Friend(
        id: UserDefaults.standard.string(forKey: "profile_user_id")!,
        username: UserDefaults.standard.string(forKey: "profile_username")!,
        firstName: UserDefaults.standard.string(forKey: "profile_first_name")!,
        lastName: UserDefaults.standard.string(forKey: "profile_last_name")!,
        name: UserDefaults.standard.string(forKey: "profile_full_name")!
    )
    
    private var appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func fetchTransactions() async {
        do {
            let (transactions_data, user_details_data) = try await SquareUpClient.shared.fetchTransactions()
            let all_friends_data = try await SquareUpClient.shared.fetchFriends()
            transactions = transactions_data
            transactionFriends = user_details_data
            allFriends = all_friends_data
        } catch {
            appState.showErrorToast = true
            appState.errorMessage = "Failed to fetch transactions."
        }
    }
    
    func voteToDelete(transaction: Transaction, userId: String, onCancel: @escaping () -> Void = {}) async {
        // Check if this is the last person to vote
        let currentVotes = transaction.votesToDelete?.count ?? 0
        let totalUsers = transaction.userIds.count
        
        if currentVotes == totalUsers - 1 {
            // This is the last person - show confirmation
            pendingDeleteTransaction = transaction
            pendingDeleteCancelCallback = onCancel
            showLastDeleteConfirmation = true
        } else {
            // Not the last person - proceed normally
            await performVoteToDelete(transaction: transaction, userId: userId)
        }
    }
    // Separated logic for actual API call
    func performVoteToDelete(transaction: Transaction, userId: String) async {
        let body: [String: Any] = [
            "transaction_id": transaction.id
        ]
        do {
            try await SquareUpClient.shared.POST(
                endpoint: "/api/add-vote-to-delete-transaction",
                body: body
            )
            // Update votesToDelete locally
            if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
                if !(transactions[index].votesToDelete ?? []).contains(userId) {
                    if transactions[index].votesToDelete == nil {
                        transactions[index].votesToDelete = [userId]
                    } else {
                        transactions[index].votesToDelete!.append(userId)
                    }
                }
            }
            await fetchTransactions()
        } catch {
            // Handle error silently or optionally notify
        }
    }
    
    func unvoteToDelete(transaction: Transaction, userId: String) async {
        let body: [String: Any] = [
            "transaction_id": transaction.id
        ]
        do {
            try await SquareUpClient.shared.POST(
                endpoint: "/api/remove-vote-to-delete-transaction",
                body: body
            )
            // Update votesToDelete locally
            if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
                if var votes = transactions[index].votesToDelete, let idx = votes.firstIndex(of: userId) {
                    votes.remove(at: idx)
                    transactions[index].votesToDelete = votes
                }
            }
        } catch {
            // Handle error silently or optionally notify
        }
    }
}

struct TransactionsView: View {
    @StateObject var vm: TransactionViewModel
    @EnvironmentObject var appState: AppState
    @State private var showCreateTransaction = false
    
    init(appState: AppState) {
        _vm = StateObject(wrappedValue: TransactionViewModel(appState: appState))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(Color("BackgroundColor"))
                    .ignoresSafeArea()
                Group {
                    if vm.isLoading && vm.transactions.isEmpty {
                        ProgressView("Loading transactions...")
                    } else if !vm.transactions.isEmpty {
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(vm.transactions) { transaction in
                                    TransactionCard(transaction: transaction, vm: vm)
                                        .listRowInsets(EdgeInsets())
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .padding(.bottom, 14)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                        .refreshable {
                            await vm.fetchTransactions()
                        }
                    } else {
                        ContentUnavailableView(
                            "No Transactions",
                            systemImage: "tray",
                            description: Text("Pull down to refresh")
                        )
                    }
                }
                .sheet(isPresented: $showCreateTransaction) {
                    CreateTransactionView(vm: vm)
                }
            }
            .navigationTitle("Groups")
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateTransaction = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
            }
            .alert("Confirm Delete", isPresented: $vm.showLastDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    vm.pendingDeleteCancelCallback?()
                    vm.pendingDeleteTransaction = nil
                    vm.pendingDeleteCancelCallback = nil
                }
                Button("Delete", role: .destructive) {
                    if let transaction = vm.pendingDeleteTransaction,
                       let userId = UserDefaults.standard.string(forKey: "profile_user_id") {
                        Task {
                            await vm.performVoteToDelete(transaction: transaction, userId: userId)
                        }
                    }
                    vm.pendingDeleteTransaction = nil
                    vm.pendingDeleteCancelCallback = nil
                }
            } message: {
                Text("You are the last person to Square Up, are you sure you want to delete this balance?")
            }
        }
        .scenePadding(.horizontal)
        .onAppear {
            if vm.transactions.isEmpty && !vm.isLoading {
                Task {
                    await vm.fetchTransactions()
                }
            }
        }
    }
}


struct CreateTransactionView: View {
    @ObservedObject var vm: TransactionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var transactionName = ""
    @State private var selectedUserIds: Set<String> = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    TextField("Name (e.g., 'Trip to Taos')", text: $transactionName)
                }
                
                Section {
                    ForEach(vm.allFriends) { friend in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { selectedUserIds.contains(friend.id) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedUserIds.insert(friend.id)
                                    } else {
                                        selectedUserIds.remove(friend.id)
                                    }
                                }
                            )) {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(Color("PrimaryColor"))
                                    Text(friend.username)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select Participants")
                } footer: {
                    Text("Select at least 2 participants (including yourself)")
                        .font(.caption)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await createTransaction()
                        }
                    } label: {
                        if isSubmitting {
                            HStack {
                                ProgressView()
                                Text("Creating...")
                            }
                        } else {
                            Label("Create Group", systemImage: "checkmark.circle.fill")
                        }
                    }
                    .disabled(isSubmitting || !isFormValid())
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            // Auto-select current user
            selectedUserIds.insert(vm.myself.id)
        }
    }
    
    private func isFormValid() -> Bool {
        // Check name is not empty
        guard !transactionName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        
        // Check at least 2 users selected
        guard selectedUserIds.count >= 2 else { return false }
        
        return true
    }
    
    func createTransaction() async {
        errorMessage = nil
        
        guard !transactionName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a transaction name"
            return
        }
        
        guard selectedUserIds.count >= 2 else {
            errorMessage = "Please select at least 2 participants"
            return
        }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        let body: [String: Any] = [
            "name": transactionName.trimmingCharacters(in: .whitespaces),
            "user_ids": Array(selectedUserIds)
        ]
        
        do {
            try await SquareUpClient.shared.POST(
                endpoint: "/api/create-transaction",
                body: body
            )
            await vm.fetchTransactions()
            dismiss()
        } catch {
            errorMessage = "Failed to create transaction: \(error.localizedDescription)"
        }
    }
}

struct TransactionCard: View {
    let transaction: Transaction
    @ObservedObject var vm: TransactionViewModel
    @State private var isExpanded = false
    @State private var showAddContribution = false
    @State private var selectedContribution: Contribution? = nil
    @State private var hasVoted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // MARK: Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Display debts summary
                    ForEach(transaction.debts.keys.sorted(), id: \.self) { debtorId in
                        if let owes = transaction.debts[debtorId] {
                            ForEach(owes.keys.sorted(), id: \.self) { creditorId in
                                Text("💸 \(username(for: debtorId)) owes \(username(for: creditorId)) \(owes[creditorId]!, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    // Net amount for current user
                    if let userId = UserDefaults.standard.string(forKey: "profile_user_id"),
                       let netAmount = transaction.netAmounts[userId] {
                        HStack {
                            Text("🧾 Your Balance:")
                            Text(netAmount, format: .currency(code: "USD"))
                                .foregroundColor(netAmount >= 0 ? .green : .red)
                                .bold()
                        }
                        .padding(.bottom, 6)
                    }
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
            
            // MARK: Expanded Section
            if isExpanded {
                Divider()
                    .padding(.vertical, 6)
                
                // Contributions scroll view
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(transaction.contributions) { contrib in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🧍 \(username(for: contrib.senderId))")
                                    .font(.subheadline)
                                Text(contrib.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(contrib.totalAmount, specifier: "%.2f")")
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                            }
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 1)
                            .onTapGesture {
                                selectedContribution = contrib
                            }
                        }
                    }
                }
                .frame(maxHeight: 100)
                
                // Add contribution button
                Button {
                    showAddContribution = true
                } label: {
                    Label("Add Contribution", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryColor"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.top, 10)
                .sheet(isPresented: $showAddContribution) {
                    AddContributionView(transaction: transaction, vm: vm)
                }
                
                SquareUpSwipeControl(
                    hasVoted: $hasVoted,
                    transaction: transaction,
                    vm: vm
                )
                .padding(.top, 12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
        .sheet(item: $selectedContribution) { contribution in
            ContributionDetailView(vm: vm, contribution: contribution, transaction: transaction)
        }
        .onAppear {
            let userId = UserDefaults.standard.string(forKey: "profile_user_id")
            hasVoted = userId != nil && (transaction.votesToDelete ?? []).contains(userId!)
        }
    }
    
    // Helper: Resolve user name
    private func username(for id: String) -> String {
        if let friend = vm.transactionFriends.first(where: { $0.id == id }) {
            return friend.username
        } else {
            return "User"
        }
    }
}

struct ContributionDetailView: View {
    @ObservedObject var vm: TransactionViewModel
    let contribution: Contribution
    let transaction: Transaction
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Paid by")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color("PrimaryColor"))
                            Text(username(for: contribution.senderId))
                                .font(.title2)
                                .bold()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // MARK: Amount Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Amount")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(contribution.totalAmount, format: .currency(code: "USD"))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // MARK: Description Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(contribution.description)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // MARK: Split Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Split Between")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ForEach(contribution.receiverAmounts.keys.sorted(), id: \.self) { receiverId in
                            if let amount = contribution.receiverAmounts[receiverId] {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Color("PrimaryColor"))
                                    
                                    Text(username(for: receiverId))
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Text(amount, format: .currency(code: "USD"))
                                        .font(.body)
                                        .bold()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    // MARK: Date Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(contribution.createdAt, style: .date)
                            .font(.body)
                        Text(contribution.createdAt, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Contribution Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color("PrimaryColor"))
                }
            }
        }
    }
    
    // Helper: Resolve user name
    private func username(for id: String) -> String {
        vm.transactionFriends.first(where: { $0.id == id })?.username ?? "User"
    }
}


struct AddContributionView: View {
    let transaction: Transaction
    @ObservedObject var vm: TransactionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var description = ""
    @State private var totalAmount: Double = 0
    @State private var receiverAmounts: [String: Double] = [:]
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    private var currentUserId: String {
        UserDefaults.standard.string(forKey: "profile_user_id") ?? ""
    }
    
    // Get available receivers (all users except current user)
    private var availableReceivers: [Friend] {
        vm.transactionFriends.filter { $0.id != currentUserId && transaction.userIds.contains($0.id) }
    }
    
    private var computedTotal: Double {
        receiverAmounts.values.compactMap { Double($0) }.reduce(0, +)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Contribution Details") {
                    TextField("Description", text: $description)
                        .autocapitalization(.sentences)
                    
                    TextField("Total", value: $totalAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    ForEach(availableReceivers) { receiver in
                        HStack {
                            Text(receiver.firstName)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("Amount", value: Binding(
                                get: { receiverAmounts[receiver.id] ?? 0 },
                                set: { receiverAmounts[receiver.id] = $0 }
                            ),
                            format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .disabled(totalAmount == 0)
                        }
                    }
                } header: {
                    Text("Covered Amounts")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Total allocated: $\(computedTotal, specifier: "%.2f")")
                            Spacer()
                            Button {
                                let dividedAmount = floor((totalAmount / Double(availableReceivers.count + 1)) * 100) / 100
                                for receiver in availableReceivers {
                                    receiverAmounts[receiver.id] = dividedAmount
                                }
                            } label: {
                                HStack {
                                    Text("Split Evenly")
                                        .foregroundColor(Color("PrimaryColor"))
                                    Text("⚖️")
                                }
                            }
                            .disabled(totalAmount == 0)
                        }
                        if computedTotal > totalAmount {
                            Text("⚠️ Allocated amount exceeds total")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await submitContribution()
                        }
                    } label: {
                        if isSubmitting {
                            HStack {
                                ProgressView()
                                Text("Submitting...")
                            }
                        } else {
                            Label("Submit Contribution", systemImage: "checkmark.circle.fill")
                        }
                    }
                    .disabled(isSubmitting || !isFormValid())
                }
            }
            .navigationTitle("Add Contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundColor(.red)
                }
            }
        }
    }
    
    private func isFormValid() -> Bool {
        // Check description is not empty
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        
        // Check total amount is valid
        if (totalAmount <= 0) { return false }
        
        // Check at least one receiver has an amount
        let validReceivers = receiverAmounts.filter { key, value in
            if value <= 0 { return false }
            return true
        }
        guard !validReceivers.isEmpty else { return false }
        
        return true
    }
    
    func submitContribution() async {
        errorMessage = nil
        
        if (totalAmount <= 0) {
            errorMessage = "Please enter a valid total amount"
            return
        }
        
        // Build receiver amounts dictionary with only non-zero values
        var receiverAmountsDict: [String: Double] = [:]
        for (userId, amount) in receiverAmounts {
            if amount > 0 {
                receiverAmountsDict[userId] = amount
            }
        }
        
        guard !receiverAmountsDict.isEmpty else {
            errorMessage = "Please specify at least one receiver amount"
            return
        }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        let body: [String: Any] = [
            "transaction_id": transaction.id,
            "description": description.trimmingCharacters(in: .whitespaces),
            "total_amount": totalAmount,
            "receiver_amounts": receiverAmountsDict
        ]
        
        do {
            try await SquareUpClient.shared.POST(
                endpoint: "/api/add-contribution",
                body: body
            )
            await vm.fetchTransactions()
            dismiss()
        } catch {
            errorMessage = "Failed to add contribution: \(error.localizedDescription)"
        }
    }
}


struct SquareUpSwipeControl: View {
    @Binding var hasVoted: Bool
    let transaction: Transaction
    @ObservedObject var vm: TransactionViewModel
    
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false
    @State private var lastHapticTrigger: CGFloat = 0
    
    private let swipeThreshold: CGFloat = 100
    private let maxSwipeDistance: CGFloat = 240
    private let startingPosition: CGFloat = 5
    private let hapticInterval: CGFloat = 10 // Trigger haptic every 20 points
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 60)
                
                currentText()
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryColor"))
                    .animation(Animation.spring(duration: 0.3), value: hasVoted)
                
                HStack {
                    RoundedRectangle(cornerRadius: morphCornerRadius())
                        .fill(Color("PrimaryColor"))
                        .frame(width: 50, height: 50)
                        .offset(x: shapeOffset())
                        .shadow(radius: 2)
                        .animation(Animation.spring(duration: 0.3), value: dragOffset)
                        .animation(Animation.spring(duration: 0.3), value: hasVoted)
                    
                    Spacer()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 5)
                    .updating($isDragging) { value, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        dragOffset = value.translation.width
                        triggerProgressiveHaptics(translation: value.translation.width)
                    }
                    .onEnded { value in
                        let userId = UserDefaults.standard.string(forKey: "profile_user_id") ?? ""
                        if value.translation.width > swipeThreshold {
                            // Swipe right -> vote
                            if !hasVoted {
                                triggerSuccessHaptic()
                                hasVoted = true
                                Task {
                                    await vm.voteToDelete(transaction: transaction, userId: userId) {
                                        // Cancel callback - reset hasVoted
                                        hasVoted = false
                                    }
                                }
                            }
                        } else if value.translation.width < -swipeThreshold {
                            // Swipe left -> unvote
                            if hasVoted {
                                triggerSuccessHaptic()
                                hasVoted = false
                                Task {
                                    await vm.unvoteToDelete(transaction: transaction, userId: userId)
                                }
                            }
                        }
                        
                        dragOffset = 0
                        lastHapticTrigger = 0
                    }
            )
        }
    }
    
    private func triggerProgressiveHaptics(translation: CGFloat) {
        let effectiveDrag = hasVoted ? abs(min(translation, 0)) : max(translation, 0)
        
        // Calculate how many intervals we've crossed
        let currentInterval = floor(effectiveDrag / hapticInterval)
        let lastInterval = floor(lastHapticTrigger / hapticInterval)
        
        // Trigger haptic if we've crossed into a new interval
        if currentInterval > lastInterval {
            let progress = effectiveDrag / swipeThreshold
            
            // Vary haptic intensity based on progress
            if progress < 0.3 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else if progress < 0.7 {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else if progress < 1.0 {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            } else {
                // Past threshold - use rigid for stronger feedback
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
            
            lastHapticTrigger = effectiveDrag
        }
    }
    
    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func morphCornerRadius() -> CGFloat {
        let progress = morphProgress()
        return 25 - (progress * 13)
    }
    
    private func shapeOffset() -> CGFloat {
        let basePosition: CGFloat = hasVoted ? maxSwipeDistance : startingPosition
        
        if hasVoted {
            return max(startingPosition, basePosition + dragOffset)
        } else {
            return min(maxSwipeDistance, basePosition + max(0, dragOffset))
        }
    }
    
    private func morphProgress() -> CGFloat {
        if hasVoted {
            let dragProgress = abs(min(dragOffset, 0)) / (maxSwipeDistance - startingPosition)
            return 1.0 - dragProgress
        } else {
            let dragProgress = max(dragOffset, 0) / maxSwipeDistance
            return min(dragProgress, 1.0)
        }
    }
    
    @ViewBuilder
    private func currentText() -> some View {
        if hasVoted {
            HStack {
                Image(systemName: "chevron.left")
                Text("Square Down")
            }
        } else {
            HStack {
                Text("Square Up")
                Image(systemName: "chevron.right")
            }
        }
    }
}
