//
//  Balances.swift
//  SquareUp
//
//  Created by Owen  Taylor on 9/6/25.
//

import SwiftUI

struct Item: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let details: String
    let firstName: String
    let lastName: String
}

struct Friends: View {
    let items: [Item] = [
        .init(title: "Groceries", subtitle: "Weekly shop", details: "Milk, eggs, bread, fruit, veggies.", firstName: "Owen", lastName: "Taylor"),
        .init(title: "Gym", subtitle: "Workout plan", details: "Push/Pull/Legs split.", firstName: "Owen", lastName: "Taylor"),
        .init(title: "Trip", subtitle: "Weekend trip", details: "Packing list: charger, jacket, camera.", firstName: "Owen", lastName: "Taylor"),
        .init(title: "Project", subtitle: "App v1.2", details: "Finish OTP UI, add analytics, write tests.", firstName: "Owen", lastName: "Taylor")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(items) { item in
                        NavigationLink(destination: DetailView(item: item)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(makePayment(item: item))
                                    .font(.headline)
                                Text(item.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle()) // removes default NavigationLink styling
                    }
                }
                .padding()
            }
            .navigationTitle("Your Balances")
        }
    }
    
    private func makePayment(item: Item) -> String {
        return item.firstName + " " + item.lastName + " → " + item.firstName + " " + item.lastName
    }
}

struct DetailView: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(item.title)
                .font(.largeTitle)
                .bold()
            Text(item.subtitle)
                .font(.title3)
                .foregroundColor(.secondary)
            Divider()
            Text(item.details)
                .font(.body)
            Spacer()
        }
        .padding()
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SimpleListView_Previews: PreviewProvider {
    static var previews: some View {
        Friends()
    }
}
