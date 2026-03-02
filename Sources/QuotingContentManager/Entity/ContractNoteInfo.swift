//
//  ContractNoteInfo.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

public extension ContractNoteManager {
    struct ContractNoteInfo: Sendable {
        public let uniqueCode: String
        public let content: String
        public let traits: [Trait]
        public let mutex: Mutex?
        public let weight: Int
        public let deprecated: Bool

        init(deprecated: Bool = false, uniqueCode: String, mutex: Mutex? = nil, traits: [Trait], weight: Int, content: String) {
            self.uniqueCode = uniqueCode
            self.content = content
            self.traits = traits
            self.mutex = mutex
            self.weight = weight
            self.deprecated = deprecated
        }

        package func isSubsetOf(tags: [String]) -> Bool {
            traits.contains {
                let result = $0.tags.isSubset(of: tags) && ($0.excluded.isEmpty || !$0.excluded.isSubset(of: tags))
                return result
            }
        }
    }
}

public extension ContractNoteManager.ContractNoteInfo {
    enum Mutex: Sendable {
        case codes([String])
        case tags([String])
    }
}
