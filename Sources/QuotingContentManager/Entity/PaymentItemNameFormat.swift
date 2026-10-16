/// PaymentItem 顯示名稱模板。
///
/// `template` 含兩種替換語法：
/// - `{name}` — 由 caller 端 substitute，通常代入 `serviceItem.displayName(for:)`
/// - `%PlaceholderKey%` — 留給 frontend 依 `GetTemplateVariables` API 回傳的 variables multi-pass 展開
///
/// 範例：
/// - `"%FinancialComplianceAuditStartYear%{name}"` 展開後 `民國115年財務報表查核簽證`
/// - `"{name} %AccountingStart%"` 展開後 `會計帳務處理作業 (115年6月開始)`
/// - `"{name}%PaidInCapital|exact%%CompanyRegistrationRegion%(不含動資查核)%CompanyRegistrationShareholder%"`
///   展開後 `工商登記處理作業(資本額1萬元)(雙北地區)(不含動資查核)(股東1人)`
public struct PaymentItemNameFormat: Codable, Sendable, Equatable {
    public let template: String

    /// 稅務帳專用的 template；nil 代表各帳別共用 `template`
    /// （與 `ServiceItem.taxAccountName` / `WorkItem.taxAccountContent` 同一個慣例）。
    ///
    /// 需要它的理由：酬金列的用字可以和服務名稱不同。記帳的稅務帳酬金寫「稅務申報服務(…開始)」，
    /// 不帶「作業」；但稅務帳的服務名稱是「稅務申報服務作業」（服務範圍標題、`%ServiceItemNames%` 在用），
    /// 用 `{name}` 會帶出「作業」，所以稅務帳另寫一份 template。
    public let taxAccountTemplate: String?

    /// 酬金名稱末尾要指回的合約注意事項（整理費(115年1-4月；註二)）；nil 代表不帶註號。
    ///
    /// **不寫進 `template`**：酬金名稱在新增服務項目時就存成快照（OC `PaymentItemAdded`），
    /// 註號卻要等報價單上的備註清單定案才算得出來，而且 `{…}` 不能離開 QCM（見 `ContentPlaceholder`）。
    /// 所以快照維持原樣，讀取端把名稱**展開之後**再交給 `NoteReference.attach(to:noteNumber:)` 接上註號 ——
    /// 既有報價單不必改酬金名稱，報價單上有那條備註就會帶出註號。
    public let noteReference: NoteReference?

    public init(template: String, taxAccountTemplate: String? = nil, noteReference: NoteReference? = nil) {
        self.template = template
        self.taxAccountTemplate = taxAccountTemplate
        self.noteReference = noteReference
    }

    /// 取該帳別的 template，將 `{name}` 替換為實際 service item 顯示名稱。`%xxx%` placeholder 保留交由 frontend 展開。
    public func resolve(name: String, for accountingCategory: AccountingCategory?) -> String {
        accountingCategory.pick(standard: template, taxAccount: taxAccountTemplate)
            .replacingOccurrences(of: ContentPlaceholder.name.rawValue, with: name)
    }

    /// 酬金名稱指回合約注意事項的寫法。
    ///
    /// 母版把註號寫在名稱末尾那組括號裡（整理費(115年1-4月；註二)），所以分兩種情形：
    /// 名稱以右括號結尾 → 插在右括號前；不是（整帳區間沒填、或使用者改過名稱）→ 另開一組括號接在後面。
    /// 兩種寫法（標點）都由 QCM 定，理由同 `ContractNoteReference`。
    public struct NoteReference: Codable, Sendable, Equatable {
        /// 被引用的備註在 `ContractNoteManager` 的 `uniqueCode`。
        public let contractNoteUniqueCode: String
        /// 名稱以右括號結尾時，插在右括號前的寫法；`{noteNo}` 換成註號（中文數字）。
        public let insideParenthesesTemplate: String
        /// 名稱不以右括號結尾時，接在名稱後的寫法；`{noteNo}` 換成註號（中文數字）。
        public let standaloneTemplate: String

        public init(contractNoteUniqueCode: String, insideParenthesesTemplate: String, standaloneTemplate: String) {
            self.contractNoteUniqueCode = contractNoteUniqueCode
            self.insideParenthesesTemplate = insideParenthesesTemplate
            self.standaloneTemplate = standaloneTemplate
        }

        /// 把註號接進**已展開**的酬金名稱。`noteNumber` 為 nil（報價單上沒有那條備註）時原樣回傳。
        ///
        /// 必須在 `%…%` 展開之後呼叫：快照裡的右括號在範本變數的值裡（`整理費%ReformPeriod%`），
        /// 展開前看不到。
        public func attach(to resolvedName: String, noteNumber: String?) -> String {
            guard let noteNumber else { return resolvedName }
            if let last = resolvedName.last, last == ")" || last == "）" {
                return String(resolvedName.dropLast()) + render(insideParenthesesTemplate, noteNumber) + String(last)
            }
            return resolvedName + render(standaloneTemplate, noteNumber)
        }

        private func render(_ template: String, _ noteNumber: String) -> String {
            template.replacingOccurrences(of: ContentPlaceholder.noteNo.rawValue, with: noteNumber)
        }
    }
}
