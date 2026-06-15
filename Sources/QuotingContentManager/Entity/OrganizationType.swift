//
//  OrganizationType.swift
//  QuotingContentManager
//

/// 報價案的組織型態。
///
/// 用於決定工商登記付款名稱使用的資本額 placeholder 種類(實收 / 登記 / 省略)。
public enum OrganizationType: String, Codable, Sendable, CaseIterable {
    case limitedCompany                   // 有限公司
    case companyLimitedByShares           // 股份有限公司
    case soleProprietorshipOrPartnership  // 獨資合夥
    case nonProfitOrganization            // 非營利事務組織
    case professionalPracticeIncome       // 執行業務所得
    case foreignCompany                   // 境外公司

    /// 工商登記名稱要使用的資本額 placeholder key(未含 `%…|exact%` 包裝),無資本額則為 `nil`。
    ///
    /// 規則:股份→實收(`PaidInCapital`)、有限/獨資合夥→登記(`RegisteredCapital`)、其餘三者→無。
    public var capitalPlaceholderKey: String? {
        switch self {
        case .companyLimitedByShares:
            "PaidInCapital"
        case .limitedCompany, .soleProprietorshipOrPartnership:
            "RegisteredCapital"
        case .nonProfitOrganization, .professionalPracticeIncome, .foreignCompany:
            nil
        }
    }
}
