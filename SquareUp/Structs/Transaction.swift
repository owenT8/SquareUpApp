//
//  Transaction.swift
//  SquareUp
//
//  Created by Owen  Taylor on 10/19/25.
//

import Foundation

struct Transaction: Codable, Identifiable {
    let id: String
    let name: String
    let userIds: [String]
    let contributions: [Contribution]
    let netAmounts: [String: Double]
    let debts: [String: [String: Double]]
    let createdAt: Date
    let createdBy: String?
    var votesToDelete: [String]?

    enum CodingKeys: String, CodingKey {
        case id = "transaction_id"
        case name
        case userIds = "user_ids"
        case contributions
        case netAmounts = "net_amounts"
        case debts
        case createdAt = "created_at"
        case createdBy = "created_by"
        case votesToDelete = "votes_to_delete"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        userIds = try container.decode([String].self, forKey: .userIds)
        contributions = try container.decode([Contribution].self, forKey: .contributions)
        netAmounts = try container.decode([String: Double].self, forKey: .netAmounts)
        debts = try container.decode([String: [String: Double]].self, forKey: .debts)
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        votesToDelete = try container.decodeIfPresent([String].self, forKey: .votesToDelete)
        // Flexible decode for createdAt
        if let doubleValue = try? container.decode(Double.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: doubleValue)
        } else if let stringValue = try? container.decode(String.self, forKey: .createdAt) {
            // Try ISO8601 first
            if let date = ISO8601DateFormatter().date(from: stringValue) {
                createdAt = date
            } else {
                // Try HTTP-date (RFC1123)
                let rfc1123 = DateFormatter()
                rfc1123.locale = Locale(identifier: "en_US_POSIX")
                rfc1123.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                if let date = rfc1123.date(from: stringValue) {
                    createdAt = date
                } else if let doubleValue = Double(stringValue) {
                    createdAt = Date(timeIntervalSince1970: doubleValue)
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date string: \(stringValue)")
                }
            }
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Could not decode date")
        }
    }
}

struct Contribution: Codable, Identifiable {
    let id: String
    let senderId: String
    let description: String
    let totalAmount: Double
    let receiverAmounts: [String: Double]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "contribution_id"
        case senderId = "sender_id"
        case description
        case totalAmount = "total_amount"
        case receiverAmounts = "receiver_amounts"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        senderId = try container.decode(String.self, forKey: .senderId)
        description = try container.decode(String.self, forKey: .description)
        totalAmount = try container.decode(Double.self, forKey: .totalAmount)
        receiverAmounts = try container.decode([String: Double].self, forKey: .receiverAmounts)
        // Flexible decode for createdAt
        if let doubleValue = try? container.decode(Double.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: doubleValue)
        } else if let stringValue = try? container.decode(String.self, forKey: .createdAt) {
            // Try to parse ISO8601 first
            if let date = ISO8601DateFormatter().date(from: stringValue) {
                createdAt = date
            } else {
                // Try HTTP-date (RFC1123)
                let rfc1123 = DateFormatter()
                rfc1123.locale = Locale(identifier: "en_US_POSIX")
                rfc1123.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                if let date = rfc1123.date(from: stringValue) {
                    createdAt = date
                } else if let doubleValue = Double(stringValue) {
                    createdAt = Date(timeIntervalSince1970: doubleValue)
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date string: \(stringValue)")
                }
            }
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Could not decode date")
        }
        
        if let contribution_id = try? container.decode(String.self, forKey: .id) {
            id = contribution_id
        } else {
            id = UUID().uuidString
        }
    }
}

