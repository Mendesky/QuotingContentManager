//
//  ServiceItem.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

import Foundation

public struct ServiceItem: Codable, Sendable {
    public let type: String
    public let name: String
    public let taxAccountName: String?
    public let alias: String
    public let primary: Bool
    public let term: String?
    public var tags: [String]
    public let workItems: [WorkItem]
    public let scopeTerms: [ScopeTerm]
    /// 附加服務名稱顯示策略。`.flatName`（純名稱，如自用住宅或非附加服務）/ `.embedsPrice(format)`
    /// （名稱內嵌金額，如 CTP）。取代舊的 optional `additionalServiceNameFormat`——把「format 缺」的雙義
    /// 拆成顯式宣告，價格型一定帶 format（型別強制）。詳見 `AdditionalServiceNameStrategy`。
    public let additionalServiceNameStrategy: AdditionalServiceNameStrategy
    public let paymentItemNameFormat: PaymentItemNameFormat?
    /// 「這張卡沒有營所稅申報作業」時改用的酬金名稱模板。`nil` = 沒有這個分版，一律用
    /// `paymentItemNameFormat`（除記帳外的服務項目都是 nil）。
    ///
    /// **為什麼需要分版而不是讓變數解成空字串**：記帳的主模板是
    /// `{name}-%ProfitseekingEnterpriseIncomeTaxFiling% …`，那個連字號寫在**模板**裡。
    /// 沒有申報方式時把變數解成空字串，名稱會殘一個孤兒的「-」。
    ///
    /// **判準是「這張卡有沒有 profitseekingEnterpriseIncomeTaxFiling 工作項目」，不是帳別**：
    /// 管理帳的 validWorkItems 不含它，但**財務帳含**（財務帳＝全集）。用 `forTaxAccount`
    /// 當判準會把財務帳的申報方式一起砍掉。
    public let paymentItemNameFormatWithoutIncomeTaxFiling: PaymentItemNameFormat?

    public init(
        type: String,
        name: String,
        taxAccountName: String? = nil,
        alias: String,
        primary: Bool,
        term: String? = nil,
        tags: [String] = [],
        workItems: [WorkItem] = [],
        scopeTerms: [ScopeTerm] = [],
        additionalServiceNameStrategy: AdditionalServiceNameStrategy = .flatName,
        paymentItemNameFormat: PaymentItemNameFormat? = nil,
        paymentItemNameFormatWithoutIncomeTaxFiling: PaymentItemNameFormat? = nil
    ) {
        self.type = type
        self.name = name
        self.taxAccountName = taxAccountName
        self.alias = alias
        self.primary = primary
        self.term = term
        self.tags = tags
        self.workItems = workItems
        self.scopeTerms = scopeTerms
        self.additionalServiceNameStrategy = additionalServiceNameStrategy
        self.paymentItemNameFormat = paymentItemNameFormat
        self.paymentItemNameFormatWithoutIncomeTaxFiling = paymentItemNameFormatWithoutIncomeTaxFiling
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.name = try container.decode(String.self, forKey: .name)
        self.taxAccountName = try container.decodeIfPresent(String.self, forKey: .taxAccountName)
        self.alias = try container.decode(String.self, forKey: .alias)
        self.primary = try container.decode(Bool.self, forKey: .primary)
        self.term = try container.decodeIfPresent(String.self, forKey: .term)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.workItems = try container.decodeIfPresent([WorkItem].self, forKey: .workItems) ?? []
        self.scopeTerms = try container.decodeIfPresent([ScopeTerm].self, forKey: .scopeTerms) ?? []
        self.additionalServiceNameStrategy = try container.decodeIfPresent(AdditionalServiceNameStrategy.self, forKey: .additionalServiceNameStrategy) ?? .flatName
        self.paymentItemNameFormat = try container.decodeIfPresent(PaymentItemNameFormat.self, forKey: .paymentItemNameFormat)
        self.paymentItemNameFormatWithoutIncomeTaxFiling = try container.decodeIfPresent(PaymentItemNameFormat.self, forKey: .paymentItemNameFormatWithoutIncomeTaxFiling)
    }

    public var effectiveScopeTerms: [ScopeTerm] {
        if !scopeTerms.isEmpty { return scopeTerms }
        if let term { return [.init(name: name, content: term)] }
        return []
    }

    public func workItem(type: String) -> WorkItem? {
        workItems.first { $0.type == type }
    }

    public func accepts(workItemType: String) -> Bool {
        workItems.contains { $0.type == workItemType }
    }

