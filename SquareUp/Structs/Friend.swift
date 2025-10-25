//
//  Friend.swift
//  SquareUp
//
//  Created by Owen  Taylor on 10/18/25.
//

struct Friend: Identifiable, Codable, Hashable {
    let id: String
    let username: String
    let firstName: String
    let lastName: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case name
    }

    init(id: String, username: String, firstName: String, lastName: String, name: String) {
        self.id = id
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.name = name
    }

    init?(dict: [String: Any]) {
        guard let id = dict["user_id"] as? String,
              let username = dict["username"] as? String,
              let firstName = dict["first_name"] as? String,
              let lastName = dict["last_name"] as? String,
              let name = dict["name"] as? String
        else {
            return nil
        }
        self.init(id: id, username: username, firstName: firstName, lastName: lastName, name: name)
    }
}
