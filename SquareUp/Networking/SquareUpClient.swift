//
//  SquareUpClient.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/25/25.
//
import Foundation

struct SquareUpClient {
    static let shared = SquareUpClient()
    let host: String = "http://square-up-server.vercel.app"
    
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
}
