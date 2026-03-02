//
//  ServiceItem.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

public struct ServiceItem: Codable, Sendable {
    public let type: String
    public let name: String
    public let alias: String
    public let primary: Bool
    public var tags: [String]
    
    
    // MARK: 主要服務項目
    public static var accounting: Self {
        get {
            .init(
                type: "Accounting",
                name: "會計帳務作業",
                alias: "記帳",
                primary: true,
                tags: [
                    "ServiceItem/Accounting"
                ])
        }
    }

    public static var accountingReform: Self {
        get{
            .init(
                type: "AccountingReform",
                name: "會計帳務重整作業",
                alias: "整帳",
                primary: false,
                tags: [
                    "ServiceItem/AccountingReform"
                ])
        }
    }

    public static var financialComplianceAudit: Self {
        get {
            .init(
                type: "FinancialComplianceAudit",
                name: "財務報表查核簽證",
                alias: "財簽",
                primary: true,
                tags: [
                    "ServiceItem/FinancialComplianceAudit"
                ])
        }
    }

    public static var taxComplianceAudit: Self {
        get {
            .init(
                type: "TaxComplianceAudit",
                name: "財務報表查核簽證",
                alias: "稅簽",
                primary: true,
                tags: [
                    "ServiceItem/TaxComplianceAudit"
                ])
        }
    }

    public static var cashierOperation: Self {
        get {
            .init(
                type: "CashierOperation",
                name: "出納事務處理作業",
                alias: "出納",
                primary: true,
                tags: [
                    "ServiceItem/CashierOperation"
                ])
        }
    }

    public static var payrollSupportOperation: Self {
        get {
            .init(
                type: "PayrollSupportOperation",
                name: "薪資人力支援作業",
                alias: "薪資",
                primary: true,
                tags: [
                    "ServiceItem/PayrollSupportOperation"
                ])
        }
    }

    public static var settlementReview: Self {
        get {
            .init(
                type: "SettlementReview",
                name: "結算覆核",
                alias: "覆核",
                primary: false,
                tags: [
                    "ServiceItem/SettlementReview"
                ])
        }
    }

    public static var customized: Self {
        get {
            .init(
                type: "Customized",
                name: "自訂",
                alias: "自訂",
                primary: true,
                tags: [
                    "ServiceItem/Customized"
                ])
        }
    }

    public static var companyRegistration: Self {
        get {
            .init(
                type: "CompanyRegistration",
                name: "工商登記處理作業",
                alias: "工商登記",
                primary: true,
                tags: [
                    "ServiceItem/CompanyRegistration"
                ])
        }
    }

    // MARK: 附加服務項目
    public static var ctp: Self {
        get {
            .init(
                type: "CTP",
                name: "年度CTP申報",
                alias: "CTP",
                primary: true,
                tags: [
                    "ServiceItem/CTP"
                ])
        }
    }

    public static var assistanceAnnualSupplementaryPremiumDeductionDetailsReporting: Self {
        get {
            .init(
                type: "AssistanceAnnualSupplementaryPremiumDeductionDetailsReporting",
                name: "年度補充保費扣費明細彙報",
                alias: "補充保費",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceAnnualSupplementaryPremiumDeductionDetailsReporting"
                ])
        }
    }

    public static var assistanceRegistrationByJWServiceItem: Self {
        get {
            .init(
                type: "AssistanceRegistrationByJWServiceItem",
                name: "經濟部設立登記",
                alias: "經濟部設立",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceRegistrationByJWServiceItem"
                ])
        }
    }

    public static var assistanceWithCompanyCertificatationApplication: Self {
        get {
            .init(
                type: "AssistanceWithCompanyCertificatationApplication",
                name: "代辦工商憑證申請",
                alias: "工商憑證",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithCompanyCertificatationApplication"
                ])
        }
    }

    public static var assistanceWithCompanyCorporateSeal: Self {
        get {
            .init(
                type: "AssistanceWithCompanyCorporateSeal",
                name: "代刻公司章(大)",
                alias: "公司章(大)",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithCompanyCorporateSeal"
                ])
        }
    }

    public static var assistanceWithChairmanCorporateSeal: Self {
        get {
            .init(
                type: "AssistanceWithChairmanCorporateSeal",
                name: "代刻公司章(小)",
                alias: "公司章(小)",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithChairmanCorporateSeal"
                ])
        }
    }

    public static var assistanceWithCompanyStamps: Self {
        get {
            .init(
                type: "AssistanceWithCompanyStamps",
                name: "代刻公司便章(大)",
                alias: "便章(大)",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithCompanyStamps"
                ])
        }
    }

    public static var assistanceWithCompanyConvenienceStamps: Self {
        get {
            .init(
                type: "AssistanceWithCompanyConvenienceStamps",
                name: "代刻公司便章(小)",
                alias: "便章(小)",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithCompanyConvenienceStamps"
                ])
        }
    }

    public static var assistanceWithInvoiceStamp: Self {
        get {
            .init(
                type: "AssistanceWithInvoiceStamp",
                name: "代刻發票章",
                alias: "發票章",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithInvoiceStamp"
                ])
        }
    }

    public static var assistanceWithLaborAndHealthInsuranceInsuredUnitSetting: Self {
        get {
            .init(
                type: "AssistanceWithLaborAndHealthInsuranceInsuredUnitSetting",
                name: "代辦勞健保投保單位設立",
                alias: "勞健保設立",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithLaborAndHealthInsuranceInsuredUnitSetting"
                ])
        }
    }

    public static var ownerOccupiedResidencePartForBusinessApplication: Self {
        get {
            .init(
                type: "OwnerOccupiedResidencePartForBusinessApplication",
                name: "自用住宅申請部分供營業用",
                alias: "自住供營業",
                primary: true,
                tags: [
                    "ServiceItem/OwnerOccupiedResidencePartForBusinessApplication"
                ])
        }
    }
}


