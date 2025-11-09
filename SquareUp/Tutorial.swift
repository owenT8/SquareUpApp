import SwiftUI

struct TutorialPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
}

struct TutorialView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    let pages: [TutorialPage] = [
        TutorialPage(
            icon: "person.2.fill",
            title: "Add Friends",
            description: "Go to your Profile and search for friends to build your network and split expenses together.",
            gradient: [Color("PrimaryColor").opacity(0.9), Color("PrimaryColor").opacity(0.6)]
        ),
        TutorialPage(
            icon: "person.3.fill",
            title: "Create Groups",
            description: "In the Groups tab, start a new group for trips, events, or shared expenses. Add friends to keep everyone on the same page.",
            gradient: [Color.blue.opacity(0.9), Color.blue.opacity(0.6)]
        ),
        TutorialPage(
            icon: "dollarsign.circle.fill",
            title: "Add Contributions",
            description: "Expand any group and tap 'Add Contribution' to log who paid for what and how it's split. We'll calculate who owes whom automatically.",
            gradient: [Color.green.opacity(0.9), Color.green.opacity(0.6)]
        ),
        TutorialPage(
            icon: "checkmark.seal.fill",
            title: "Square Up",
            description: "When everyone in the group has swiped to Square Up, the balance is settled and the group is deleted. Everyone must agree before it's removed!",
            gradient: [Color.purple.opacity(0.9), Color.purple.opacity(0.6)]
        )
    ]
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        appState.currentScreenGroup = .main
                        UserDefaults.standard.set(true, forKey: "has_seen_tutorial")
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        TutorialPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color("PrimaryColor") : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Bottom button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        appState.currentScreenGroup = .main
                        UserDefaults.standard.set(true, forKey: "has_seen_tutorial")
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("PrimaryColor"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

struct TutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                
                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 20)
            
            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TutorialView()
        .environmentObject(AppState())
}
