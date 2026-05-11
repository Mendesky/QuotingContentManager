/// PaymentItem 顯示名稱模板。
///
/// `template` 含兩種替換語法：
/// - `{name}` — 由 caller 端 substitute，通常代入 `serviceItem.displayName(forTaxAccount:)`
/// - `%PlaceholderKey%` — 留給 frontend 依 `GetTemplateVariables` API 回傳的 variables multi-pass 展開
///
/// 範例：
/// - `"%FinancialComplianceAuditStartYear%{name}"` 展開後 `民國115年財務報表查核簽證`
/// - `"{name} %AccountingStart%"` 展開後 `會計帳務處理作業 (115年6月開始)`
/// - `"{name}%PaidInCapital|exact%%CompanyRegistrationRegion%(不含動資查核)%CompanyRegistrationShareholder%"`
///   展開後 `工商登記處理作業(資本額1萬元)(雙北地區)(不含動資查核)(股東1人)`
public struct PaymentItemNameFormat: Codable, Sendable, Equatable {
    public let template: String

    public init(template: String) {
        self.template = template
    }

    /// 將 `{name}` 替換為實際 service item 顯示名稱。`%xxx%` placeholder 保留交由 frontend 展開。
    public func resolve(name: String) -> String {
        template.replacingOccurrences(of: "{name}", with: name)
    }
}
