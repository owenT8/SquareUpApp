//
//  Venmo.swift
//  SquareUp
//
//  Created by Owen  Taylor on 9/6/25.
//
import SwiftUI

struct Social: View {
    let items: [Item] = [
        .init(title: "Groceries", subtitle: "Weekly shop", details: "Milk, eggs, bread, fruit, veggies.", firstName: "Owen", lastName: "Taylor"),
        .init(title: "Gym", subtitle: "Workout plan", details: "Push/Pull/Legs split.", firstName: "Owen", lastName: "Taylor"),
        .init(title: "Trip", subtitle: "Weekend trip", details: "Packing list: charger, jacket, camera.", firstName: "Owen", lastName: "Taylor"),
        .init(title: "Project", subtitle: "App v1.2", details: "Finish OTP UI, add analytics, write tests.", firstName: "Owen", lastName: "Taylor")
    ]
    
    var body: some View {
        Text("Social View")
    }
    
    private func makePayment(item: Item) -> String {
        return item.firstName + " " + item.lastName + " → " + item.firstName + " " + item.lastName
    }
}

struct Social_Previews: PreviewProvider {
    static var previews: some View {
        Social()
    }
}
