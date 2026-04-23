//
//  ProvisionsSection.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/4/23.
//

public struct ProvisionsSection: Codable, Sendable {
    public let title: String
    public let provisions: [String]

    public init(title: String, provisions: [String]) {
        self.title = title
        self.provisions = provisions
    }
}
