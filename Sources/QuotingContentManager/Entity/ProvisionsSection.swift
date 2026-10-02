//
//  ProvisionsSection.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/4/23.
//

public struct ProvisionsSection: Codable, Sendable {
    public let title: String

    /// 條文清單。**逐條**帶帳別變體——1150828 母版裡，權利義務的(一)(二)稅務帳與一套帳句型不同、
    /// (三)兩邊相同；其它約定則反過來只有(三)不同。整個 section 拆兩份會讓沒有差異的長條文重複一次，
    /// 所以差異落在條的層級。
    public let provisions: [Provision]

    public init(title: String, provisions: [Provision]) {
        self.title = title
        self.provisions = provisions
    }

    /// 取出該帳別實際要印的條文。**呼叫端一律走這支**，不要直接讀 `provisions` 的原始字串，
    /// 否則稅務帳會拿到一套帳的版本。
    public func displayProvisions(forTaxAccount isTaxAccount: Bool) -> [String] {
        provisions.map { $0.displayText(forTaxAccount: isTaxAccount) }
    }

    /// 一條條文。`taxAccount` 為 nil 代表兩個帳別共用 `standard`
    /// （與 `ServiceItem.taxAccountName` / `WorkItem.taxAccountContent` 同一個慣例）。
    public struct Provision: Codable, Sendable, ExpressibleByStringLiteral {
        public let standard: String
        public let taxAccount: String?

        public init(_ standard: String, taxAccount: String? = nil) {
            self.standard = standard
            self.taxAccount = taxAccount
        }

        /// 兩個帳別共用時可以直接寫字串字面量，省掉一層 `.init(...)` 雜訊。
        public init(stringLiteral value: String) {
            self.init(value)
        }

        public func displayText(forTaxAccount isTaxAccount: Bool) -> String {
            isTaxAccount ? (taxAccount ?? standard) : standard
        }
    }
}
