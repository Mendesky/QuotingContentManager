//
//  ScopeTerm.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/4/23.
//

public struct ScopeTerm: Codable, Sendable {
    public let name: String
    public let content: String

    public init(name: String, content: String) {
        self.name = name
        self.content = content
    }
}
