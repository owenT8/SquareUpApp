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
    @State private var selection: Int = 0
    
    var body: some View {
        TabView(selection: $selection) {
            Social()
                .tag(0)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            Friends()
                .tag(1)
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
            Profile()
                .tag(2)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
    }
}

struct SlideView_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
