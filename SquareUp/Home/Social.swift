//
//  Venmo.swift
//  SquareUp
//
//  Created by Owen  Taylor on 9/6/25.
//
import SwiftUI

@MainActor
class SocialFeedViewModel: ObservableObject {
    @Published var contributions: [Contribution] = []
    @Published var userDetails: [Friend] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasMoreContent: Bool = true
    
    private var appState: AppState
    private let pageSize: Int = 15
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func fetchInitialContributions() async {
        isLoading = true
        hasMoreContent = true
        
        do {
            let (newContributions, users) = try await SquareUpClient.shared.fetchSocialContributions(limit: pageSize)
            contributions = newContributions
            userDetails = users
            hasMoreContent = newContributions.count == pageSize
        } catch {
            appState.showErrorToast = true
            appState.errorMessage = "Failed to load feed."
        }
        
        isLoading = false
    }
    
    func refreshContributions() async {
        do {
            let (newContributions, users) = try await SquareUpClient.shared.fetchSocialContributions(limit: pageSize)
            contributions = newContributions
            userDetails = users
            hasMoreContent = newContributions.count == pageSize
        } catch {
            let nsError = error as NSError
            guard nsError.domain != NSURLErrorDomain || nsError.code != NSURLErrorCancelled else {
                return
            }
            appState.showErrorToast = true
            appState.errorMessage = "Failed to load feed."
        }
    }
    
    func loadMoreContributions() async {
        guard !isLoadingMore && hasMoreContent else { return }
        
        isLoadingMore = true
        
        do {
            // Get the last contribution ID to use as a cursor for pagination
            guard let lastId = contributions.last?.id else {
                isLoadingMore = false
                return
            }
            
            let (newContributions, users) = try await SquareUpClient.shared.fetchSocialContributions(limit: pageSize, afterId: lastId)
            
            // Append new contributions
            contributions.append(contentsOf: newContributions)
            
            // Merge user details
            let newUsers = users.filter { newUser in
                !userDetails.contains { $0.id == newUser.id }
            }
            userDetails.append(contentsOf: newUsers)
            
            // If we got fewer items than requested, we've reached the end
            hasMoreContent = newContributions.count == pageSize
        } catch {
            appState.showErrorToast = true
            appState.errorMessage = "Failed to load more."
        }
        
        isLoadingMore = false
    }
    
    func username(for id: String) -> String {
        userDetails.first(where: { $0.id == id })?.username ?? "User"
    }
    
    func fullName(for id: String) -> String {
        userDetails.first(where: { $0.id == id })?.name ?? "Unknown"
    }
}

struct SocialFeedView: View {
    @StateObject var vm: SocialFeedViewModel
    @EnvironmentObject var appState: AppState
    
    init(appState: AppState) {
        _vm = StateObject(wrappedValue: SocialFeedViewModel(appState: appState))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                if vm.isLoading && vm.contributions.isEmpty {
                    ProgressView("Loading feed...")
                } else {
                    List {
                        if vm.contributions.isEmpty {
                            // Empty state inside the list so refresh still works
                            VStack(spacing: 16) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text("No Activity Yet")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Contributions from your friends will appear here.\nPull down to refresh.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(vm.contributions) { contribution in
                                SocialContributionCard(contribution: contribution, vm: vm)
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .padding(.bottom, 16)
                                    .onAppear {
                                        // Load more when we reach near the end
                                        if contribution.id == vm.contributions.last?.id {
                                            Task {
                                                await vm.loadMoreContributions()
                                            }
                                        }
                                    }
                            }
                            
                            if vm.isLoadingMore {
                                ProgressView()
                                    .padding()
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            } else if !vm.hasMoreContent && !vm.contributions.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("You're all caught up! 🎉")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding()
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await vm.refreshContributions()
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 80)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Activity")
        }
        .scenePadding(.horizontal)
        .onAppear {
            if vm.contributions.isEmpty && !vm.isLoading {
                Task {
                    await vm.fetchInitialContributions()
                }
            }
        }
    }
}

struct SocialContributionCard: View {
    let contribution: Contribution
    @ObservedObject var vm: SocialFeedViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color("PrimaryColor"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.fullName(for: contribution.senderId))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("@\(vm.username(for: contribution.senderId))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(contribution.createdAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(contribution.description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }
            .padding(.leading, 4)
            
            // MARK: Split info
            if contribution.receiverAmounts.count > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Split with \(contribution.receiverAmounts.count) \(contribution.receiverAmounts.count == 1 ? "person" : "people")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}
