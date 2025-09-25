//
//  Venmo.swift
//  SquareUp
//
//  Created by Owen  Taylor on 9/6/25.
//
import SwiftUI

struct Social: View {
    let items: [Item] = [
        .init(firstName: "Owen", lastName: "Taylor"),
        .init(firstName: "Emily", lastName: "Clark"),
        .init(firstName: "Michael", lastName: "Brown"),
        .init(firstName: "Sophia", lastName: "Davis")
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

