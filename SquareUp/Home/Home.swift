//
//  Home.swift
//  SquareUp
//
//  Created by Owen  Taylor on 9/6/25.
//
import SwiftUI

enum HomePage {
    case socail, balances, profile
}

struct Home: View {
    @State private var selection = 0
    let pages = [Color.red, Color.green, Color.blue] // replace with
    struct TabItem {
        let title: String
        let icon: String
    }
    
    let tabs: [TabItem] = [
        TabItem(title: "Home", icon: "house.fill"),
        TabItem(title: "Friends", icon: "person.2.fill"),
        TabItem(title: "Profile", icon: "person.crop.circle.fill")
    ]
    
    var body: some View {
        ZStack {
            // Main pages
            TabView(selection: $selection) {
                Social()
                    .tag(0)
                Friends()
                    .tag(1)
                Profile()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Floating bar overlay
            VStack {
                Spacer()
                HStack {
                    ForEach(tabs.indices, id: \.self) { index in
                        Button {
                            withAnimation {
                                selection = index
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tabs[index].icon)
                                    .font(.system(size: 30, weight: .semibold))
//                                Text(tabs[index].title)
//                                    .font(.caption)
                            }
                            .foregroundColor(selection == index ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .background(.ultraThinMaterial) // blurry floating effect
                .clipShape(Capsule())
                .shadow(radius: 5)
                .padding(.bottom, 5)
            }
            .padding(.horizontal, 20)
        }
    }
}

struct SlideView_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
