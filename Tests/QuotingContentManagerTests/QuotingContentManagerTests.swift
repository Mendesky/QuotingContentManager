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

// 記帳酬金名稱帶營所稅申報方式（PBI 3b81b546）：`{name}-%ProfitseekingEnterpriseIncomeTaxFiling% %AccountingStart%`，
// 展開後如「稅務帳務處理作業-書審申報 (設立完成後開始)」。裸 key＝預設長描述（書審申報），glance 可切短描述（書審）。
@Test func `accounting paymentItemName carries filing method placeholder`() async throws {
    let item = ServiceItem.accounting
    #expect(item.paymentItemName(forTaxAccount: true) == "稅務帳務處理作業-%ProfitseekingEnterpriseIncomeTaxFiling% %AccountingStart%")
    #expect(item.paymentItemName(forTaxAccount: false) == "會計帳務處理作業-%ProfitseekingEnterpriseIncomeTaxFiling% %AccountingStart%")
}

// 暫繳簽證：單一 workItem（複用記帳暫繳的 type 與文案）、無 term/scopeTerms（服務範圍呈現名稱＋條列）、
// 酬金模板 `%ProvisionalIncomeTaxAuditStartYear%之{name}`（值含「年度」由 OC contributor 供給）。
@Test func `provisionalIncomeTaxAudit is registered and matches contract`() async throws {
    let item = try #require(QuotingContentManager.standard.getServiceItem(type: "ProvisionalIncomeTaxAudit"))
    #expect(item.name == "暫繳簽證")
    #expect(item.primary == true)
    #expect(item.tags == ["ServiceItem/ProvisionalIncomeTaxAudit"])
    #expect(item.workItems.map(\.type) == ["provisionalIncomeTaxReturnFiling"])
    #expect(item.workItems.first?.content == "年度中暫繳申報")
    #expect(item.effectiveScopeTerms.isEmpty)
    #expect(item.paymentItemName(forTaxAccount: false) == "%ProvisionalIncomeTaxAuditStartYear%之暫繳簽證")
    #expect(item.paymentItemName(forTaxAccount: true) == "%ProvisionalIncomeTaxAuditStartYear%之暫繳簽證")  // 無 taxAccountName，兩者同
}
