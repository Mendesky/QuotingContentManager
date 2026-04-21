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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.name = try container.decode(String.self, forKey: .name)
        self.alias = try container.decode(String.self, forKey: .alias)
        self.primary = try container.decode(Bool.self, forKey: .primary)
        self.term = try container.decodeIfPresent(String.self, forKey: .term)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.workItems = try container.decodeIfPresent([WorkItem].self, forKey: .workItems) ?? []
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
                name: "會計帳務處理作業",
                alias: "記帳",
                primary: true,
                term: "由 貴公司委託本事務所代辦相關會計工作，包括以下內容：",
                tags: [
                    "ServiceItem/Accounting"
                ],
                workItems: [
                    .init(
                        type: "accounting",
                        content: "平時會計帳務作業",
                        taxAccountContent: "平時稅務帳務作業",
                        description: "憑證整理、傳票登打、相關帳簿與代編報表"
                    ),
                    .init(type: "fundingProcess", content: "資金流程作業"),
                    .init(type: "standardReporting", content: "標準報表編製"),
                    .init(type: "customizedReporting", content: "客製化報表編製"),
                    .init(type: "businessTaxFiling", content: "營業稅申報作業"),
                    .init(type: "costAnalysis", content: "成本表編製作業"),
                    .init(type: "financialSettlement", content: "年底結算作業"),
                    .init(type: "provisionalIncomeTaxReturnFiling", content: "年度中暫繳申報"),
                    .init(type: "profitseekingEnterpriseIncomeTaxFiling", content: "營利事業所得稅結算申報作業"),
                    .init(type: "undistributedEarningsFiling", content: "未分配盈餘結算申報作業"),
                    .init(type: "withholdingStatementFiling", content: "各類給付扣繳(股利)憑單申報作業"),
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
                    .init(type: "accountingReform", content: "會計帳務重整作業"),
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
                    .init(type: "financialComplianceAudit", content: "財務報表查核簽證"),
                ])
        }
    }

    public static var taxComplianceAudit: Self {
        get {
            .init(
                type: "TaxComplianceAudit",
                name: "營利事業所得稅查核簽證",
                alias: "稅簽",
                primary: true,
                term: "營利事業所得稅查核簽證主要係包括執行營利事業所得稅結算申報程序及依照「所得稅法」規定進行會計師查核簽證作業及國稅局查核事項協助。\n未分配盈餘主要係分配盈餘結算申報與查核。",
                tags: [
                    "ServiceItem/TaxComplianceAudit",
                    "Need/BusinessClientAssistance",
                ],
                workItems: [
                    .init(type: "taxComplianceAudit", content: "營利事業所得稅查核簽證與未分配盈餘查核"),
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
                    .init(type: "accountsReceivablePayablePostingAndOffsetting", content: "應收、應付款項立帳、沖銷及科目餘額編製"),
                    .init(type: "onlineBankingPaymentAggregator", content: "整理、彙總及輸入網銀付款資料"),
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
                    .init(
                        type: "monthlyPayrollReviewOperation",
                        content: "每月薪資複核作業",
                        subItems: [
                            "員工出、缺勤之薪資複核",
                            "薪資表、薪資條製作",
                            "薪資扣繳稅款及二代健保繳費計算作業",
                        ]
                    ),
                    .init(
                        type: "laborInsuranceOperation",
                        content: "每月勞、健保及勞工退休金作業",
                        subItems: [
                            "勞、健保及勞工退休金之核算",
                            "員工加、退保及調整作業",
                        ]
                    ),
                    .init(type: "secondGenerationNationalHealthInsuranceFiling", content: "二代健保申報作業"),
                    .init(type: "annualInsurancePaymentCertificate", content: "提供年度保險費繳納證明單"),
                    .init(type: "severancePayCalculation", content: "資遣費計算"),
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
                    .init(type: "customized", content: "自訂"),
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
                    .init(type: "companyNameAndBusinessScopeReservation", content: "經濟部公司名稱預查"),
                    .init(type: "economicMinistryRegistration", content: "經濟部設立登記"),
                    .init(type: "regulationsGoverningAuditingAndAttestationCertification", content: "設立資本額查核簽證"),
                    .init(type: "antiMoneyLaunderingCertification", content: "防洗錢查核簽證"),
                    .init(type: "exporterImporterRegistration", content: "國貿局進出口登記"),
                    .init(type: "companyRegistration", content: "國稅局營業登記"),
                    .init(type: "uniformInvoicePurchasing", content: "國稅局購票證申報"),
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
                    .init(type: "ctp", content: "年度CTP申報"),
                    .init(type: "ctpOfCompanyRegistration", content: "經濟部CTP申報事宜"),
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
                    .init(type: "assistanceAnnualSupplementaryPremiumDeductionDetailsReporting", content: "年度補充保費扣費明細彙報"),
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
                    .init(type: "assistanceWithCompanyCertificatationApplication", content: "代辦工商憑證申請"),
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
                    .init(type: "assistanceWithCompanySeal", content: "代刻公司章(大)"),
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
                    .init(type: "assistanceWithChairmanSeal", content: "代刻公司章(小)"),
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
                    .init(type: "assistanceWithCompanyConvenienceSeal", content: "代刻公司便章(大)"),
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
                    .init(type: "assistanceWithChairmanConvenienceSeal", content: "代刻公司便章(小)"),
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
                    .init(type: "assistanceWithInvoiceSeal", content: "代刻發票章"),
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
                    .init(type: "assistanceWithLaborAndHealthInsuranceInsuredUnitSetting", content: "代辦勞健保投保單位設立"),
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
                    .init(type: "ownerOccupiedResidencePartForBusinessApplication", content: "自用住宅申請部分供營業用"),
                ])
        }
    }
}


