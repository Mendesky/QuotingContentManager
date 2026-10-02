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

/// 1150828 母版把加收金額改成「阿拉伯數字＋中文單位」且拿掉 `{price}` 前後的空格
/// （母版寫「加收2仟元/家」，不是「加收 2,000 元/家」，也不是國字大寫的「貳仟」）。
@Suite("附加服務金額的中文單位")
struct AdditionalServicePriceFormattingTests {

    private func rendered(_ price: Decimal) -> String {
        AdditionalServiceNameFormat(template: "加收{price}元", requiresCount: false)
            .render(price: price, count: nil)
    }

    @Test("百位以上逐級拆單位，餘數接在後面")
    func chineseUnits() {
        #expect(rendered(800) == "加收8佰元")
        #expect(rendered(1000) == "加收1仟元")
        #expect(rendered(1200) == "加收1仟2佰元")
        #expect(rendered(2000) == "加收2仟元")
        #expect(rendered(2500) == "加收2仟5佰元")
        #expect(rendered(3000) == "加收3仟元")
        #expect(rendered(20000) == "加收2萬元")
        #expect(rendered(25000) == "加收2萬5仟元")
        #expect(rendered(150) == "加收1佰50元")
    }

    // 不足百與非整數金額維持原本的千分位寫法——中文單位拆不出有意義的結果。
    // 非整數本來就會被既有的 `maximumFractionDigits = 0` 截掉小數，這裡只是釘住「不走中文單位」。
    @Test("不足百與非整數金額維持原寫法")
    func fallsBackBelowHundred() {
        #expect(rendered(0) == "加收0元")
        #expect(rendered(80) == "加收80元")
        #expect(rendered(Decimal(string: "1500.5")!) == "加收1,500元")
    }

    @Test("所有價格型模板都不再有 {price} 前後的空格")
    func noSurroundingSpaces() {
        var checked = 0
        for item in QuotingContentManager.standard.serviceItems {
            guard case let .embedsPrice(format) = item.additionalServiceNameStrategy else { continue }
            checked += 1
            #expect(!format.template.contains(" {price}"), "\(item.type): {price} 前仍有空格")
            #expect(!format.template.contains("{price} "), "\(item.type): {price} 後仍有空格")
        }
        #expect(checked == 10, "價格型附加服務應有 10 個，實得 \(checked)")
    }
}

/// 註號引用（`{noteRef}`）。
///
/// 1150828 母版的同意函把 CTP 與補充保費兩行末尾指回合約注意事項（「)(註四)」/「；註五)」）。
/// 號碼不固定（取決於該份報價單實際印出哪幾條備註），所以 QCM 只宣告「引用誰、怎麼寫」，
/// 號碼由呼叫端（OC `GetContractNotes` → `ContractNoteNumbering`）算出來餵進 `render`。
@Suite("附加服務的註號引用")
struct AdditionalServiceNoteReferenceTests {

    private static func format(of item: ServiceItem) -> AdditionalServiceNameFormat {
        guard case let .embedsPrice(format) = item.additionalServiceNameStrategy else {
            Issue.record("\(item.type) 不是 .embedsPrice")
            return .init(template: "", requiresCount: false)
        }
        return format
    }

