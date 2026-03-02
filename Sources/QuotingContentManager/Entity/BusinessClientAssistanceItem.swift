//
//  BusinessClientAssistanceItem.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

public extension BusinessClientAssistanceManager {
    struct Item: Sendable {
        public let uniqueCode: String
        public let name: String
        public let content: String
        public let traits: [Trait]

        init(uniqueCode: String, name: String, content: String, traits: [Trait] = []) {
            self.uniqueCode = uniqueCode
            self.name = name
            self.content = content
            self.traits = traits
        }

        package func isSubsetOf(tags: [String]) -> Bool {
            traits.contains {
                $0.tags.isSubset(of: tags) && ($0.excluded.isEmpty || !$0.excluded.isSubset(of: tags))
            }
        }
    }
}
