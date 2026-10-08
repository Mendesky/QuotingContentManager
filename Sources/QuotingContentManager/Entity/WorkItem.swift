public struct WorkItem: Codable, Sendable, Equatable {
    public let type: String
    public let content: String
    public let taxAccountContent: String?
    /// 行號（獨資合夥）專用內容。行號不是向經濟部辦公司登記，而是依商業登記法向地方政府辦商業登記，
    /// 故工商登記的「公司名稱預查／公司設立登記」對行號改印「商業登記名稱預查／商業設立登記」。
    /// `nil` = 與 `content` 同字。模式仿 `taxAccountContent`。
    public let soleProprietorshipOrPartnershipContent: String?
    public let description: String?
    public let subItems: [String]
    /// 這個 workItem 在「服務範圍」段落的顯示範圍。
    ///
    /// **定義一定要留著、只是不顯示**：下游 `GetServiceScopeApplicationService` 對每個被勾選的
    /// workItemType 查表，查不到會直接 throw。存量案件勾過的項目若從陣列刪掉，整份報價單 PDF
    /// 與公費合約頁都會 500，而不是少印一行。
    ///
    /// 需要分帳別的理由：1150828 母版把「年底結算作業」兩個帳別都劃掉，但「平時帳務作業」
    /// 只有稅務帳劃掉、一套帳留著（改成只印「憑證整理歸檔」）。
    public let serviceScopeVisibility: ServiceScopeVisibility

    /// 這個 workItem 在服務範圍末尾要指向的合約注意事項（1150917 母版：
    /// 「二代健保申報作業。(註五)」）。nil 代表不引用任何備註。
    ///
    /// 引用的位置由 `content` / `taxAccountContent` 裡的 `{noteRef}` 標出。
    public let noteReference: ContractNoteReference?

    public init(
        type: String,
        content: String,
        taxAccountContent: String? = nil,
        soleProprietorshipOrPartnershipContent: String? = nil,
        description: String? = nil,
        subItems: [String] = [],
        serviceScopeVisibility: ServiceScopeVisibility = .both,
        noteReference: ContractNoteReference? = nil
    ) {
        self.type = type
        self.content = content
        self.taxAccountContent = taxAccountContent
        self.soleProprietorshipOrPartnershipContent = soleProprietorshipOrPartnershipContent
        self.description = description
        self.subItems = subItems
        self.serviceScopeVisibility = serviceScopeVisibility
        self.noteReference = noteReference
    }

    /// 該帳別要印的內文。`noteNumber` 給值時填入 `{noteRef}`，算不出註號時整段引用消失
    /// （見 `ContractNoteReference.substitute`）。
    public func displayContent(for accountingCategory: AccountingCategory?, noteNumber: String? = nil) -> String {
        let text = accountingCategory.pick(standard: content, taxAccount: taxAccountContent)
        return ContractNoteReference.substitute(in: text, reference: noteReference, noteNumber: noteNumber)
    }

    /// 依帳別與組織型態取顯示內容：行號專用內容優先，其次才是帳別分流（`displayContent(for:noteNumber:)`）。
    ///
    /// 兩種變體目前不會出現在同一個 workItem（行號內容只在工商登記、稅務帳內容只在記帳），
    /// 優先序只是讓語意明確。`organizationType == nil`（呼叫端取不到型態）→ 退回帳別版，即公司原文。
    public func displayContent(for accountingCategory: AccountingCategory?, organizationType: OrganizationType?, noteNumber: String? = nil) -> String {
        if organizationType == .soleProprietorshipOrPartnership, let soleProprietorshipOrPartnershipContent {
            return ContractNoteReference.substitute(in: soleProprietorshipOrPartnershipContent, reference: noteReference, noteNumber: noteNumber)
        }
        return displayContent(for: accountingCategory, noteNumber: noteNumber)
    }

    public func isVisibleInServiceScope(for accountingCategory: AccountingCategory?) -> Bool {
        switch serviceScopeVisibility {
        case .both:           true
        case .standardOnly:   !accountingCategory.usesTaxAccountCopy
        case .taxAccountOnly: accountingCategory.usesTaxAccountCopy
        case .hidden:         false
        }
    }

    public enum ServiceScopeVisibility: String, Codable, Sendable, Equatable {
        /// 兩個帳別都印（預設）。
        case both
        /// 只有印一般版文案的帳別印；稅務帳不印（哪些帳別算一般版見 `usesTaxAccountCopy`）。
        case standardOnly
        /// 只有稅務帳印。
        case taxAccountOnly
        /// 兩個帳別都不印。項目仍可被勾選、仍進酬金與其他計算，只是不出現在服務範圍條列。
        case hidden
    }
}
