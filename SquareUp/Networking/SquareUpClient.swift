//
//  SquareUpClient.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/25/25.
//
import Foundation

struct SquareUpClient {
    static let shared = SquareUpClient()
    let host: String = "http://127.0.0.1:8000"
    
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
        
        print(body)
                
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
        }
        
        return statusCode
    }
    
    func verifyToken() async throws -> (Bool, [String: Any]) {
        let (data, _) = try await self.POST(endpoint: "/api/verify-token", body: [:])
        
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
                    
        if (json["valid"] != nil) == true {
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
        let (data, response) = try await self.POST(endpoint: "/api/add-friend", body: ["friend_id": username])
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
    
    struct TransactionResponse: Codable {
        let transactions: [Transaction]
    }

    func fetchTransactions() async throws -> [Transaction] {
        let (data, response) = try await self.GET(endpoint: "/api/get-user-transactions")

        // Ensure the HTTP response was successful
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let result = try decoder.decode(TransactionResponse.self, from: data)
            return result.transactions
        } catch {
            throw error
        }
    }
}

