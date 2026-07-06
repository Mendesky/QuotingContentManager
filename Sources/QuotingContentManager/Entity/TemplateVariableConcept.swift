/// 範本變數「概念」的**單一真值**（詞彙 + 層級都定義在此）。
///
/// QCM 擁有報價文本的詞彙：模板裡的 `%AccountingStart%` 等 placeholder「存在」是 QCM 的事，
/// 而**「該 placeholder 的值在哪個層級變動」（grouping / case / bundle）也是這個詞彙的語意屬性**，
/// 一併定義在此。消費端（OpportunityContext 算值 + 前端 render/限定）一律以此為準：
///
/// - **層級由 exhaustive `switch scope` 決定** → 新增 case 未分層 = **編譯失敗**（層級單一真值的保證）。
/// - 消費端用 `concept.placeholder(variant:)` / `.key(variant:)` 取字串，**concept 字串只存在此處一份**，
///   避免「散落各處手打、一調整就靜默 drift」。
///
/// `scope` 是**內容語意**（值在此層級變動），刻意**不涉及** OpportunityContext 的 aggregate 結構、
/// 也不涉及 `|Case|Bundle` 這套限定機制——那些是消費端如何「詮釋」此語意，不屬 QCM。
///
/// **變體（variant）** 如 `long`/`short`（申報方式）、`exact`/`fuzzy`（資本額）是同一概念的顯示選項，
/// 不影響層級，由消費端以 `variant:` 附加。
public enum TemplateVariableConcept: String, CaseIterable, Sendable, Codable {
    // grouping 級
    case defaultFromName = "DefaultFromName"
    case serviceItemNames = "ServiceItemNames"
    case accountingWorkName = "AccountingWorkName"

    // case 級
    case quotingCaseName = "QuotingCaseName"
    case defaultToName = "DefaultToName"
    case totalAssets = "TotalAssets"
    case estimatedAnnualRevenue = "EstimatedAnnualRevenue"
    case paidInCapital = "PaidInCapital"
    case registeredCapital = "RegisteredCapital"
    case financialComplianceAuditGroundName = "FinancialComplianceAuditGroundName"
    case financialComplianceAuditGroundAmount = "FinancialComplianceAuditGroundAmount"
    case defaultAccountingPaymentItemSupplementaryNote = "DefaultAccountingPaymentItemSupplementaryNote"
    case defaultFinancialComplianceAuditPaymentItemSupplementaryNote = "DefaultFinancialComplianceAuditPaymentItemSupplementaryNote"
    case defaultTaxComplianceAuditPaymentItemSupplementaryNote = "DefaultTaxComplianceAuditPaymentItemSupplementaryNote"

    // bundle 級
    case accountingStart = "AccountingStart"
    case reformPeriod = "ReformPeriod"
    case financialComplianceAuditStartYear = "FinancialComplianceAuditStartYear"
    case taxComplianceAuditStartYear = "TaxComplianceAuditStartYear"
    case companyRegistrationRegion = "CompanyRegistrationRegion"
    case companyRegistrationShareholder = "CompanyRegistrationShareholder"
    case profitseekingEnterpriseIncomeTaxFiling = "ProfitseekingEnterpriseIncomeTaxFiling"
    case accountingPeriod = "AccountingPeriod"
    case accountingBilling = "AccountingBilling"
    case cashierPeriod = "CashierPeriod"
    case cashierBilling = "CashierBilling"
    case payrollSupportPeriod = "PayrollSupportPeriod"
    case payrollSupportBilling = "PayrollSupportBilling"

    /// 值在哪個層級變動（內容語意）。
    public enum Scope: String, Sendable, Codable {
        case grouping
        case caseLevel
        case bundle
    }

    /// **exhaustive switch**：新增 case 未在此分層 → 編譯失敗（層級單一真值）。
    public var scope: Scope {
        switch self {
        case .defaultFromName, .serviceItemNames, .accountingWorkName:
            return .grouping
        case .quotingCaseName, .defaultToName, .totalAssets, .estimatedAnnualRevenue,
             .paidInCapital, .registeredCapital,
             .financialComplianceAuditGroundName, .financialComplianceAuditGroundAmount,
             .defaultAccountingPaymentItemSupplementaryNote,
             .defaultFinancialComplianceAuditPaymentItemSupplementaryNote,
             .defaultTaxComplianceAuditPaymentItemSupplementaryNote:
            return .caseLevel
        case .accountingStart, .reformPeriod,
             .financialComplianceAuditStartYear, .taxComplianceAuditStartYear,
             .companyRegistrationRegion, .companyRegistrationShareholder,
             .profitseekingEnterpriseIncomeTaxFiling,
             .accountingPeriod, .accountingBilling,
             .cashierPeriod, .cashierBilling,
             .payrollSupportPeriod, .payrollSupportBilling:
            return .bundle
        }
    }

    /// placeholder key（不含 `%`）：`rawValue` 或 `rawValue|variant`。
    public func key(variant: String? = nil) -> String {
        variant.map { "\(rawValue)|\($0)" } ?? rawValue
    }

    /// 完整 placeholder（含 `%`）：供模板字串引用，避免手打 `%AccountingStart%`。
    public func placeholder(variant: String? = nil) -> String {
        "%\(key(variant: variant))%"
    }
}
