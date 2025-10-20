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

    // Remove the init - don't fetch automatically
    init() {}

    func fetchTransactions() async {
        isLoading = true
        do {
            let data = try await SquareUpClient.shared.fetchTransactions()
            print(data)
            transactions = data
        } catch {
            print("Failed to fetch transactions: \(error)")
        }
        isLoading = false
    }
}

struct TransactionsView: View {
    @StateObject var vm = TransactionViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.transactions.isEmpty {
                    ProgressView("Loading transactions...")
                } else if !vm.transactions.isEmpty {
                    List {
                        ForEach(vm.transactions) { transaction in
                            TransactionCard(transaction: transaction)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
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
            .navigationTitle("Groups")
        }
        .onAppear {
            // Only fetch if we haven't already and not currently loading
            if vm.transactions.isEmpty && !vm.isLoading {
                Task {
                    await vm.fetchTransactions()
                }
            }
        }
    }
}

struct TransactionCard: View {
    let transaction: Transaction
    @State private var isExpanded = false
    @State private var showAddContribution = false
    
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
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.top, 10)
                .sheet(isPresented: $showAddContribution) {
                    AddContributionView(transaction: transaction)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal)
    }
    
    // Helper: Resolve user name
    private func username(for id: String) -> String {
        transaction.userDetails.first(where: { $0.userID == id })?.username ?? "User"
    }
}

struct AddContributionView: View {
    let transaction: Transaction
    @Environment(\.dismiss) private var dismiss
    
    @State private var description = ""
    @State private var totalAmount = ""
    @State private var receiverAmounts: [String: String] = [:]
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    private var currentUserId: String {
        UserDefaults.standard.string(forKey: "profile_user_id") ?? ""
    }
    
    // Get available receivers (all users except current user)
    private var availableReceivers: [UserDetail] {
        transaction.userDetails.filter { $0.userID != currentUserId }
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
                    
                    TextField("Total Amount", text: $totalAmount)
                        .keyboardType(.decimalPad)
                        .onChange(of: totalAmount) { _, newValue in
                            // Filter to only allow numbers and decimal point
                            let filtered = newValue.filter { "0123456789.".contains($0) }
                            if filtered != newValue {
                                totalAmount = filtered
                            }
                        }
                }
                
                Section {
                    ForEach(availableReceivers) { receiver in
                        HStack {
                            Text(receiver.firstName)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("Amount", text: Binding(
                                get: { receiverAmounts[receiver.userID] ?? "" },
                                set: { receiverAmounts[receiver.userID] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .onChange(of: receiverAmounts[receiver.userID] ?? "") { _, newValue in
                                // Filter to only allow numbers and decimal point
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                if filtered != newValue {
                                    receiverAmounts[receiver.userID] = filtered
                                }
                            }
                        }
                    }
                } header: {
                    Text("Receiver Amounts")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total allocated: $\(computedTotal, specifier: "%.2f")")
                        if let total = Double(totalAmount), computedTotal > total {
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
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func isFormValid() -> Bool {
        // Check description is not empty
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        
        // Check total amount is valid
        guard let total = Double(totalAmount), total > 0 else { return false }
        
        // Check at least one receiver has an amount
        let validReceivers = receiverAmounts.filter { key, value in
            guard let amount = Double(value), amount > 0 else { return false }
            return true
        }
        guard !validReceivers.isEmpty else { return false }
        
        return true
    }
    
    func submitContribution() async {
        errorMessage = nil
        
        guard let total = Double(totalAmount), total > 0 else {
            errorMessage = "Please enter a valid total amount"
            return
        }
        
        // Build receiver amounts dictionary with only non-zero values
        var receiverAmountsDict: [String: Double] = [:]
        for (userId, amountStr) in receiverAmounts {
            if let amount = Double(amountStr), amount > 0 {
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
            "total_amount": total,
            "receiver_amounts": receiverAmountsDict
        ]
        
        do {
            try await SquareUpClient.shared.POST(
                endpoint: "/api/add-contribution",
                body: body
            )
            dismiss()
        } catch {
            errorMessage = "Failed to add contribution: \(error.localizedDescription)"
            print("❌ Failed to add contribution:", error)
        }
    }
}

struct Balances: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
           
        }
    }
}