    public func displayName(forTaxAccount isTaxAccount: Bool) -> String {
        isTaxAccount ? (taxAccountName ?? name) : name
    }

    /// 結合 `displayName(forTaxAccount:)` 與 `paymentItemNameFormat.template` 算出 paymentItem 顯示名稱。
    /// `{name}` 由本 method 替換為 displayName；`%xxx%` placeholder 保留交由 frontend 展開。
    /// 若 serviceItem 沒有設定 `paymentItemNameFormat`，回 nil（caller 端 fallback 為 displayName 即可）。
    /// - Parameter hasIncomeTaxFiling: 這張卡有沒有「營利事業所得稅結算申報作業」工作項目。
    ///   `false` 且本 serviceItem 有設 `paymentItemNameFormatWithoutIncomeTaxFiling` 時改用該版
    ///   （記帳專用；其餘服務項目沒有分版，傳什麼都一樣）。預設 `true` 讓既有呼叫端行為不變。
    public func paymentItemName(forTaxAccount isTaxAccount: Bool, hasIncomeTaxFiling: Bool = true) -> String? {
        let format = hasIncomeTaxFiling
            ? paymentItemNameFormat
            : (paymentItemNameFormatWithoutIncomeTaxFiling ?? paymentItemNameFormat)
        return format?.resolve(name: displayName(forTaxAccount: isTaxAccount))
    }


