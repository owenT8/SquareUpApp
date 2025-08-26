//
//  SquareUpClient.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/25/25.
//
import Foundation

struct SquareUpClient {
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
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        print(request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print(data, response)
        
        return (data, response)
    }
    
    func signUp(data: [String: Any]) async throws -> [String : String] {
        let (data, _) = try await self.POST(endpoint: "/api/signup", body: data)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
            throw URLError(.cannotParseResponse)
        }
        return json
    }
    
    func login(data: [String: Any]) async throws -> [String : String] {
        print("Logging in user")
        let (data, _) = try await self.POST(endpoint: "/api/login", body: data)
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            throw URLError(.cannotParseResponse)
        }
        print("Logged in with user: \(json)")
        return json
    }
    
    func verifyToken(data: [String: Any]) async throws -> Bool {
        let (data, _) = try await self.POST(endpoint: "/api/verify-token", body: data)
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            throw URLError(.cannotParseResponse)
        }
        return json["valid"] == "True" || json["valid"] == "true"
    }
}
