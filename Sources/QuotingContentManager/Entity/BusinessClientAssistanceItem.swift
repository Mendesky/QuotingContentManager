//
//  BusinessClientAssistanceItem.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

public extension BusinessClientAssistanceManager {
    struct Item: Sendable {
        public let name: String
        public let content: String
        public let traits: [Trait]

        init(name: String, content: String, traits: [Trait] = []) {
            self.name = name
            self.content = content
            self.traits = traits
        }
    }
}
