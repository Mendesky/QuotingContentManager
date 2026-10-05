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

    public init(template: String, taxAccountTemplate: String? = nil) {
        self.template = template
        self.taxAccountTemplate = taxAccountTemplate
    }

    /// 取該帳別的 template，將 `{name}` 替換為實際 service item 顯示名稱。`%xxx%` placeholder 保留交由 frontend 展開。
    public func resolve(name: String, for accountingCategory: AccountingCategory?) -> String {
        accountingCategory.pick(standard: template, taxAccount: taxAccountTemplate)
            .replacingOccurrences(of: ContentPlaceholder.name.rawValue, with: name)
    }
}
