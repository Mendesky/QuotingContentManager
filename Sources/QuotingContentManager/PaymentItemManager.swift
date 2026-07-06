//
//  PaymentItemManager.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/4/23.
//

public struct PaymentItemManager: Sendable {
    public var items: [Item] = [
        .init(
            uniqueCode: "1",
            content: "財務簽證依預估\(TemplateVariableConcept.financialComplianceAuditGroundName.placeholder())\(TemplateVariableConcept.financialComplianceAuditGroundAmount.placeholder())報價。",
            traits: ["ServiceItem/FinancialComplianceAudit"]
        ),
        .init(
            uniqueCode: "2",
            content: "稅務簽證依照預估年營收計\(TemplateVariableConcept.estimatedAnnualRevenue.placeholder())報價。",
            // 兩個 trait 並列（[Trait]，ANY-of 語意）— 同份 PaymentItem 同時對應「純稅簽」與
            // 「含未分配盈餘變體」兩個 ServiceItemType；business 拍板補充說明永遠一致。
            // 寫成兩個 trait 而非單一 trait 含兩個 tag，是為了讓 `fetchPaymentItems(serviceItem:)` 分別以
            // 「TaxComplianceAudit」或「TaxComplianceAuditAndUndistributedEarningsAudit」查詢都能命中。
            traits: [
                "ServiceItem/TaxComplianceAudit",
                "ServiceItem/TaxComplianceAuditAndUndistributedEarningsAudit",
            ]
        ),
        .init(
            uniqueCode: "3",
            content: "\(TemplateVariableConcept.accountingWorkName.placeholder())處理作業依照預估年營收計\(TemplateVariableConcept.estimatedAnnualRevenue.placeholder())報價。",
            traits: ["ServiceItem/Accounting"]
        ),
    ]

    public init() {}
}
