extension QuotingContentManager {
    /// `%AccountingWorkName%` 的展開值。
    ///
    /// 1150828 母版改版後，這個值同時要服務兩種句型：
    /// - `提升整體%AccountingWorkName%品質`（目的、服務範圍）→「提升整體稅務申報服務品質」／「提升整體帳務整理品質」
    /// - `%AccountingWorkName%作業…`（酬金補充說明、記帳付款條件註）→「稅務申報服務作業…」／「帳務整理作業…」
    ///
    /// 這組值是唯一能讓上述四句共用同一份 template 的選擇。其餘三處（contractHeader、
    /// 協助事項③、rightsAndObligations）母版的稅務帳／一套帳句型本身不同（不只是名詞不同），
    /// 一個變數表達不了，改以各自的帳別變體承載，不走這個變數。
    public func accountingWorkDisplayName(for accountingCategory: AccountingCategory?) -> String {
        accountingCategory.pick(standard: "帳務整理", taxAccount: "稅務申報服務")
    }
}
