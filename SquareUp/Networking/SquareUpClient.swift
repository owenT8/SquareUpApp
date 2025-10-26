//
//  SquareUpClient.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/25/25.
//
import Foundation

struct TransactionsAndUserResponse: Codable {
    let transactions: [Transaction]
    let userDetails: [Friend]
    
    enum CodingKeys: String, CodingKey {
        case transactions
        case userDetails = "user_details"
    }
}

struct SquareUpClient {
    static let shared = SquareUpClient()
    let host: String = "http://square-up-server.vercel.app/"
    
    func GET(endpoint: String, parameters: [String: Any]? = nil) async throws -> (Data, URLResponse) {
        var components = URLComponents(string: host)!
        components.path = endpoint
        if let parameters = parameters {
            components.queryItems = parameters.map { element in
                URLQueryItem(name: element.key, value: "\(element.value)")
            }
        }

        guard let url = components.url else {
                throw URLError(.badURL)
        }
            
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        // Async/await version
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, response)
    }
    
    func POST(endpoint: String, body: [String: Any]) async throws -> (Data, URLResponse) {
        var components = URLComponents(string: host)!
        components.path = endpoint
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        return (data, response)
    }
    
    func sendOtpCode(data: [String: String]) async throws -> Int {
        let (_, response) = try await self.POST(endpoint: "/api/send-otp", body: data)

        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        return statusCode
    }
    
    func signUp(data: [String: Any]) async throws -> Int {
        let (data, response) = try await self.POST(endpoint: "/api/signup", body: data)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
            throw URLError(.cannotParseResponse)
        }
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        if statusCode == 201 {
            if let token = json["token"] {
                TokenManager.shared.saveToken(access: token)
                try await setUserDefaults(data: json)
            }
        }
        
        return statusCode
    }
    
    func login(data: [String: Any]) async throws -> Int {
        let (data, response) = try await self.POST(endpoint: "/api/login", body: data)
        
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            throw URLError(.cannotParseResponse)
        }
      
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        if statusCode == 200 {
            if let token = json["token"] {
                TokenManager.shared.saveToken(access: token)
            }
            try await setUserDefaults(data: json)
        }
        
        return statusCode
    }
    
    func verifyToken() async throws -> (Bool, [String: Any]) {
        let (data, _) = try await self.POST(endpoint: "/api/verify-token", body: [:])
        
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
                    
        if (json["valid"] != nil) == true {
            try await setUserDefaults(data: json)
            return (true, json)
        } else {
            return (false, [:])
        }
    }
    
    func verifyLoginDetails(data: [String: Any]) async throws -> Bool {
        let (_, response) = try await self.POST(endpoint: "/api/check-email-username-password", body: data)
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        if statusCode == 200 {
            return true
        }
        return false
    }
    
    func verifyEmail(data: [String: Any]) async throws -> Bool {
        let (_, response) = try await self.POST(endpoint: "/api/check-email", body: data)
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        if statusCode == 200 {
            return true
        }
        return false
    }
    
    func verifyUsername(data: [String: Any]) async throws -> Bool {
        let (_, response) = try await self.POST(endpoint: "/api/check-username", body: data)
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        if statusCode == 200 {
            return true
        }
        return false
    }
    
    func resetPassword(data: [String: Any]) async throws -> Bool {
        let (_, response) = try await self.POST(endpoint: "/api/reset-password", body: data)
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        if statusCode == 200 {
            return true
        }
        return false
    }

    func searchUsernames(query: String) async throws -> [Friend] {
        let (data, response) = try await self.GET(endpoint: "/api/search-usernames", parameters: ["prefix": query])
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        if let dict = json as? [String: Any], let friendsArr = dict["usernames"] as? [[String: Any]] {
            let friends = friendsArr.compactMap { Friend(dict: $0) }
            return friends
        } else {
            return []
        }
    }

    func addFriend(username: String) async throws -> Bool {
        let (data, response) = try await self.POST(endpoint: "/api/add-friend-request", body: ["friend_id": username])
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw URLError(.badServerResponse)
        }
        if statusCode == 200 || statusCode == 201 {
            return true
        }
        // Some APIs send { success: true } with 200
        if let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let ok = dict["success"] as? Bool {
            return ok
        }
        return false
    }
    
    func removeFriend(username: String) async throws -> Bool {
        let (data, response) = try await self.POST(endpoint: "/api/remove-friend", body: ["friend_id": username])
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw URLError(.badServerResponse)
        }
        if statusCode == 200 || statusCode == 201 {
            return true
        }
        // Some APIs send { success: true } with 200
        if let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let ok = dict["success"] as? Bool {
            return ok
        }
        return false
    }
    

    func fetchFriends() async throws -> [Friend] {
        let (data, response) = try await self.GET(endpoint: "/api/get-friends")
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        // Expect json to be [String: Any] with a key "friends" mapping to [[String: Any]]
        if let dict = json as? [String: Any], let friendsArr = dict["friends"] as? [[String: Any]] {
            let friends = friendsArr.compactMap { Friend(dict: $0) }
            return friends
        } else {
            return []
        }
    }
    
    func fetchTransactions() async throws -> (transactions: [Transaction], userDetails: [Friend]) {
        let (data, response) = try await self.GET(endpoint: "/api/get-user-transactions")

        // Ensure the HTTP response was successful
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
                
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let result = try decoder.decode(TransactionsAndUserResponse.self, from: data)
            return (transactions: result.transactions, userDetails: result.userDetails)
        } catch {
            throw error
        }
    }
    
    func fetchSocialContributions(limit: Int = 15, afterId: String? = nil) async throws -> ([Contribution], [Friend]) {
        struct Response: Codable {
            let contributions: [Contribution]
            let user_details: [Friend]
        }
        var parameters = ["limit": limit] as [String: Any]
        if afterId != nil {
            parameters["afterId"] = afterId
        }
        let (data, response) = try await self.GET(endpoint: "/api/get-contributions", parameters: parameters)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(Response.self, from: data)
        return (result.contributions, result.user_details)
    }
    
    func fetchFriendRequests() async throws -> (incoming: [Friend], outgoing: [Friend]) {
        let (data, response) = try await self.GET(endpoint: "/api/get-friend-requests")
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        if let dict = json as? [String: Any] {
            let incomingArr = dict["friend_requests"] as? [[String: Any]] ?? []
            let outgoingArr = dict["outgoing_friend_requests"] as? [[String: Any]] ?? []
            let incoming = incomingArr.compactMap { Friend(dict: $0) }
            let outgoing = outgoingArr.compactMap { Friend(dict: $0) }
            return (incoming: incoming, outgoing: outgoing)
        } else {
            return (incoming: [], outgoing: [])
        }
    }
    
    func acceptFriendRequest(forUserId userId: String) async throws -> Bool {
        let (_, response) = try await self.POST(endpoint: "/api/accept-friend-request", body: ["friend_id": userId])
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 else {
            return false
        }
        return true
    }
    
    func rejectFriendRequest(forUserId userId: String) async throws -> Bool {
        let (_, response) = try await self.POST(endpoint: "/api/remove-friend-request", body: ["friend_id": userId])
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 else {
            return false
        }
        return true
    }
    
    func removeOutgoingFriendRequest(forUserId userId: String) async throws -> Bool {
        let (_, response) = try await self.POST(endpoint: "/api/remove-outgoing-friend-request", body: ["friend_id": userId])
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 else {
            return false
        }
        return true
    }
    
    func setUserDefaults(data: [String: Any]) async throws {
        await MainActor.run {
            if let username = data["username"] as? String {
                UserDefaults.standard.set(username, forKey: "profile_username")
            }
            if let email = data["email"] as? String {
                UserDefaults.standard.set(email, forKey: "profile_email")
            }
            if let user_id = data["user_id"] as? String {
                UserDefaults.standard.set(user_id, forKey: "profile_user_id")
            }
            if let first_name = data["first_name"] as? String {
                UserDefaults.standard.set(first_name, forKey: "profile_first_name")
            }
            if let last_name = data["last_name"] as? String {
                UserDefaults.standard.set(last_name, forKey: "profile_last_name")
            }
            if let full_name = data["name"] as? String {
                UserDefaults.standard.set(full_name, forKey: "profile_full_name")
            }
        }
    }
}

