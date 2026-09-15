import Testing
import Foundation
@testable import QuotingContentManager

@Suite("ServiceItem.additionalServiceNameStrategy contract")
struct AdditionalServiceNameStrategyTests {

    /// 價格型附加服務：名稱內嵌金額，策略必為 `.embedsPrice`（型別強制帶 format）。
    private static let priceEmbeddingItems: [ServiceItem] = [
        .ctp,
        .assistanceAnnualSupplementaryPremiumDeductionDetailsReporting,
        .assistanceWithCompanyCertificationApplication,
        .assistanceWithCompanySeal,
        .assistanceWithChairmanSeal,
        .assistanceWithCompanyConvenienceSeal,
        .assistanceWithChairmanConvenienceSeal,
        .assistanceWithInvoiceSeal,
        .assistanceWithLaborAndHealthInsuranceInsuredUnitSetting,
        // 自用住宅：2026-07 起改為 .embedsPrice（PDF 需顯示加收金額），不再是純名稱項目。
        .ownerOccupiedResidencePartForBusinessApplication,
    ]

    /// 純名稱項目：一般服務，策略必為 `.flatName`。
    /// （自用住宅原屬此列，2026-07 改為 `.embedsPrice` 後已移至 `priceEmbeddingItems`。）
    private static let flatNameItems: [ServiceItem] = [
        .accounting,
        .accountingReform,
        .financialComplianceAudit,
        .taxComplianceAudit,
        .provisionalIncomeTaxAudit,
        .cashierOperation,
        .payrollSupportOperation,
        .customized,
        .companyRegistration,
    ]

    private static func format(of item: ServiceItem) -> AdditionalServiceNameFormat? {
        if case .embedsPrice(let format) = item.additionalServiceNameStrategy { return format }
        return nil
    }

    @Test("價格型 type 策略必為 .embedsPrice（型別保證帶 format，不可能漏設）")
    func priceEmbeddingTypesUseEmbedsPrice() {
        for item in Self.priceEmbeddingItems {
            #expect(Self.format(of: item) != nil, "\(item.type) 必須是 .embedsPrice")
        }
    }

    @Test("純名稱 type 策略必為 .flatName（avoid drift）")
    func flatNameTypesUseFlatName() {
        for item in Self.flatNameItems {
            #expect(item.additionalServiceNameStrategy == .flatName, "\(item.type) 應為 .flatName")
        }
    }

    @Test("requiresCount 與 template 含 {count} 對齊")
    func requiresCountMatchesTemplate() {
        for item in Self.priceEmbeddingItems {
            guard let format = Self.format(of: item) else {
                Issue.record("\(item.type) 不是 .embedsPrice")
                continue
            }
            let containsCountToken = format.template.contains("{count}")
            #expect(
                format.requiresCount == containsCountToken,
                "\(item.type): requiresCount=\(format.requiresCount) 與 template 含 {count}=\(containsCountToken) 不一致"
            )
        }
    }

    @Test("template 含 {price}，且 render 後 placeholder 全部被替換")
    func tokensReplacedAfterRender() {
        for item in Self.priceEmbeddingItems {
            guard let format = Self.format(of: item) else {
                Issue.record("\(item.type) 不是 .embedsPrice")
                continue
            }
            #expect(format.template.contains("{price}"), "\(item.type): template 必須含 {price}")
            let rendered = format.render(price: 1000, count: 3)
            #expect(!rendered.contains("{price}"), "\(item.type) render 後仍含 {price}: \(rendered)")
            #expect(!rendered.contains("{count}"), "\(item.type) render 後仍含 {count}: \(rendered)")
        }
    }

    @Test("關鍵字眼必須出現在 render 輸出（防 typo 漂移）")
    func renderedNameContainsKeyPhrase() {
        let cases: [(item: ServiceItem, phrase: String)] = [
            (.ctp, "代辦年度CTP申報"),
            (.assistanceAnnualSupplementaryPremiumDeductionDetailsReporting, "代辦年度補充保費扣費明細彙報"),
            (.assistanceWithCompanyCertificationApplication, "代辦工商憑證申請"),
            (.assistanceWithCompanySeal, "代刻公司章(大章)"),
            // 負責人章：template 的字眼與 catalog `name`（代刻公司章(小)）刻意不同，以 template 為準。
            (.assistanceWithChairmanSeal, "代刻負責人章(小章)"),
            (.assistanceWithCompanyConvenienceSeal, "代刻公司便章(大)"),
            (.assistanceWithChairmanConvenienceSeal, "代刻公司便章(小)"),
            (.assistanceWithInvoiceSeal, "代刻發票章"),
            (.assistanceWithLaborAndHealthInsuranceInsuredUnitSetting, "代辦勞健保投保單位設立"),
        ]
        for (item, phrase) in cases {
            guard let format = Self.format(of: item) else {
                Issue.record("\(item.type) 不是 .embedsPrice")
                continue
            }
            let rendered = format.render(price: 1000, count: 3)
            #expect(rendered.contains(phrase), "\(item.type): render 輸出應含 '\(phrase)'，實得：\(rendered)")
        }
    }
}
