//
//  ContractNoteInfo.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

public struct ContractNoteInfo: Sendable {
    public let uniqueCode: String

    /// 備註內容的組成段落。
    ///
    /// 多數備註只有一段、且無條件（`init(…, content:)` 會包成單段），讀起來與改版前無異。
    /// 1150828 母版新增的註一（報價基準）／註二（付款條件）是**複合備註**：一條備註的內文
    /// 由數個各自帶 trait 條件的段落組成，只選財簽就只印財簽那段。這是母版「按主題併成一條」
    /// 與「內容依選到的服務裁剪」兩個要求的交集，用一條 note 一個固定字串表達不了。
    public let segments: [Segment]

    /// 組完所有段落後接在最末的字元（通常是句號）。
    ///
    /// 標點放這裡而不是寫進每段的尾巴：段落之間用 `Segment.separator` 相接，哪一段會變成最後一段
    /// 取決於當下選了什麼服務；把句號留在各段尾巴，少印中間某段時就會多出或少掉標點。
    public let terminator: String

    public let traits: [Trait]
    public let mutex: Mutex?
    public let weight: Int
    public let deprecated: Bool

    /// 這條備註屬於哪個「編號群組」。非 nil 時，內文前面要掛上群組的序號前綴
    /// （例如「附加服務選項2：」）。
    ///
    /// **序號不存在這裡，也不存在備註快照裡**：它取決於當下有幾條同群組的備註、以及它們的排序，
    /// 兩者都會變（隱藏一張附加服務卡 → 少一條；使用者拖曳 → 順序換）。寫死就會像改版前那樣，
    /// 隱藏 CTP 之後補充保費仍然自稱「選項2」。唯一算得準的地方是讀取端拿到最終排序之後，
    /// 見 OpportunityContext 的 `GetContractNotesApplicationService`。
    public let optionGroup: OptionGroup?

    /// 單段、無條件的備註（改版前的既有形狀）。
    init(deprecated: Bool = false, uniqueCode: String, mutex: Mutex? = nil, traits: [Trait], weight: Int, optionGroup: OptionGroup? = nil, content: String) {
        self.init(
            deprecated: deprecated,
            uniqueCode: uniqueCode,
            mutex: mutex,
            traits: traits,
            weight: weight,
            optionGroup: optionGroup,
            segments: [.init(content)],
            terminator: ""
        )
    }

    /// 複合備註：內文由數個條件段落組成。
    init(
        deprecated: Bool = false,
        uniqueCode: String,
        mutex: Mutex? = nil,
        traits: [Trait],
        weight: Int,
        optionGroup: OptionGroup? = nil,
        segments: [Segment],
        terminator: String = ""
    ) {
        self.uniqueCode = uniqueCode
        self.segments = segments
        self.terminator = terminator
        self.traits = traits
        self.mutex = mutex
        self.weight = weight
        self.optionGroup = optionGroup
        self.deprecated = deprecated
    }

    /// 需要連號呈現的備註群組。
    public enum OptionGroup: String, Sendable, CaseIterable, Hashable {
        /// 同意函可勾選的附加服務（CTP、補充保費…），內文前綴「附加服務選項N：」。
        case additionalService

        /// 前綴的用字住在這裡而不是呼叫端 —— 文案屬於 QCM，讀取端只負責算出 `number`。
        public func prefix(number: Int) -> String {
            switch self {
            case .additionalService: "附加服務選項\(number)："
            }
        }
    }

    /// 依實際命中的 tag 組出這條備註要寫進報價單的內文。
    ///
    /// 一段都沒命中 → nil（整條備註不出現）。呼叫端一律走這支，**不要**自己把 `segments` 串起來。
    public func composedContent(subsetOf tags: [String]) -> String? {
        let present = segments.filter { $0.isSubsetOf(tags: tags) }
        guard !present.isEmpty else { return nil }
        var text = ""
        for (index, segment) in present.enumerated() {
            if index > 0 { text += segment.separator }
            text += segment.text
        }
        return text + terminator
    }

    /// 把所有段落無條件串起來。**這不是任何一份報價單會印出來的內容** —— 名字刻意不叫
    /// `fullContent`，免得讀起來像「完整內文」而被拿去斷言完整句子。
    ///
    /// 它假設段落彼此相加，但段落也可以是**互為替代**的：註一的主詞三段中，「營業收入總額」
    /// 與「營業收入總額及憑證量」靠 `excluded` 互斥（兩者講同一個指標），全部串起來會讀成
    /// 「營業收入總額、營業收入總額及憑證量」。
    ///
    /// 用途只有一個：**不知道選了什麼服務時的字串存在性檢查**（例如掃所有備註有沒有出現某個字眼）。
    /// 寫進報價單的內容一律走 `composedContent(subsetOf:)`。
    public var allSegmentsJoined: String {
        var text = ""
        for (index, segment) in segments.enumerated() {
            if index > 0 { text += segment.separator }
            text += segment.text
        }
        return text + terminator
    }

    package func isSubsetOf(tags: [String]) -> Bool {
        traits.contains {
            let result = $0.tags.isSubset(of: tags) && ($0.excluded.isEmpty || !$0.excluded.isSubset(of: tags))
            return result
        }
    }

    /// 備註內文的一段。
    public struct Segment: Sendable, ExpressibleByStringLiteral {
        public let text: String
        /// 接在前一段之後、本段之前的字串；本段是第一段時忽略。
        public let separator: String
        /// 這一段出現的條件。空陣列 = 無條件（只要整條備註出現就印）。
        public let traits: [Trait]

        public init(_ text: String, separator: String = "", traits: [Trait] = []) {
            self.text = text
            self.separator = separator
            self.traits = traits
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        func isSubsetOf(tags: [String]) -> Bool {
            if traits.isEmpty { return true }
            return traits.contains {
                $0.tags.isSubset(of: tags) && ($0.excluded.isEmpty || !$0.excluded.isSubset(of: tags))
            }
        }
    }
}
