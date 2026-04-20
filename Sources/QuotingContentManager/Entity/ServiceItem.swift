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
    public let term: String?
    public var tags: [String]
    public let workItems: [WorkItem]

    public init(
        type: String,
        name: String,
        alias: String,
        primary: Bool,
        term: String? = nil,
        tags: [String] = [],
        workItems: [WorkItem] = []
    ) {
        self.type = type
        self.name = name
        self.alias = alias
        self.primary = primary
        self.term = term
        self.tags = tags
        self.workItems = workItems
    }

    public func workItem(type: String) -> WorkItem? {
        workItems.first { $0.type == type }
    }

    public func accepts(workItemType: String) -> Bool {
        workItems.contains { $0.type == workItemType }
    }


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
                ],
                workItems: [
                    .init(type: "accounting", name: "平時稅務會計帳務作業"),
                    .init(type: "fundingProcess", name: "資金流程製作"),
                    .init(type: "standardReporting", name: "標準報表編製"),
                    .init(type: "customizedReporting", name: "客製化報表編製"),
                    .init(type: "businessTaxFiling", name: "營業稅申報"),
                    .init(type: "costAnalysis", name: "成本表編製作業"),
                    .init(type: "financialSettlement", name: "年底會計之結算作業"),
                    .init(type: "provisionalIncomeTaxReturnFiling", name: "年度中暫繳申報"),
                    .init(type: "profitseekingEnterpriseIncomeTaxFiling", name: "營利事業所得稅申報作業"),
                    .init(type: "undistributedEarningsFiling", name: "未分配盈餘加徵百分之五結算申報作業"),
                    .init(type: "withholdingStatementFiling", name: "年度各類給付扣繳（股利）憑單開立與申報作業"),
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
                ],
                workItems: [
                    .init(type: "accountingReform", name: "會計帳務重整作業"),
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
                term: "財務報表均依照「審計準則」與「企業會計準則」查核並出具財務簽證查核報告書，包括會計師查核報告書、財務報表、財務報表附註及相關財務資訊等項目。",
                tags: [
                    "ServiceItem/FinancialComplianceAudit",
                    "Need/BusinessClientAssistance",
                ],
                workItems: [
                    .init(type: "financialComplianceAudit", name: "財務報表查核簽證"),
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
                term: "營利事業所得稅查核簽證主要係包括執行營利事業所得稅結算申報程序及依照「所得稅法」規定進行會計師查核簽證作業。\n未分配盈餘主要係包括未分配盈餘之申報與查核。",
                tags: [
                    "ServiceItem/TaxComplianceAudit",
                    "Need/BusinessClientAssistance",
                ],
                workItems: [
                    .init(type: "taxComplianceAudit", name: "營利事業所得稅查核簽證與未分配盈餘查核"),
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
                term: "由 貴公司委託出納事務相關處理作業，包括以下內容：",
                tags: [
                    "ServiceItem/CashierOperation"
                ],
                workItems: [
                    .init(type: "accountsReceivablePayablePostingAndOffsetting", name: "應收、應付款項立帳、沖銷及科目餘額編製"),
                    .init(type: "onlineBankingPaymentAggregator", name: "整理、彙總及輸入網銀付款資料"),
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
                term: "由 貴公司委託薪資人力相關支援作業，包括以下內容：",
                tags: [
                    "ServiceItem/PayrollSupportOperation"
                ],
                workItems: [
                    .init(type: "monthlyPayrollReviewOperation", name: "每月薪資複核作業"),
                    .init(type: "laborInsuranceOperation", name: "每月勞保、健保及勞退作業"),
                    .init(type: "secondGenerationNationalHealthInsuranceFiling", name: "二代健保申報作業"),
                    .init(type: "annualInsurancePaymentCertificate", name: "提供年度保險費繳納證明單"),
                    .init(type: "severancePayCalculation", name: "資遣費計算"),
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
                ],
                workItems: [
                    .init(type: "customized", name: "自訂"),
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
                term: "由 貴公司委託本事務所代理承辦相關工商登記，包括以下內容：",
                tags: [
                    "ServiceItem/CompanyRegistration"
                ],
                workItems: [
                    .init(type: "companyNameAndBusinessScopeReservation", name: "經濟部公司名稱預查"),
                    .init(type: "economicMinistryRegistration", name: "經濟部設立登記"),
                    .init(type: "regulationsGoverningAuditingAndAttestationCertification", name: "設立資本額查核簽證"),
                    .init(type: "antiMoneyLaunderingCertification", name: "防洗錢查核簽證"),
                    .init(type: "exporterImporterRegistration", name: "國貿局進出口登記"),
                    .init(type: "companyRegistration", name: "國稅局營業登記"),
                    .init(type: "uniformInvoicePurchasing", name: "國稅局購票證申報"),
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
                ],
                workItems: [
                    .init(type: "ctp", name: "年度CTP申報"),
                    .init(type: "ctpOfCompanyRegistration", name: "經濟部CTP申報事宜"),
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
                ],
                workItems: [
                    .init(type: "assistanceAnnualSupplementaryPremiumDeductionDetailsReporting", name: "年度補充保費扣費明細彙報"),
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
                ],
                workItems: [
                    .init(type: "assistanceWithCompanyCertificatationApplication", name: "代辦工商憑證申請"),
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
                ],
                workItems: [
                    .init(type: "assistanceWithCompanySeal", name: "代刻公司章(大)"),
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
                ],
                workItems: [
                    .init(type: "assistanceWithChairmanSeal", name: "代刻公司章(小)"),
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
                ],
                workItems: [
                    .init(type: "assistanceWithCompanyConvenienceSeal", name: "代刻公司便章(大)"),
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
                ],
                workItems: [
                    .init(type: "assistanceWithChairmanConvenienceSeal", name: "代刻公司便章(小)"),
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
                ],
                workItems: [
                    .init(type: "assistanceWithInvoiceSeal", name: "代刻發票章"),
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
                ],
                workItems: [
                    .init(type: "assistanceWithLaborAndHealthInsuranceInsuredUnitSetting", name: "代辦勞健保投保單位設立"),
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
                ],
                workItems: [
                    .init(type: "ownerOccupiedResidencePartForBusinessApplication", name: "自用住宅申請部分供營業用"),
                ])
        }
    }
}


