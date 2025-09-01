//
//  TokenManager.swift
//  SquareUp
//
//  Created by Owen  Taylor on 8/31/25.
//

import Foundation

class TokenManager {
    static let shared = TokenManager()
    private let accessService = "com.squareup.access"
    private let refreshService = "com.squareup.refresh"
    private let account = "auth"

    var accessToken: String? {
        guard let data = KeychainHelper.read(service: accessService, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    var refreshToken: String? {
        guard let data = KeychainHelper.read(service: refreshService, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveTokens(access: String, refresh: String) {
        KeychainHelper.save(Data(access.utf8), service: accessService, account: account)
        KeychainHelper.save(Data(refresh.utf8), service: refreshService, account: account)
    }
    
    func saveToken(access: String) {
        KeychainHelper.save(Data(access.utf8), service: accessService, account: account)
    }

    func clearTokens() {
        KeychainHelper.delete(service: accessService, account: account)
        KeychainHelper.delete(service: refreshService, account: account)
    }

    func isAccessTokenExpired(_ token: String) -> Bool {
        guard let payload = decodeJWT(token),
              let exp = payload["exp"] as? TimeInterval else { return true }
        return Date(timeIntervalSince1970: exp) < Date()
    }

    private func decodeJWT(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        let payloadData = base64UrlDecode(String(parts[1]))
        return payloadData.flatMap {
            try? JSONSerialization.jsonObject(with: $0, options: []) as? [String: Any]
        }
    }

    private func base64UrlDecode(_ base64Url: String) -> Data? {
        var base64 = base64Url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        return Data(base64Encoded: base64)
    }

    func refreshIfNeeded(completion: @escaping (String?) -> Void) {
        guard let token = accessToken else {
            completion(nil)
            return
        }

        if !isAccessTokenExpired(token) {
            completion(token)
            return
        }

        // 🔄 Call backend refresh endpoint
        guard let refresh = refreshToken else {
            completion(nil)
            return
        }

        var req = URLRequest(url: URL(string: "https://api.myapp.com/auth/refresh")!)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["refresh_token": refresh])

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                  let newAccess = json["access_token"],
                  let newRefresh = json["refresh_token"] else {
                completion(nil)
                return
            }
            self.saveTokens(access: newAccess, refresh: newRefresh)
            completion(newAccess)
        }.resume()
    }
}
