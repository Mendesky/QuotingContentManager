import Testing
@testable import QuotingContentManager

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}

// `workItems` 宣告序 = 報價 UI 工作項目 marker 順序（mendesky-web `p2-template.model.ts` 的 A → B → …）。
// 下游（OpportunityContext 服務範圍 / 報價 PDF）以宣告序輸出文件清單，改動此順序即改變文件顯示順序。
@Test func `accounting workItems follow quote UI marker order`() async throws {
    let expected = [
        "accounting",
        "fundingProcess",
        "standardReporting",
        "customizedReporting",
        "businessTaxFiling",
        "provisionalIncomeTaxReturnFiling",
        "financialSettlement",
        "withholdingStatementFiling",
        "profitseekingEnterpriseIncomeTaxFiling",
        "undistributedEarningsFiling",
        "costAnalysis",
    ]
    #expect(ServiceItem.accounting.workItems.map(\.type) == expected)
}
