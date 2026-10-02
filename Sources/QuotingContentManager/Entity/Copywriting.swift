//
//  ContractHeader.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/3.
//

public struct Copywriting: Codable, Sendable {
    public let title: String
    public let content: String
    /// 稅務帳專用的 `content`；nil 代表兩個帳別共用 `content`。
    ///
    /// 與 `ServiceItem.taxAccountName` / `WorkItem.taxAccountContent` 同一個慣例。
    /// 需要它的理由見 `QuotingContentManager.contractHeader`：1150828 母版的稅務帳版與一套帳版
    /// 句型本身不同（不只是名詞不同），`%AccountingWorkName%` 一個值表達不了兩邊。
    public let taxAccountContent: String?

    public init(title: String, content: String, taxAccountContent: String? = nil) {
        self.title = title
        self.content = content
        self.taxAccountContent = taxAccountContent
    }

    public func displayContent(forTaxAccount isTaxAccount: Bool) -> String {
        isTaxAccount ? (taxAccountContent ?? content) : content
    }
}
