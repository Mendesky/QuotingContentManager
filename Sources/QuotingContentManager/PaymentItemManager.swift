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
            content: "財務簽證依預估%FinancialComplianceAuditGroundName%%FinancialComplianceAuditGroundAmount%報價。",
            traits: ["ServiceItem/FinancialComplianceAudit"]
        ),
        .init(
            uniqueCode: "2",
            content: "稅務簽證依照預估年營收計%EstimatedRevenue%報價。",
            traits: ["ServiceItem/TaxComplianceAudit"]
        ),
        .init(
            uniqueCode: "3",
            content: "%AccountingWorkName%處理作業依照預估年營收計%EstimatedRevenue%報價。",
            traits: ["ServiceItem/Accounting"]
        ),
    ]

    public init() {}
}
