import Testing
@testable import QuotingContentManager

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}

// `workItems` 宣告序決定**服務範圍的條列順序**——OpportunityContext 的
// `GetServiceScopeApplicationService` 依宣告序輸出，改動此順序即改變報價單 PDF 與公費合約頁的條列順序。
//
// 這個順序**不影響**報價 UI 的工作項目 marker：mendesky-web 走 workItemType ↔ marker 的寫死對照
// （`p2-service-item-mapping.ts`，costAnalysis ↔ 'F-CA' / 'H-CA'），marker 與陣列位置無關。
// （本註解原本寫「宣告序 = marker 順序」，2026-10 核對前端後更正。）
//
// 1150828 母版把成本表挪到資金流程之後、營業稅之前（原本在陣列最後）。
@Test func `accounting workItems order drives service scope listing`() async throws {
    let expected = [
        "accounting",
        "fundingProcess",
        "costAnalysis",
        "standardReporting",
        "customizedReporting",
        "businessTaxFiling",
        "provisionalIncomeTaxReturnFiling",
        "financialSettlement",
        "withholdingStatementFiling",
        "profitseekingEnterpriseIncomeTaxFiling",
        "undistributedEarningsFiling",
    ]
    #expect(ServiceItem.accounting.workItems.map(\.type) == expected)
}

// 1150828 母版的酬金列只有「{名稱}(114年3月開始)」——營所稅申報方式那一段（PBI 3b81b546 加的）拿掉了。
// `%ProfitseekingEnterpriseIncomeTaxFiling%` 變數本身仍留在系統裡，只是這個 format 不再引用。
@Test func `accounting paymentItemName drops filing method segment`() async throws {
    let item = ServiceItem.accounting
    #expect(item.paymentItemName(for: .taxAccount) == "稅務申報服務%AccountingStart%")
    #expect(item.paymentItemName(for: .financialAccount) == "帳務整理作業%AccountingStart%")
    #expect(item.paymentItemNameFormat?.template.contains("ProfitseekingEnterpriseIncomeTaxFiling") == false)
    #expect(item.paymentItemNameFormat?.taxAccountTemplate?.contains("ProfitseekingEnterpriseIncomeTaxFiling") == false)
}

// 產業創新條例 23-3 申報：文案依 Notion PBI 已確認截圖。name 用全名（進服務範圍前言的 %ServiceItemNames%），
// 服務範圍為單一 scopeTerm（標題＋說明），酬金名稱的年度由 OC 依卡上「未分配盈餘年度」供給。
@Test func `industrialInnovationUndistributedEarningsFiling is registered and matches confirmed copy`() async throws {
    let item = try #require(QuotingContentManager.standard.getServiceItem(type: "IndustrialInnovationUndistributedEarningsFiling"))
    #expect(item.name == "產業創新條例第23條之3規定相關申報作業")
    #expect(item.alias == "產業創新條例23-3申報")
    #expect(item.primary == true)
    #expect(item.tags == ["ServiceItem/IndustrialInnovationUndistributedEarningsFiling"])
    #expect(item.workItems.map(\.type) == ["industrialInnovationUndistributedEarningsFiling"])
    #expect(item.workItems.first?.content == "產業創新條例23-3申報")
    let terms = item.effectiveScopeTerms(for: nil)
    #expect(terms.map(\.name) == ["產業創新條例第23條之3規定相關申報作業"])
    #expect(terms.first?.content == "公司或有限合夥事業適用產業創新條例第23條之3規定，填具「未分配盈餘實質投資明細表」及「產業創新條例申報減免稅額通報表」申報作業。")
    #expect(item.paymentItemName(for: nil) == "產業創新條例第23條之3規定相關申報作業-%IndustrialInnovationUndistributedEarningsYear%未分配盈餘申報")
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
    #expect(item.effectiveScopeTerms(for: .financialAccount).isEmpty)
    #expect(item.effectiveScopeTerms(for: .taxAccount).isEmpty)
    #expect(item.paymentItemName(for: .financialAccount) == "%ProvisionalIncomeTaxAuditStartYear%之暫繳簽證")
    #expect(item.paymentItemName(for: .taxAccount) == "%ProvisionalIncomeTaxAuditStartYear%之暫繳簽證")  // 無 taxAccountName，兩者同
}
