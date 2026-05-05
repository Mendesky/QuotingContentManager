import Testing
import Foundation
@testable import QuotingContentManager

@Suite("ServiceItem.additionalServiceNameFormat contract")
struct AdditionalServiceNameFormatTests {

    private static let assistanceItems: [ServiceItem] = [
        .ctp,
        .assistanceAnnualSupplementaryPremiumDeductionDetailsReporting,
        .assistanceWithCompanyCertificatationApplication,
        .assistanceWithCompanySeal,
        .assistanceWithChairmanSeal,
        .assistanceWithCompanyConvenienceSeal,
        .assistanceWithChairmanConvenienceSeal,
        .assistanceWithInvoiceSeal,
        .assistanceWithLaborAndHealthInsuranceInsuredUnitSetting,
    ]

    private static let nonAssistanceItems: [ServiceItem] = [
        .accounting,
        .accountingReform,
        .financialComplianceAudit,
        .taxComplianceAudit,
        .cashierOperation,
        .payrollSupportOperation,
        .customized,
        .companyRegistration,
        .ownerOccupiedResidencePartForBusinessApplication,
    ]

    @Test("9 個 Assistance/Ctp type 必須有 format")
    func assistanceTypesHaveFormat() {
        for item in Self.assistanceItems {
            #expect(item.additionalServiceNameFormat != nil, "\(item.type) 必須設定 additionalServiceNameFormat")
        }
    }

    @Test("非 Assistance type 不應有 format（avoid drift）")
    func nonAssistanceTypesHaveNoFormat() {
        for item in Self.nonAssistanceItems {
            #expect(item.additionalServiceNameFormat == nil, "\(item.type) 不應設定 additionalServiceNameFormat")
        }
    }

    @Test("requiresCount 與 template 含 {count} 對齊")
    func requiresCountMatchesTemplate() {
        for item in Self.assistanceItems {
            guard let format = item.additionalServiceNameFormat else {
                Issue.record("\(item.type) 沒有 format")
                continue
            }
            let containsCountToken = format.template.contains("{count}")
            #expect(
                format.requiresCount == containsCountToken,
                "\(item.type): requiresCount=\(format.requiresCount) 與 template 含 {count}=\(containsCountToken) 不一致"
            )
        }
    }

    @Test("template 含 {price}，且渲染後 placeholder 全部被替換")
    func tokensReplacedAfterRender() {
        for item in Self.assistanceItems {
            #expect(
                item.additionalServiceNameFormat?.template.contains("{price}") == true,
                "\(item.type): template 必須含 {price}"
            )
            let rendered = item.additionalServiceName(price: 1000, count: 3)
            #expect(rendered != nil, "\(item.type) 渲染回傳 nil")
            #expect(
                rendered?.contains("{price}") == false,
                "\(item.type) 渲染後仍含 {price}: \(rendered ?? "nil")"
            )
            #expect(
                rendered?.contains("{count}") == false,
                "\(item.type) 渲染後仍含 {count}: \(rendered ?? "nil")"
            )
        }
    }

    @Test("關鍵字眼必須出現在渲染輸出（防 typo 漂移）")
    func renderedNameContainsKeyPhrase() {
        let cases: [(item: ServiceItem, phrase: String)] = [
            (.ctp, "代辦年度CTP申報"),
            (.assistanceAnnualSupplementaryPremiumDeductionDetailsReporting, "代辦年度補充保費扣費明細彙報"),
            (.assistanceWithCompanyCertificatationApplication, "代辦工商憑證申請"),
            (.assistanceWithCompanySeal, "代刻公司章(大)"),
            (.assistanceWithChairmanSeal, "代刻公司章(小)"),
            (.assistanceWithCompanyConvenienceSeal, "代刻公司便章(大)"),
            (.assistanceWithChairmanConvenienceSeal, "代刻公司便章(小)"),
            (.assistanceWithInvoiceSeal, "代刻發票章"),
            (.assistanceWithLaborAndHealthInsuranceInsuredUnitSetting, "代辦勞健保投保單位設立"),
        ]
        for (item, phrase) in cases {
            let rendered = item.additionalServiceName(price: 1000, count: 3)
            #expect(
                rendered?.contains(phrase) == true,
                "\(item.type): 渲染輸出應含 '\(phrase)'，實得：\(rendered ?? "nil")"
            )
        }
    }

    @Test("additionalServiceName 在 format 為 nil 時回傳 nil")
    func returnsNilWhenFormatAbsent() {
        let rendered = ServiceItem.accounting.additionalServiceName(price: 1000, count: 3)
        #expect(rendered == nil)
    }
}