    // MARK: 主要服務項目
    public static var accounting: Self {
        get {
            .init(
                type: "Accounting",
                name: "會計帳務處理作業",
                taxAccountName: "稅務帳務處理作業",
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
                    .init(type: "provisionalIncomeTaxReturnFiling", content: "年度中暫繳申報"),
                    .init(type: "financialSettlement", content: "年底結算作業"),
                    .init(type: "withholdingStatementFiling", content: "各類給付扣繳(股利)憑單申報作業"),
                    .init(type: "profitseekingEnterpriseIncomeTaxFiling", content: "營利事業所得稅結算申報作業"),
                    .init(type: "undistributedEarningsFiling", content: "未分配盈餘結算申報作業"),
                    .init(type: "costAnalysis", content: "成本表編製作業"),
                ],
                // 酬金名稱帶營所稅申報方式（PBI 3b81b546）：展開後如「稅務帳務處理作業-書審申報 (設立完成後開始)」。
                // 裸 key＝預設長描述（書審申報），glance 可切短描述（書審）。
                paymentItemNameFormat: PaymentItemNameFormat(
                    template: "{name}-\(TemplateVariableConcept.profitseekingEnterpriseIncomeTaxFiling.placeholder()) \(TemplateVariableConcept.accountingStart.placeholder())"
                ),
                // 沒有「營利事業所得稅結算申報作業」工作項目的記帳卡（管理帳恆是；稅務帳／財務帳
                // 可由使用者取消勾選）——整段連同連字號拿掉，而不是讓變數解成空字串殘一個孤兒「-」。
                // 上游依 workItemTypes 決定用哪一版，不是依帳別：財務帳＝全集、含營所稅申報。
                paymentItemNameFormatWithoutIncomeTaxFiling: PaymentItemNameFormat(
                    template: "{name} \(TemplateVariableConcept.accountingStart.placeholder())"
                ))
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
                ],
                paymentItemNameFormat: PaymentItemNameFormat(
                    template: "{name}\(TemplateVariableConcept.reformPeriod.placeholder())"
                ))
        }
    }

    /// 一次性專案專用的獨立整帳卡（上游 `QuotingAggregate.ServiceItemType.projectAccountingReform`）。
    ///
    /// 與 `accountingReform` 是兩張不同的卡，差別在上游：那張恆掛在記帳卡之下、不進服務範圍；
    /// 這張不掛母卡、進服務範圍但**只印名稱**。
    ///
    /// **刻意不給 `term` / `scopeTerms`**：上游把它分類為 `.introOnly`，沒有 scopeTerm 時
    /// 渲染端只印標題那一行 —— 這正是產品要的「單純印名稱」。給了 term 反而會多印一段。
    ///
    /// **`workItems` 不可省略**：上游 `GetServiceScope` 會逐一 `serviceItem.workItem(type:)`，
    /// 查無即 throw，而那一步發生在讀 presentation 之前。「服務範圍不印條列」是呈現層的事，
    /// 不代表這裡可以不宣告 workItem。
    public static var projectAccountingReform: Self {
        get {
            .init(
                type: "ProjectAccountingReform",
                name: "會計帳務重整作業(專案)",
                alias: "專案整帳",
                primary: false,
                tags: [
                    "ServiceItem/ProjectAccountingReform"
                ],
                // type 是專屬的 `projectAccountingReform`，**不與 AccountingReform 共用**：
                // 共用會讓上游 checkDuplicateWorkItemTypesWithinBundle 擋掉「同 bundle 兩張整帳」，
                // 而那條限制業務上沒人要求過，純粹是 workItem 撞名的副作用。
                workItems: [
                    .init(type: "projectAccountingReform", content: "專案會計帳務重整作業"),
                ],
                // variant "project" 不可省略：上游算兩個 key —— `ReformPeriod`（給 accountingReform）
                // 與 `ReformPeriod|project`（給本卡）。寫成不帶 variant 的 `%ReformPeriod%`，
                // 跨 bundle 同時存在兩張整帳時，本卡的酬金名稱會靜默取到另一張的期間。
                paymentItemNameFormat: PaymentItemNameFormat(
                    template: "{name}\(TemplateVariableConcept.reformPeriod.placeholder(variant: "project"))"
                ))
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
                ],
                workItems: [
                    .init(type: "financialComplianceAudit", content: "財務報表查核簽證"),
                ],
                paymentItemNameFormat: PaymentItemNameFormat(
                    template: "\(TemplateVariableConcept.financialComplianceAuditStartYear.placeholder()){name}"
                ))
        }
    }

    public static var taxComplianceAudit: Self {
        get {
            .init(
                type: "TaxComplianceAudit",
                name: "營利事業所得稅查核簽證",
                alias: "稅簽",
                primary: true,
                tags: [
                    "ServiceItem/TaxComplianceAudit",
                ],
                workItems: [
                    .init(type: "taxComplianceAudit", content: "營利事業所得稅查核簽證"),
                ],
                scopeTerms: [
                    .init(
                        name: "營利事業所得稅查核簽證",
                        content: "營利事業所得稅查核簽證主要係包括執行營利事業所得稅結算申報程序及依照「所得稅法」規定進行會計師查核簽證作業及國稅局查核事項協助。"
                    ),
                ],
                paymentItemNameFormat: PaymentItemNameFormat(
                    template: "\(TemplateVariableConcept.taxComplianceAuditStartYear.placeholder()){name}"
                ))
        }
    }

    /// 「營利事業所得稅查核簽證 + 未分配盈餘查核」變體。
    /// 與既有 `taxComplianceAudit` 在 caller 端視為兩個獨立 ServiceItemType：
    /// - 純 `taxComplianceAudit`：行號（獨資合夥）等無法人盈餘可分配的情境
    /// - 本變體：一般公司型態
    ///
    /// 設計細節：
    /// - **`tags` 沿用 `ServiceItem/TaxComplianceAudit`**：下游 contractNoteManager / paymentItemManager 既有
    ///   tag-based matching（uniqueCode 5 / 6 / 12 / 13 / 2 等 entry 都以 `ServiceItem/TaxComplianceAudit` 觸發）
    ///   不需動，本變體會 inherit 相同 ContractNote / PaymentItem 補充說明（業務拍板：兩 type 補充說明永遠一致）。
    /// - **`workItems` 拆兩個**：`taxComplianceAudit` + `undistributedEarningsAudit`，與既有「純」變體的單一
    ///   workItem 結構不同（這是兩 type 在語意上的真正差異點）。
    /// - **`paymentItemNameFormat.template` 共用** `\(TemplateVariableConcept.taxComplianceAuditStartYear.placeholder()){name}`：年份 placeholder 對兩
    ///   變體都適用；{name} 自然 resolve 為本 ServiceItem 的 `name`（即「...與未分配盈餘查核」全名）。
    public static var taxComplianceAuditAndUndistributedEarningsAudit: Self {
        get {
            .init(
                type: "TaxComplianceAuditAndUndistributedEarningsAudit",
                name: "營利事業所得稅查核簽證與未分配盈餘查核",
                alias: "稅簽",
                primary: true,
                tags: [
                    "ServiceItem/TaxComplianceAudit",
                ],
                workItems: [
                    .init(type: "taxComplianceAudit", content: "營利事業所得稅查核簽證"),
                    .init(type: "undistributedEarningsAudit", content: "未分配盈餘查核"),
                ],
                scopeTerms: [
                    .init(
                        name: "營利事業所得稅查核簽證",
                        content: "營利事業所得稅查核簽證主要係包括執行營利事業所得稅結算申報程序及依照「所得稅法」規定進行會計師查核簽證作業及國稅局查核事項協助。"
                    ),
                    .init(
                        name: "未分配盈餘查核簽證",
                        content: "主要係分配盈餘結算申報與查核。"
                    ),
                ],
                paymentItemNameFormat: PaymentItemNameFormat(
                    template: "\(TemplateVariableConcept.taxComplianceAuditStartYear.placeholder()){name}"
                ))
        }
    }

    /// 暫繳簽證：對「年度中暫繳申報」做簽證。workItem 完全複用記帳的
    /// `provisionalIncomeTaxReturnFiling`（type 與文案皆同），業務上與「記帳含暫繳申報 workItem」
    /// 同 bundle 互斥（invariant 在 OpportunityContext AuditQuoting）。
    /// 無 term / scopeTerms：服務範圍呈現「名稱＋條列 workItem」（同 CTP 的 workItems-only 模式）。
    public static var provisionalIncomeTaxAudit: Self {
        get {
            .init(
                type: "ProvisionalIncomeTaxAudit",
                name: "暫繳簽證",
                alias: "暫繳簽證",
                primary: true,
                tags: [
                    "ServiceItem/ProvisionalIncomeTaxAudit",
                ],
                workItems: [
                    .init(type: "provisionalIncomeTaxReturnFiling", content: "年度中暫繳申報"),
                ],
                paymentItemNameFormat: PaymentItemNameFormat(
                    template: "\(TemplateVariableConcept.provisionalIncomeTaxAuditStartYear.placeholder())之{name}"
                ))
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

    // TODO: 等下游 enum 新增對應 case 再恢復
//    public static var settlementReview: Self {
//        get {
//            .init(
//                type: "SettlementReview",
//                name: "結算覆核",
//                alias: "覆核",
//                primary: false,
//                tags: [
//                    "ServiceItem/SettlementReview"
//                ])
//        }
//    }

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

    /// 工商登記服務項目(目錄/預設版)。
    ///
    /// 酬金名稱模板固定為 `{name}`（工商登記處理作業），不因組織型態變化。
    public static var companyRegistration: Self {
        get {
            companyRegistration(for: .companyLimitedByShares)
        }
    }

    /// 依組織型態回傳工商登記服務項目。酬金名稱不再依組織型態/資本額/地區/股東人數變化
    /// （這些案件細節改由報價單備註一承載，見 QCM ContractNoteManager uniqueCode "15"）；
    /// 保留 `organizationType` 參數是為了不動呼叫端簽名（OC `WhenCompanyRegistrationAdded` 沿用既有呼叫）。
    public static func companyRegistration(for organizationType: OrganizationType) -> Self {
        companyRegistration(paymentItemNameFormat: PaymentItemNameFormat(template: "{name}"))
    }

    /// 工商登記服務項目骨架(共用):帶入算好的 `paymentItemNameFormat`。
    private static func companyRegistration(paymentItemNameFormat: PaymentItemNameFormat) -> Self {
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
                .init(type: "companyNameAndBusinessScopeReservation", content: "公司名稱預查"),
                .init(type: "economicMinistryRegistration", content: "公司設立登記"),
                .init(type: "regulationsGoverningAuditingAndAttestationCertification", content: "設立資本額查核簽證"),
                .init(type: "antiMoneyLaunderingCertification", content: "防洗錢查核簽證"),
                .init(type: "exporterImporterRegistration", content: "國貿局進出口登記"),
                .init(type: "companyRegistration", content: "國稅局營業登記"),
                .init(type: "uniformInvoicePurchasing", content: "國稅局購票證申報"),
                .init(type: "ctpOfCompanyRegistration", content: "經濟部CTP申報事宜"),
            ],
            paymentItemNameFormat: paymentItemNameFormat)
    }

    // MARK: 附加服務項目
    public static var ctp: Self {
        get {
            .init(
                type: "Ctp",
                name: "年度CTP申報",
                alias: "CTP",
                primary: true,
                tags: [
                    "ServiceItem/Ctp"
                ],
                workItems: [
                    .init(type: "ctp", content: "年度CTP申報"),
                ],
                additionalServiceNameStrategy: .embedsPrice(AdditionalServiceNameFormat(
                    template: "代辦年度CTP申報(每年3月；加收 {price} 元/家)",
                    requiresCount: false
                )))
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
                ],
                additionalServiceNameStrategy: .embedsPrice(AdditionalServiceNameFormat(
                    template: "代辦年度補充保費扣費明細彙報(每年1月；加收 {price} 元/家)",
                    requiresCount: false
                )))
        }
    }

    // TODO: 等下游 enum 新增對應 case 再恢復
