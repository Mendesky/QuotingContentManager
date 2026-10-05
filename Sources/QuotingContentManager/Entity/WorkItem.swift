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

    public init(
        type: String,
        content: String,
        taxAccountContent: String? = nil,
        soleProprietorshipOrPartnershipContent: String? = nil,
        description: String? = nil,
        subItems: [String] = []
    ) {
        self.type = type
        self.content = content
        self.taxAccountContent = taxAccountContent
        self.soleProprietorshipOrPartnershipContent = soleProprietorshipOrPartnershipContent
        self.description = description
        self.subItems = subItems
    }

    public func displayContent(forTaxAccount isTaxAccount: Bool) -> String {
        isTaxAccount ? (taxAccountContent ?? content) : content
    }

    /// 依帳別與組織型態取顯示內容：行號專用內容優先，其次才是帳別分流（`displayContent(forTaxAccount:)`）。
    ///
    /// 兩種變體目前不會出現在同一個 workItem（行號內容只在工商登記、稅務帳內容只在記帳），
    /// 優先序只是讓語意明確。`organizationType == nil`（呼叫端取不到型態）→ 退回帳別版，即公司原文。
    public func displayContent(forTaxAccount isTaxAccount: Bool, organizationType: OrganizationType?) -> String {
        if organizationType == .soleProprietorshipOrPartnership, let soleProprietorshipOrPartnershipContent {
            return soleProprietorshipOrPartnershipContent
        }
        return displayContent(forTaxAccount: isTaxAccount)
    }
}