    @Test("CTP：括號外另開一個括號寫註號")
    func ctpReference() {
        let format = Self.format(of: .ctp)
        #expect(format.noteReference?.contractNoteUniqueCode == "1")
        #expect(
            format.render(price: 2000, count: nil, noteNumber: "四")
                == "代辦年度CTP申報(每年3月；加收2仟元/家)(註四)"
        )
    }

    @Test("補充保費：註號寫在括號內，用分號接")
    func supplementaryPremiumReference() {
        let format = Self.format(of: .assistanceAnnualSupplementaryPremiumDeductionDetailsReporting)
        #expect(format.noteReference?.contractNoteUniqueCode == "7")
        #expect(
            format.render(price: 2000, count: nil, noteNumber: "五")
                == "代辦年度補充保費扣費明細彙報(每年1月；加收2仟元/家；註五)"
        )
    }

    /// 算不出註號時整段引用消失，而不是印出「(註)」這種殘缺的東西 ——
    /// 所以兩個 template 都必須讓「沒有引用」的版本自己讀得通（補充保費的右括號留在 template 裡）。
    @Test("沒有註號時引用整段消失，句子仍讀得通")
    func omitsReferenceWithoutNumber() {
        #expect(
            Self.format(of: .ctp).render(price: 2000, count: nil)
                == "代辦年度CTP申報(每年3月；加收2仟元/家)"
        )
        #expect(
            Self.format(of: .assistanceAnnualSupplementaryPremiumDeductionDetailsReporting)
                .render(price: 2000, count: nil)
                == "代辦年度補充保費扣費明細彙報(每年1月；加收2仟元/家)"
        )
    }

    /// 沒宣告 `noteReference` 的 format 給了號碼也不該憑空長出引用。
    @Test("未宣告引用的 format 給號碼也不印")
    func ignoresNumberWithoutDeclaredReference() {
        let format = AdditionalServiceNameFormat(template: "加收{price}元{noteRef}", requiresCount: false)
        #expect(format.render(price: 800, count: nil, noteNumber: "三") == "加收8佰元")
    }

    /// 宣告了引用，被引用的 uniqueCode 就得真的存在於 `ContractNoteManager`，
    /// 否則 OC 永遠查不到號碼、引用永遠不印，而且不會有任何錯誤。
    @Test("所有 noteReference 指到的 uniqueCode 都存在且未 deprecated")
    func referencedNotesExist() {
        var checked = 0
        for item in QuotingContentManager.standard.serviceItems {
            guard
                case let .embedsPrice(format) = item.additionalServiceNameStrategy,
                let reference = format.noteReference
            else { continue }
            checked += 1
            #expect(
                QuotingContentManager.standard.getNote(uniqueCode: reference.contractNoteUniqueCode) != nil,
                "\(item.type) 引用的備註 uniqueCode \(reference.contractNoteUniqueCode) 不存在"
            )
        }
        #expect(checked == 2, "目前只有 CTP 與補充保費兩條有註號引用，實得 \(checked)")
    }

    /// 有引用的 template 一定要留 `{noteRef}` 的位置，否則號碼算出來也插不進去。
    @Test("宣告了 noteReference 的 template 必含 {noteRef}")
    func templatesCarryPlaceholder() {
        for item in QuotingContentManager.standard.serviceItems {
            guard
                case let .embedsPrice(format) = item.additionalServiceNameStrategy,
                format.noteReference != nil
            else { continue }
            #expect(format.template.contains("{noteRef}"), "\(item.type) 宣告了引用卻沒有 {noteRef}")
        }
    }
}

/// 編號群組：備註自己不寫號碼，只宣告「我屬於哪個要連號的群組」。
@Suite("ContractNoteInfo.OptionGroup")
struct ContractNoteOptionGroupTests {

    @Test("附加服務選項的前綴用字")
    func additionalServicePrefix() {
        #expect(ContractNoteInfo.OptionGroup.additionalService.prefix(number: 1) == "附加服務選項1：")
        #expect(ContractNoteInfo.OptionGroup.additionalService.prefix(number: 2) == "附加服務選項2：")
    }

    /// 掛群組的備註內文**不可以**自己寫「附加服務選項N：」——改版前就是寫死在文案裡，
    /// 隱藏 CTP 之後剩下的那條仍自稱「選項2」。號碼只能由讀取端依最終清單算。
    @Test("掛了群組的備註內文不自帶序號前綴")
    func groupedNotesDoNotHardcodeNumbers() {
        var checked = 0
        for note in QuotingContentManager.standard.contractNoteManager.notes {
            guard note.optionGroup != nil else { continue }
            checked += 1
            #expect(!note.allSegmentsJoined.contains("附加服務選項"), "備註 \(note.uniqueCode) 的內文自己寫了序號")
        }
        #expect(checked == 2, "目前只有 CTP 與補充保費兩條備註掛群組，實得 \(checked)")
    }

    /// 反向釘住：有註號引用的附加服務，它引用的那條備註一定也要掛在編號群組裡
    /// （母版上這兩條就是同意函上那兩個「附加服務選項」）。
    @Test("被引用的備註都掛在附加服務群組")
    func referencedNotesAreGrouped() {
        for item in QuotingContentManager.standard.serviceItems {
            guard
                case let .embedsPrice(format) = item.additionalServiceNameStrategy,
                let reference = format.noteReference
            else { continue }
            let note = QuotingContentManager.standard.getNote(uniqueCode: reference.contractNoteUniqueCode)
            #expect(note?.optionGroup == .additionalService, "\(item.type) 引用的備註沒掛附加服務群組")
        }
    }
}
