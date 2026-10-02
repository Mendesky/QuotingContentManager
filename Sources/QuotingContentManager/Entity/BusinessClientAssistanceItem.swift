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
        /// 稅務帳專用的 `content`；nil 代表兩個帳別共用 `content`。
        /// 與 `ServiceItem.taxAccountName` / `WorkItem.taxAccountContent` 同一個慣例。
        public let taxAccountContent: String?
        public let traits: [Trait]

        init(uniqueCode: String, name: String, content: String, taxAccountContent: String? = nil, traits: [Trait] = []) {
            self.uniqueCode = uniqueCode
            self.name = name
            self.content = content
            self.taxAccountContent = taxAccountContent
            self.traits = traits
        }

        public func displayContent(forTaxAccount isTaxAccount: Bool) -> String {
            isTaxAccount ? (taxAccountContent ?? content) : content
        }

        package func isSubsetOf(tags: [String]) -> Bool {
            if traits.isEmpty { return true }
            return traits.contains {
                $0.tags.isSubset(of: tags) && ($0.excluded.isEmpty || !$0.excluded.isSubset(of: tags))
            }
        }
    }
}