//    public static var assistanceRegistrationByJWServiceItem: Self {
//        get {
//            .init(
//                type: "AssistanceRegistrationByJWServiceItem",
//                name: "經濟部設立登記",
//                alias: "經濟部設立",
//                primary: true,
//                tags: [
//                    "ServiceItem/AssistanceRegistrationByJWServiceItem"
//                ])
//        }
//    }

    public static var assistanceWithCompanyCertificationApplication: Self {
        get {
            .init(
                type: "AssistanceWithCompanyCertificationApplication",
                name: "代辦工商憑證申請",
                alias: "工商憑證",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithCompanyCertificationApplication"
                ],
                workItems: [
                    .init(type: "assistanceWithCompanyCertificationApplication", content: "代辦工商憑證申請"),
                ],
                additionalServiceNameStrategy: .embedsPrice(AdditionalServiceNameFormat(
                    template: "代辦工商憑證申請(加收 {price} 元)",
                    requiresCount: false
                )))
        }
    }

    public static var assistanceWithCompanySeal: Self {
        get {
            .init(
                type: "AssistanceWithCompanySeal",
                name: "代刻公司章(大)",
                alias: "公司章(大)",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithCompanySeal"
                ],
                workItems: [
                    .init(type: "assistanceWithCompanySeal", content: "代刻公司章(大)"),
                ],
                additionalServiceNameStrategy: .embedsPrice(AdditionalServiceNameFormat(
                    template: "代刻公司章(大章) {count} 枚(加收 {price} 元)",
                    requiresCount: true
                )))
        }
    }

    public static var assistanceWithChairmanSeal: Self {
        get {
            .init(
                type: "AssistanceWithChairmanSeal",
                name: "代刻公司章(小)",
                alias: "公司章(小)",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithChairmanSeal"
                ],
                workItems: [
                    .init(type: "assistanceWithChairmanSeal", content: "代刻公司章(小)"),
                ],
                additionalServiceNameStrategy: .embedsPrice(AdditionalServiceNameFormat(
                    template: "代刻負責人章(小章) {count} 枚(加收 {price} 元)",
                    requiresCount: true
                )))
        }
    }

    public static var assistanceWithCompanyConvenienceSeal: Self {
        get {
            .init(
                type: "AssistanceWithCompanyConvenienceSeal",
                name: "代刻公司便章(大)",
                alias: "便章(大)",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithCompanyConvenienceSeal"
                ],
                workItems: [
                    .init(type: "assistanceWithCompanyConvenienceSeal", content: "代刻公司便章(大)"),
                ],
                additionalServiceNameStrategy: .embedsPrice(AdditionalServiceNameFormat(
                    template: "代刻公司便章(大)各 {count} 枚(加收 {price} 元)",
                    requiresCount: true
                )))
        }
    }

    public static var assistanceWithChairmanConvenienceSeal: Self {
        get {
            .init(
                type: "AssistanceWithChairmanConvenienceSeal",
                name: "代刻公司便章(小)",
                alias: "便章(小)",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithChairmanConvenienceSeal"
                ],
                workItems: [
                    .init(type: "assistanceWithChairmanConvenienceSeal", content: "代刻公司便章(小)"),
                ],
                additionalServiceNameStrategy: .embedsPrice(AdditionalServiceNameFormat(
                    template: "代刻公司便章(小)各 {count} 枚(加收 {price} 元)",
                    requiresCount: true
                )))
        }
    }

    public static var assistanceWithInvoiceSeal: Self {
        get {
            .init(
                type: "AssistanceWithInvoiceSeal",
                name: "代刻發票章",
                alias: "發票章",
                primary: true,
                tags: [
                    "ServiceItem/AssistanceWithInvoiceSeal"
                ],
                workItems: [
                    .init(type: "assistanceWithInvoiceSeal", content: "代刻發票章"),
                ],
                additionalServiceNameStrategy: .embedsPrice(AdditionalServiceNameFormat(
                    template: "代刻發票章 {count} 枚(加收 {price} 元)",
                    requiresCount: true
                )))
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
                ],
                additionalServiceNameStrategy: .embedsPrice(AdditionalServiceNameFormat(
                    template: "代辦勞健保投保單位設立(加收 {price} 元)",
                    requiresCount: false
                )))
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
                ],
                additionalServiceNameStrategy: .embedsPrice(AdditionalServiceNameFormat(
                    template: "自用住宅申請部分供營業用(加收 {price} 元)",
                    requiresCount: false
                )))
        }
    }
}


