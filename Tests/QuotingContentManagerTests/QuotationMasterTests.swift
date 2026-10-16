import Testing
@testable import QuotingContentManager

/// 現行報價單母版（藍儀 CPA，1150917 最終版）的內容契約。
///
/// **母版測試只有這一份。** 改版時直接改這裡的期望值，不要另開「某版差異」的檔案——
/// 同一句話被兩個檔案釘住，下次改版就得改兩處，而且很容易只改到一處（1150828、1150917 曾各一份，已合併）。
/// 歷次改版改了什麼看 git log；這裡只寫「現在應該長怎樣」，舊用字以「不得出現」的斷言防止回頭。
///
/// 母版兩份：A 稅務帳（`.taxAccount`）、B 一套帳（`.financialAccount`）。句型在兩份之間不同的，斷言成對。
/// 多數期望值是「`%AccountingWorkName%` 展開後」的成品字串：變數值由第一組測試釘住，
/// 其餘用 `expanded(_:for:)` 做同樣的替換再比對，避免「值改了但句子沒跟著對」溜過去。
enum CurrentMaster {
    static let qcm = QuotingContentManager.standard

    /// 母版 A。
    static let tax: AccountingCategory = .taxAccount
    /// 母版 B（一套帳）。
    static let standard: AccountingCategory = .financialAccount
    /// 兩份母版，給「兩邊都要成立」的斷言用。
    static let both: [AccountingCategory] = [tax, standard]

    static func expanded(_ text: String, for category: AccountingCategory?) -> String {
        text.replacingOccurrences(
            of: TemplateVariableConcept.accountingWorkName.placeholder(),
            with: qcm.accountingWorkDisplayName(for: category)
        )
    }
}

// MARK: - 帳別與共用變數

@Suite("現行母版 — 帳別與共用變數")
struct CurrentMasterVariableTests {

    private let qcm = CurrentMaster.qcm

    /// 「哪些帳別印稅務帳版文案」的決策表。改這張表等於改所有分帳別的文案，所以每一格都釘住。
    @Test("只有稅務帳印稅務帳版；純簽證、管理帳、財務帳與判定不出帳別都印一般版")
    func onlyTaxAccountUsesTaxAccountCopy() {
        for category in AccountingCategory.allCases {
            let category = Optional(category)
            #expect(category.usesTaxAccountCopy == (category == .taxAccount), "\(String(describing: category))")
        }
        #expect(AccountingCategory?.none.usesTaxAccountCopy == false)
    }

    // 這組值是唯一能讓「目的／服務範圍／酬金補充說明／記帳付款條件註」四句共用同一份 template
    // 的選擇。改它就要重新驗下面所有展開後的期望值。
    @Test("%AccountingWorkName% 的值")
    func accountingWorkName() {
        #expect(qcm.accountingWorkDisplayName(for: .taxAccount) == "稅務申報服務")
        for category in AccountingCategory.allCases where category != .taxAccount {
            #expect(qcm.accountingWorkDisplayName(for: category) == "帳務整理", "\(category)")
        }
        #expect(qcm.accountingWorkDisplayName(for: nil) == "帳務整理")
    }

    @Test("目的與服務範圍共用同一份 template，兩個帳別都對上母版")
    func purposeAndServiceScopeShareTemplate() {
        for copywriting in [qcm.purpose, qcm.serviceScope] {
            #expect(CurrentMaster.expanded(copywriting.content, for: CurrentMaster.tax).contains("提升整體稅務申報服務品質"))
            #expect(CurrentMaster.expanded(copywriting.content, for: CurrentMaster.standard).contains("提升整體帳務整理品質"))
            // 共用代表沒有帳別變體。
            #expect(copywriting.taxAccountContent == nil)
        }
    }

    /// 稅務帳母版原句（%ServiceItemNames% 以財簽＋稅簽＋記帳展開）：
    /// 「本項專案作業之服務範圍將根據相關稅務法令、企業會計準則、會計師查核簽證規則及辦法之規定，由 貴公司委託
    /// 本事務所辦理有關財務報表查核簽證、營利事業所得稅查核簽證與未分配盈餘查核簽證及稅務申報服務作業之專業服務，
    /// 俾能符合相關法令規定與提升整體稅務申報服務品質。有關具體服務事項如下：」
    @Test("服務範圍前言：依「會計師查核簽證規則及辦法」之規定")
    func serviceScopeHeading() {
        let serviceItemNames = TemplateVariableConcept.serviceItemNames.placeholder()
        let tax = CurrentMaster.expanded(qcm.serviceScope.content, for: CurrentMaster.tax)
        #expect(tax == "本項專案作業之服務範圍將根據相關稅務法令、企業會計準則、會計師查核簽證規則及辦法之規定，由 貴公司委託本事務所辦理有關\(serviceItemNames)之專業服務，俾能符合相關法令規定與提升整體稅務申報服務品質。有關具體服務事項如下：")
        #expect(!qcm.serviceScope.content.contains("會計師查核簽證準則"), "舊用字不得出現")
    }

    @Test("酬金補充說明與記帳付款條件註共用 template，且不寫死「處理」")
    func paymentItemAndAccountingNoteShareTemplate() throws {
        let supplementary = try #require(qcm.fetchPaymentItems(serviceItem: "Accounting").first).content
        #expect(CurrentMaster.expanded(supplementary, for: CurrentMaster.tax).hasPrefix("稅務申報服務作業依照預估年營收計"))
        #expect(CurrentMaster.expanded(supplementary, for: CurrentMaster.standard).hasPrefix("帳務整理作業依照預估年營收計"))

        // 記帳的付款條件在註二裡，用 allSegmentsJoined 取整條來驗用字。
        let paymentNote = try #require(qcm.getNote(uniqueCode: "21")).allSegmentsJoined
        #expect(CurrentMaster.expanded(paymentNote, for: CurrentMaster.tax).contains("稅務申報服務作業費用"))
        #expect(CurrentMaster.expanded(paymentNote, for: CurrentMaster.standard).contains("帳務整理作業費用"))
        #expect(!paymentNote.contains("處理作業費用"))
    }
}

// MARK: - 信件與合約說明

@Suite("現行母版 — 信件與合約說明")
struct CurrentMasterLetterAndHeaderTests {

    private let qcm = CurrentMaster.qcm

    /// 受文公司名換成「貴公司」——信件不顯示公司名稱。
    @Test("信件：不顯示公司名稱，改「貴公司」")
    func letterUsesHonorificInsteadOfCompanyName() {
        let content = qcm.letter.content
        #expect(content.hasPrefix("茲將附上 貴公司有關"))
        #expect(!content.contains(TemplateVariableConcept.quotingCaseName.placeholder()), "信件不該再帶公司名變數")
    }

    @Test("主旨：「分別說明如後」用「後」不用「后」")
    func contractHeaderSubjectUsesHou() {
        #expect(qcm.contractHeader.title.contains("謹將服務內容及酬金等分別說明如後，敬請卓察賜覆為禱。"))
    }

    /// 「后」在這份文件裡都是「後」的誤植（說明如後、概述如後…），整份目錄掃一遍，不只主旨。
    @Test("全部文案不出現「后」")
    func noVariantHouAnywhere() {
        for entry in QCMTextCatalog.all() {
            #expect(!entry.text.contains("后"), "\(entry.location) 出現「后」，應為「後」")
        }
    }

    /// 「貴公司」前面一律用半形空格（2026-10-08 使用者裁定）。原本混著全形空格（挪抬）與半形空格，
    /// 整份目錄掃一遍，之後新增的文案混進全形空格就會紅。
    @Test("全部文案不出現全形空格")
    func noIdeographicSpaceAnywhere() {
        for entry in QCMTextCatalog.all() {
            #expect(!entry.text.contains("\u{3000}"), "\(entry.location) 出現全形空格，「貴公司」前面請用半形空格")
        }
    }

    /// 兩份母版句型不同（不只是名詞不同），一個變數表達不了，所以句子本身有兩版。
    @Test("合約說明：稅務帳版把「稅務申報」寫死")
    func contractHeaderSplitsByAccountType() {
        let header = qcm.contractHeader
        #expect(CurrentMaster.expanded(header.displayContent(for: CurrentMaster.tax), for: CurrentMaster.tax).contains("提升稅務申報品質"))
        #expect(CurrentMaster.expanded(header.displayContent(for: CurrentMaster.standard), for: CurrentMaster.standard).contains("提升帳務整理品質"))
        // 稅務版若誤用 %AccountingWorkName%，展開會多出「服務」兩字。
        #expect(!header.displayContent(for: CurrentMaster.tax).contains(TemplateVariableConcept.accountingWorkName.placeholder()))
    }
}

// MARK: - 協助事項

@Suite("現行母版 — 協助事項")
struct CurrentMasterBusinessClientAssistanceTests {

    private let qcm = CurrentMaster.qcm

    /// 協助事項③「配合及時提供相關資訊」= uniqueCode 3。
    private func itemThree() throws -> BusinessClientAssistanceManager.Item {
        try #require(qcm.businessClientAssistanceManager.items.first { $0.uniqueCode == "3" })
    }

    @Test("協助事項③：稅務帳接「作業」、一套帳接「工作」")
    func splitsByAccountType() throws {
        let item = try itemThree()
        let tax = CurrentMaster.expanded(item.displayContent(for: CurrentMaster.tax), for: CurrentMaster.tax)
        let standard = CurrentMaster.expanded(item.displayContent(for: CurrentMaster.standard), for: CurrentMaster.standard)

        #expect(tax.contains("應對稅務申報服務作業儘量協助"))
        #expect(standard.contains("應對帳務整理工作儘量協助"))
        // 稅務版獨有的改寫。
        #expect(tax.contains("簽證或稅務申報服務無法於法定期間內完成"))
        #expect(standard.contains("簽證或服務無法於法定期間內完成"))
        // 末句兩版相同。
        #expect(tax.hasSuffix("且本事務所得依第六點(二)之時間終止受託。"))
        #expect(standard.hasSuffix("且本事務所得依第六點(二)之時間終止受託。"))
    }

    /// 兩個帳別都沒有「對帳」、用「彙集」不用「蒐集」；「如法定期間」是錯字。
    @Test("協助事項③：憑證彙集，沒有「如法定期間」錯字")
    func wordingFixes() throws {
        let item = try itemThree()
        for category in CurrentMaster.both {
            let text = CurrentMaster.expanded(item.displayContent(for: category), for: category)
            #expect(text.contains("此項協助包括憑證彙集、提供有關文件資料"))
            #expect(!text.contains("憑證蒐集、對帳"))
            #expect(!text.contains("無法如法定期間內完成"), "錯字不得出現")
        }
    }
}

// MARK: - 權利義務與其它約定

@Suite("現行母版 — 權利義務與其它約定")
struct CurrentMasterProvisionsTests {

    private let qcm = CurrentMaster.qcm

    private func rights(_ category: AccountingCategory) -> [String] {
        qcm.rightsAndObligations.displayProvisions(for: category).map { CurrentMaster.expanded($0, for: category) }
    }

    @Test("權利義務(一)(二)：稅務帳版沒有句尾的「服務」，(三) 兩版相同")
    func rightsSplitByAccountType() {
        let tax = rights(CurrentMaster.tax)
        let standard = rights(CurrentMaster.standard)
        #expect(tax.count == 3)
        #expect(standard.count == 3)

        #expect(tax[0].hasPrefix("本事務所提供稅務申報服務作業將依據"))
        #expect(tax[0].hasSuffix("完成稅務申報服務作業。"))
        #expect(standard[0].hasPrefix("本事務所提供帳務整理作業服務將依據"))
        #expect(standard[0].hasSuffix("完成帳務整理作業服務。"))

        #expect(tax[1].hasPrefix("本事務所所提供稅務申報服務作業，"))
        #expect(standard[1].hasPrefix("本事務所所提供帳務整理作業服務，"))

        #expect(tax[2] == standard[2])
        #expect(tax[2] == "本事務所對 貴公司所提供之各項資料或相關文件，當盡保密之責。")
    }

    @Test("權利義務(一)：用「整理」不用「蒐集」")
    func rightsFirstProvisionUsesTidying() {
        for category in CurrentMaster.both {
            let text = rights(category)[0]
            #expect(text.contains("利用會計專業知識整理、分類及彙總資訊"))
            #expect(!text.contains("專業知識蒐集"))
        }
    }

    @Test("權利義務(二)：有資料合法性那句，過失範圍是「彙總有過失」")
    func rightsSecondProvisionHasDataLegalityClause() {
        for category in CurrentMaster.both {
            let text = rights(category)[1]
            #expect(text.contains("貴公司應確保資料合法性及完整性，除本事務所彙總有過失之情形外"))
            #expect(!text.contains("除本事務所分類及彙總有過失"))
        }
    }

    @Test("其它約定(三)：稅務帳版的文件留存範圍是「稅務申報資訊」，(一)(二) 兩版相同")
    func agreementTermsSplitOnlyOnThirdProvision() {
        let tax = qcm.agreementTerms.displayProvisions(for: CurrentMaster.tax)
        let standard = qcm.agreementTerms.displayProvisions(for: CurrentMaster.standard)
        #expect(tax.count == 3)
        #expect(tax[0] == standard[0])
        #expect(tax[1] == standard[1])
        #expect(tax[2].contains("利害衝突確認紀錄、稅務申報資訊、內部紀錄"))
        #expect(standard[2].contains("利害衝突確認紀錄、帳務及財務資訊、內部紀錄"))
    }

    @Test("其它約定：準據法是條文之後的獨立一段，不併在(三)")
    func agreementTermsGoverningLawIsClosing() {
        let governingLaw = "有關本報價單所生之相關爭議，均應以中華民國法令為準據法。"
        #expect(qcm.agreementTerms.closing == governingLaw)
        for category in [CurrentMaster.tax, CurrentMaster.standard] {
            #expect(qcm.agreementTerms.displayProvisions(for: category).allSatisfy { !$0.contains("準據法") })
        }
        #expect(qcm.rightsAndObligations.closing == nil)
    }
}

// MARK: - 服務範圍

@Suite("現行母版 — 服務範圍")
struct CurrentMasterServiceScopeTests {

    private let qcm = CurrentMaster.qcm

    @Test("記帳卡與整帳卡的名稱")
    func accountingServiceItemNames() {
        #expect(ServiceItem.accounting.displayName(for: CurrentMaster.tax) == "稅務申報服務作業")
        #expect(ServiceItem.accounting.displayName(for: CurrentMaster.standard) == "帳務整理作業")
        #expect(ServiceItem.accountingReform.displayName(for: CurrentMaster.tax) == "稅務整理作業")
        #expect(ServiceItem.accountingReform.displayName(for: CurrentMaster.standard) == "帳務整理作業")
    }

    // 一套帳的前言在母版被整句劃掉——不是空字串，是整段不印。
    @Test("記帳卡服務範圍前言只有稅務帳有")
    func accountingTermOnlyForTaxAccount() {
        let taxTerms = ServiceItem.accounting.effectiveScopeTerms(for: CurrentMaster.tax)
        #expect(taxTerms.count == 1)
        #expect(taxTerms.first?.name == "稅務申報服務作業")
        #expect(taxTerms.first?.content == "由 貴公司委託本事務所代辦相關作業，包括以下內容：")
        #expect(ServiceItem.accounting.effectiveScopeTerms(for: CurrentMaster.standard).isEmpty)
    }

    @Test("記帳：平時帳務作業只有一套帳印，內容是「憑證整理」")
    func accountingDailyWorkItem() throws {
        let workItem = try #require(qcm.getWorkItem(serviceType: "Accounting", workItemType: "accounting"))
        #expect(workItem.displayContent(for: CurrentMaster.standard) == "憑證整理")
        #expect(workItem.description == nil)
        #expect(workItem.isVisibleInServiceScope(for: CurrentMaster.standard))
        #expect(!workItem.isVisibleInServiceScope(for: CurrentMaster.tax))
    }

    @Test("記帳：成本表兩個帳別同字，不留帳別變體")
    func costAnalysisSameInBothAccountTypes() throws {
        let workItem = try #require(qcm.getWorkItem(serviceType: "Accounting", workItemType: "costAnalysis"))
        for category in CurrentMaster.both {
            #expect(workItem.displayContent(for: category) == "成本表稅務申報作業")
            #expect(workItem.isVisibleInServiceScope(for: category))
        }
        #expect(workItem.taxAccountContent == nil, "兩邊同字就不該留帳別變體")
    }

    // 定義一定要留著：下游 GetServiceScope 查不到 workItemType 會 throw，
    // 存量案件勾過的項目若從陣列刪掉，整份 PDF 會 500 而不是少印一行。
    @Test("不進服務範圍的記帳 workItem：定義仍查得到，兩個帳別都不印",
          arguments: ["financialSettlement", "standardReporting", "customizedReporting"])
    func hiddenAccountingWorkItems(workItemType: String) throws {
        let workItem = try #require(qcm.getWorkItem(serviceType: "Accounting", workItemType: workItemType))
        for category in CurrentMaster.both {
            #expect(!workItem.isVisibleInServiceScope(for: category))
        }
        #expect(!workItem.content.isEmpty, "定義要留著")
    }

    @Test("財簽與營所稅條文不重複印服務名稱")
    func scopeTermsDropLeadingServiceName() throws {
        #expect(ServiceItem.financialComplianceAudit.term == "主要係依照「審計準則」查核財務報表是否依照「企業會計準則」編製並出具財務簽證查核報告，內容包括會計師查核報告書、財務報表、財務報表附註及相關財務資訊等項目。")

        for item in [ServiceItem.taxComplianceAudit, ServiceItem.taxComplianceAuditAndUndistributedEarningsAudit] {
            let first = try #require(item.scopeTerms.first)
            #expect(first.content.hasPrefix("主要係包括執行營利事業所得稅結算申報程序"))
        }

        let undistributed = try #require(ServiceItem.taxComplianceAuditAndUndistributedEarningsAudit.scopeTerms.last)
        #expect(undistributed.content == "主要係未分配盈餘結算申報與查核。")
    }

    @Test("出納：標題與前言用「整理」")
    func cashierUsesTidyingWording() throws {
        let cashier = try #require(qcm.getServiceItem(type: "CashierOperation"))
        #expect(cashier.name == "出納事務整理作業")
        #expect(try #require(cashier.term).contains("委託出納事務相關整理作業"))
    }

    @Test("薪資：標題帶人數級距")
    func payrollTitleCarriesHeadcountTier() throws {
        #expect(try #require(qcm.getServiceItem(type: "PayrollSupportOperation")).name == "薪資人力支援作業 - 10人以內")
    }

    // MARK: 註號引用

    private func secondGenerationInsuranceFiling() throws -> WorkItem {
        try #require(
            qcm.getWorkItem(serviceType: "PayrollSupportOperation", workItemType: "secondGenerationNationalHealthInsuranceFiling")
        )
    }

    /// 服務範圍的 workItem 也能指回合約注意事項（「二代健保申報作業。(註五)」）。
    /// 號碼由讀取端依最終清單現算，QCM 只宣告引用哪一條、怎麼寫。
    @Test("二代健保申報作業引用補充保費那條備註")
    func secondGenerationInsuranceReferencesSupplementaryPremiumNote() throws {
        let workItem = try secondGenerationInsuranceFiling()
        let reference = try #require(workItem.noteReference)
        #expect(reference.contractNoteUniqueCode == "7")
        #expect(qcm.getNote(uniqueCode: "7") != nil, "被引用的備註要存在")
        #expect(workItem.displayContent(for: CurrentMaster.standard, noteNumber: "五") == "二代健保申報作業(註五)")
    }

    /// 算不出註號（沒加購補充保費 → 那條備註不在清單上）時整段引用消失，不印出「(註)」這種殘缺的東西。
    @Test("沒有註號時引用整段消失")
    func noteReferenceVanishesWithoutNumber() throws {
        #expect(try secondGenerationInsuranceFiling().displayContent(for: CurrentMaster.standard) == "二代健保申報作業")
    }

    /// 宣告了引用的 workItem，`content` 一定要留 `{noteRef}` 的位置，否則號碼算出來也插不進去。
    @Test("宣告了 noteReference 的 workItem 必含 {noteRef}")
    func referencingWorkItemsCarryPlaceholder() {
        var checked = 0
        for item in qcm.serviceItems {
            for workItem in item.workItems where workItem.noteReference != nil {
                checked += 1
                #expect(workItem.content.contains(ContentPlaceholder.noteRef.rawValue),
                        "\(item.type).\(workItem.type) 宣告了引用卻沒有 {noteRef}")
            }
        }
        #expect(checked == 1, "目前只有二代健保一個 workItem 有註號引用，實得 \(checked)")
    }
}

// MARK: - 酬金

@Suite("現行母版 — 酬金")
struct CurrentMasterPaymentTests {

    private let qcm = CurrentMaster.qcm

    /// 稅務帳的酬金列寫「稅務申報服務」，**不帶「作業」**——和稅務帳的服務名稱（「稅務申報服務作業」，
    /// 服務範圍標題在用）不同字。一套帳仍是服務名稱「帳務整理作業」。
    @Test("記帳酬金列：稅務帳「稅務申報服務」不帶作業，一套帳「帳務整理作業」")
    func accountingPaymentItemName() throws {
        let accounting = try #require(qcm.getServiceItem(type: "Accounting"))
        let start = TemplateVariableConcept.accountingStart.placeholder()
        #expect(accounting.paymentItemName(for: CurrentMaster.tax) == "稅務申報服務\(start)")
        #expect(accounting.paymentItemName(for: CurrentMaster.standard) == "帳務整理作業\(start)")
        // 酬金與服務名稱分開：服務範圍標題照舊帶「作業」。
        #expect(accounting.displayName(for: CurrentMaster.tax) == "稅務申報服務作業")
    }

    /// 專案整帳比照整帳：酬金列「整理費(專案)(期間)」，不帶服務名稱；服務名稱仍是「帳務整理作業(專案)」。
    @Test("專案整帳酬金列：整理費(專案)")
    func projectAccountingReformPaymentItemName() throws {
        let project = try #require(qcm.getServiceItem(type: "ProjectAccountingReform"))
        let period = TemplateVariableConcept.reformPeriod.placeholder(variant: "project")
        for category in CurrentMaster.both {
            #expect(project.paymentItemName(for: category) == "整理費(專案)\(period)")
        }
        #expect(project.displayName(for: CurrentMaster.standard) == "帳務整理作業(專案)")
    }

    /// 薪資的人數級距只在服務範圍標題，酬金列不帶。
    @Test("薪資酬金列不帶人數級距，服務範圍標題帶")
    func payrollPaymentItemNameOmitsHeadcountTier() throws {
        let payroll = try #require(qcm.getServiceItem(type: "PayrollSupportOperation"))
        #expect(payroll.paymentItemName(for: nil) == "薪資人力支援作業")
        #expect(payroll.displayName(for: nil) == "薪資人力支援作業 - 10人以內")
    }

    /// 整帳酬金列指回整帳電子檔備註（22）：註號寫在期間那組括號裡（2026-10-15 業務裁定）。
    @Test("整帳酬金列：註號插在期間括號裡")
    func accountingReformPaymentItemNameReferencesNote() throws {
        let reference = try #require(qcm.getServiceItem(type: "AccountingReform")?.paymentItemNameFormat?.noteReference)
        #expect(reference.contractNoteUniqueCode == "22")
        #expect(reference.attach(to: "整理費(115年1-4月)", noteNumber: "二") == "整理費(115年1-4月；註二)")
        #expect(reference.attach(to: "整理費(114年11月-115年4月)", noteNumber: "二") == "整理費(114年11月-115年4月；註二)")
        #expect(reference.attach(to: "整理費（115年1-4月）", noteNumber: "二") == "整理費（115年1-4月；註二）")
    }

    /// 整帳區間沒填（`%ReformPeriod%` 展開成空字串）或使用者改過名稱，名稱就不以括號結尾 → 另開一組括號。
    /// 報價單上沒有那條備註（算不出註號）→ 名稱原樣，不印「(註)」這種殘缺的東西。
    @Test("整帳酬金列：名稱沒有括號時另開括號，沒有註號時原樣")
    func accountingReformPaymentItemNameReferenceFallbacks() throws {
        let reference = try #require(qcm.getServiceItem(type: "AccountingReform")?.paymentItemNameFormat?.noteReference)
        #expect(reference.attach(to: "整理費", noteNumber: "二") == "整理費(註二)")
        #expect(reference.attach(to: "整理費(115年1-4月)", noteNumber: nil) == "整理費(115年1-4月)")
    }

    /// 整帳電子檔備註不印在專案整帳上，所以專案整帳的酬金列也不指回它。
    @Test("專案整帳酬金列不帶註號")
    func projectAccountingReformPaymentItemNameHasNoReference() throws {
        let project = try #require(qcm.getServiceItem(type: "ProjectAccountingReform"))
        #expect(project.paymentItemNameFormat?.noteReference == nil)
    }

    /// 酬金名稱引用的備註要是「這個服務項目自己就帶得出來」的那條，否則報價單上永遠找不到它、註號永遠不印。
    @Test("酬金名稱引用的備註，該服務項目自己就帶得出來")
    func paymentItemNameReferencesNoteOfItsOwnServiceItem() {
        var checked = 0
        for item in qcm.serviceItems {
            guard let reference = item.paymentItemNameFormat?.noteReference else { continue }
            checked += 1
            let fetched = qcm.fetchNotes(subsetOf: Array(item.tags)).map(\.uniqueCode)
            #expect(fetched.contains(reference.contractNoteUniqueCode),
                    "\(item.type) 的酬金名稱引用 \(reference.contractNoteUniqueCode)，但這個服務項目帶不出那條備註")
        }
        #expect(checked == 1, "目前只有整帳的酬金名稱有註號引用，實得 \(checked)")
    }

    /// 兩份母版的整帳酬金列都寫「整理費(期間)」，不是服務項目名稱。
    @Test("整帳酬金列：整理費")
    func accountingReformPaymentItemName() throws {
        let reform = try #require(qcm.getServiceItem(type: "AccountingReform"))
        for category in CurrentMaster.both {
            let name = try #require(reform.paymentItemName(for: category))
            #expect(name.hasPrefix("整理費"))
            #expect(!name.contains("帳務整理作業"))
            #expect(!name.contains("稅務整理作業"))
        }
    }
}

// MARK: - 合約注意事項

@Suite("現行母版 — 合約注意事項")
struct CurrentMasterContractNoteTests {

    private let qcm = CurrentMaster.qcm

    @Test("註一第二句：「就已提供服務範圍，將另行收取費用」")
    func noteOneSecondSentence() throws {
        let content = try #require(qcm.getNote(uniqueCode: "16")).allSegmentsJoined
        #expect(content.contains("本事務所就已提供服務範圍，將另行收取費用。"))
        #expect(!content.contains("稅務諮詢費用"), "舊用字不得出現")
    }

    @Test("註二簽證付款：用具體日期")
    func noteTwoUsesConcreteDates() throws {
        let content = try #require(qcm.getNote(uniqueCode: "21")).allSegmentsJoined
        #expect(content.hasPrefix("簽證公費請於當年度12月31日前支付半數，另外半數請於次年度5月31日前支付"))
        #expect(!content.contains("當年度末日"))
        #expect(!content.contains("次年度五月末日"))
    }

    /// 前綴「附加服務選項：」的契約在 `AdditionalServiceOptionNotePrefixTests`，這裡只驗內文用字。
    @Test("附加服務兩條註的用字")
    func additionalServiceNotes() throws {
        let ctp = try #require(qcm.getNote(uniqueCode: "1")).allSegmentsJoined
        #expect(ctp.hasPrefix("附加服務選項：代辦年度CTP申報"))
        #expect(ctp.contains("依據公司法第22條之1"))
        #expect(!ctp.contains("增訂"))
        #expect(ctp.contains("(董事、監察及經理人)"))

        let premium = try #require(qcm.getNote(uniqueCode: "7")).allSegmentsJoined
        #expect(premium.hasPrefix("附加服務選項：依全民健康保險扣取"))
    }

    @Test("稅簽優點第 3 點是電腦選案比率")
    func taxAuditBenefitNote() throws {
        for code in ["12", "13"] {
            let note = try #require(qcm.getNote(uniqueCode: code)).allSegmentsJoined
            #expect(note.contains("3.降低國稅局電腦選案比率，"))
            #expect(!note.contains("抽查查帳比率"))
        }
    }

    @Test("最新稅務訊息註有「(除特定專案外)」")
    func taxNewsNote() throws {
        let note = try #require(qcm.getNote(uniqueCode: "2")).allSegmentsJoined
        #expect(note.contains("教育訓練課程(除特定專案外)，"))
    }

    // MARK: 整帳電子檔備註

    @Test("整帳電子檔備註：日期都取自整帳區間")
    func accountingReformNoteContent() throws {
        let content = try #require(qcm.getNote(uniqueCode: "22")).allSegmentsJoined
        #expect(content == "貴公司應提供%ReformPeriod|plain%相關帳冊及報表(含科目餘額明細表)之電子檔(excel)，本事務所將依 貴公司提供之%ReformEndDate%報表金額作為%ReformOpeningMonth%開帳數，且免對於%ReformPeriod|short%帳務做整理覆核，若後續因報表核實表達因素，導致需大量調整，將另與 貴公司討論報價金額。")
    }

    /// 只要有整帳就印，不看整帳卡有沒有勾提供電子檔；專案整帳不印（2026-10-15 業務裁定）。
    @Test("整帳電子檔備註：有整帳就出現，不論有無提供電子檔",
          arguments: [
            ["ServiceItem/Accounting", "ServiceItem/AccountingReform"],
            ["ServiceItem/Accounting", "ServiceItem/AccountingReform", "ServiceItemConfig/is_providing_electronic_file:true"],
            ["ServiceItem/Accounting", "ServiceItem/AccountingReform", "ServiceItemConfig/is_providing_electronic_file:false"],
          ])
    func accountingReformNoteAppearsWithReform(tags: [String]) {
        let codes = qcm.fetchNotes(subsetOf: tags).map(\.uniqueCode)
        #expect(codes.contains("22"))
        #expect(!codes.contains("9"), "9 已被 22 取代")
    }

    @Test("整帳電子檔備註：沒有整帳、或只有專案整帳時不出現",
          arguments: [
            ["ServiceItem/Accounting"],
            ["ServiceItem/ProjectAccountingReform"],
          ])
    func accountingReformNoteRequiresReform(tags: [String]) {
        #expect(!qcm.fetchNotes(subsetOf: tags).map(\.uniqueCode).contains("22"))
    }

    // MARK: 薪資備註

    @Test("薪資備註：人數級距加價")
    func payrollNoteContent() throws {
        let content = try #require(qcm.getNote(uniqueCode: "23")).allSegmentsJoined
        #expect(content == "薪資人力支援作業基本以每月5人內計算，超過人數(第6位起)每位加價1,000元。")
    }

    @Test("薪資備註：有薪資就出現，沒有就不出現")
    func payrollNoteFollowsPayroll() {
        #expect(qcm.fetchNotes(subsetOf: ["ServiceItem/PayrollSupportOperation"]).map(\.uniqueCode).contains("23"))
        #expect(!qcm.fetchNotes(subsetOf: ["ServiceItem/Accounting"]).map(\.uniqueCode).contains("23"))
        #expect(!qcm.fetchNotes(subsetOf: ["ServiceItem/PayrollSupportOperation"]).map(\.uniqueCode).contains("11"), "11 是 deprecated 的舊薪資備註")
    }

    // MARK: 出納備註

    /// 兩條都在選到出納時印（2026-10-15 業務裁定）；用字統一成服務名稱的「整理」。
    @Test("出納備註：兩條都印，內容照業務提供")
    func cashierNotes() throws {
        let codes = qcm.fetchNotes(subsetOf: ["ServiceItem/CashierOperation"]).map(\.uniqueCode)
        #expect(codes == ["24", "25"])
        #expect(try #require(qcm.getNote(uniqueCode: "24")).allSegmentsJoined == """
        出納事務整理作業內容包含：
        A.每月一次薪資轉帳。
        B.每月一次廠商批次付款。
        C.每週一次臨時付款。
        """)
        #expect(try #require(qcm.getNote(uniqueCode: "25")).allSegmentsJoined == """
        出納事務整理作業內容包含：
        A.國內轉帳30 筆；每加一筆多50 元。
        B.國外轉帳10 筆；每加一筆多100 元。
        C.一次薪資轉帳。
        *如出納事務整理作業有重複處理，將額外收取處理費用2,000元/次。
        """)
    }

    /// 舊的出納備註 10 用過康熙部首「⼀」（U+2F00），新的兩條要用一般的「一」。
    @Test("出納備註不用康熙部首的「⼀」")
    func cashierNotesUseRegularYi() throws {
        for code in ["24", "25"] {
            #expect(!(try #require(qcm.getNote(uniqueCode: code)).allSegmentsJoined.contains("\u{2F00}")))
        }
    }

    // MARK: 母版拿掉的備註

    /// 被註一／註二取代的 4（財簽）、6（稅簽）、8（記帳），被整帳電子檔備註 22 取代的 9，
    /// 以及母版拿掉的 5（削價）、10（出納）、11（薪資）：
    /// 標 deprecated——不再被帶出，但定義要留著，OC 同步時才認得出它們、把既有報價單上的清掉。
    @Test("被取代或拿掉的備註：不再被帶出，定義保留且標 deprecated",
          arguments: ["4", "5", "6", "8", "9", "10", "11"])
    func deprecatedNotesAreRetainedButNotFetched(uniqueCode: String) throws {
        #expect(qcm.getNote(uniqueCode: uniqueCode) == nil)

        let note = try #require(qcm.contractNoteManager.notes.first { $0.uniqueCode == uniqueCode }, "定義要留著")
        #expect(note.deprecated)
        // 用它自己的 trait 去撈，最能證明「條件成立也不會被帶出」。
        let ownTags = note.traits.flatMap { Array($0.tags) }
        #expect(!qcm.fetchNotes(subsetOf: ownTags).map(\.uniqueCode).contains(uniqueCode))
    }

    @Test("削價註的內容保留原文")
    func priceUndercuttingNoteContentRetained() throws {
        let note = try #require(qcm.contractNoteManager.notes.first { $0.uniqueCode == "5" })
        #expect(note.allSegmentsJoined.hasPrefix("依據會計師職業道德，不以不正當之削價方式"))
    }

    @Test("出納備註的內容保留原文")
    func cashierNoteContentRetained() throws {
        let note = try #require(qcm.contractNoteManager.notes.first { $0.uniqueCode == "10" })
        #expect(note.allSegmentsJoined.hasPrefix("出納事務整理作業內容包含："))
    }
}

// MARK: - 註一／註二的動態組裝

/// 註一（巨額變動）／註二（付款條件）的內文依實際選到的服務裁剪（只選財簽就只印財簽那句）。
/// 一條 note 一個固定字串表達不了，所以 `ContractNoteInfo` 由數個帶 trait 條件的 `Segment` 組成，
/// 由 `composedContent(subsetOf:)` 在加進報價單時組出成品。
///
/// 期望值寫完整字串而不是 `contains`，因為這兩條註的**標點銜接**正是容易出錯的地方：
/// 少印中間某一段時，段落之間的「，」「；」「。」要跟著收斂。
///
/// `ContractNoteManager` 裡註一的組合規則**以這裡為準**（那邊的註解指過來，不另抄一份表）。
@Suite("現行母版 — 註一／註二的動態組裝")
struct CompositeContractNoteTests {

    private let qcm = CurrentMaster.qcm

    private let financialAudit = "ServiceItem/FinancialComplianceAudit"
    private let taxAudit = "ServiceItem/TaxComplianceAudit"
    private let accounting = "ServiceItem/Accounting"
    private let companyRegistration = "ServiceItem/CompanyRegistration"

    private func composed(_ uniqueCode: String, _ tags: [String], for category: AccountingCategory = CurrentMaster.tax) throws -> String? {
        let note = try #require(qcm.getNote(uniqueCode: uniqueCode))
        guard note.isSubsetOf(tags: tags) else { return nil }   // 整條備註不適用
        guard let content = note.composedContent(subsetOf: tags) else { return nil }
        return CurrentMaster.expanded(content, for: category)
    }

    // MARK: 註一

    // 註一不含三句報價基準（「…依預估…報價」）：那三句只住在酬金補充說明（`PaymentItemManager`），
    // 不複製進合約注意事項 —— `noteOneExcludesPricingBasis` 釘住這件事，避免 PDF 上印兩次。
    //
    // 第一句的主詞隨服務裁剪（2026-10-02 裁定）；第二句只在有稅簽時出現（2026-10-13 裁定）。
    private static let noteOneFirstSentenceTail = "若有巨額變動或變更申報方式，將另與 貴公司討論報價金額。"
    private static let noteOneSecondSentence = "又 貴公司若後續無營利事業所得稅查核簽證及未分配盈餘查核簽證服務，本事務所就已提供服務範圍，將另行收取費用。"

    /// 七種服務組合 × 第一句的主詞 × 第二句有無（**註一組合規則的唯一一份表**）。
    ///
    /// 記帳那段自己就含「營業收入總額」，所以同時有稅簽時稅簽那段要讓位（`excluded`）——
    /// 否則會印成「營業收入總額、營業收入總額及憑證量」。這是去重，不是互斥。
    @Test("註一 — 第一句的主詞隨選到的服務裁剪，第二句只在有稅簽時出現",
          arguments: [
            (["ServiceItem/FinancialComplianceAudit"], "資產總額", false),
            (["ServiceItem/TaxComplianceAudit"], "營業收入總額", true),
            (["ServiceItem/Accounting"], "營業收入總額及憑證量", false),
            (["ServiceItem/FinancialComplianceAudit", "ServiceItem/TaxComplianceAudit"], "資產總額、營業收入總額", true),
            (["ServiceItem/FinancialComplianceAudit", "ServiceItem/Accounting"], "資產總額、營業收入總額及憑證量", false),
            (["ServiceItem/TaxComplianceAudit", "ServiceItem/Accounting"], "營業收入總額及憑證量", true),
            (["ServiceItem/FinancialComplianceAudit", "ServiceItem/TaxComplianceAudit", "ServiceItem/Accounting"],
             "資產總額、營業收入總額及憑證量", true),
          ])
    func noteOneFollowsSelectedServices(tags: [String], subject: String, hasSecondSentence: Bool) throws {
        let expected = subject + Self.noteOneFirstSentenceTail
            + (hasSecondSentence ? "\n" + Self.noteOneSecondSentence : "")
        #expect(try composed("16", tags) == expected)
    }

    @Test("註一 — 稅簽＋記帳不會把營業收入總額印兩次")
    func noteOneDoesNotRepeatRevenue() throws {
        let content = try #require(try composed("16", [taxAudit, accounting]))
        #expect(content.components(separatedBy: "營業收入總額").count - 1 == 1)
    }

    /// 第二句綁稅簽（2026-10-13 裁定；原本 2026-09 裁定為不綁稅簽、一律印）。
    @Test("註一 — 沒有稅簽時不印第二句",
          arguments: [
            ["ServiceItem/FinancialComplianceAudit"],
            ["ServiceItem/Accounting"],
            ["ServiceItem/FinancialComplianceAudit", "ServiceItem/Accounting"],
          ])
    func noteOneSecondSentenceRequiresTaxAudit(tags: [String]) throws {
        let content = try #require(try composed("16", tags))
        #expect(!content.contains("又 貴公司若後續無營利事業所得稅查核簽證及未分配盈餘查核簽證服務"))
    }

    @Test("註一不含報價基準 —— 那三句只住在酬金補充說明")
    func noteOneExcludesPricingBasis() throws {
        let content = try #require(try composed("16", [financialAudit, taxAudit, accounting]))
        #expect(!content.contains("依預估"))

        let items = qcm.paymentItemManager.items
        #expect(items.count == 3)
        #expect(try #require(qcm.fetchPaymentItems(serviceItem: "FinancialComplianceAudit").first).content.hasPrefix("財務簽證依預估"))
        #expect(try #require(qcm.fetchPaymentItems(serviceItem: "TaxComplianceAudit").first).content.hasPrefix("稅務簽證依照預估年營收計"))
        #expect(try #require(qcm.fetchPaymentItems(serviceItem: "Accounting").first).content.contains("作業依照預估年營收計"))
    }

    // MARK: 註一（專營投資業版）

    private let investmentOnly = IndustrialType.investmentOnly.contractNoteTag

    @Test("行業別 tag 的字串")
    func industrialTypeTag() {
        #expect(investmentOnly == "IndustrialType/investmentOnly")
        #expect(IndustrialType.allCases.allSatisfy { $0.contractNoteTag.hasPrefix(IndustrialType.contractNoteTagPrefix) })
    }

    @Test("專營投資業 — 註一換成投資業版，不印 16",
          arguments: [
            ["ServiceItem/FinancialComplianceAudit"],
            ["ServiceItem/TaxComplianceAudit"],
            ["ServiceItem/Accounting"],
            ["ServiceItem/FinancialComplianceAudit", "ServiceItem/TaxComplianceAudit", "ServiceItem/Accounting"],
          ])
    func investmentOnlyReplacesNoteOne(tags: [String]) {
        let codes = qcm.fetchNotes(subsetOf: tags + [investmentOnly]).map(\.uniqueCode)
        #expect(codes.first == "26")
        #expect(!codes.contains("16"))
    }

    @Test("其他行業別或還沒填行業別 — 照舊印 16、沒有投資業版",
          arguments: [nil] + IndustrialType.allCases.filter { $0 != .investmentOnly }.map(\.contractNoteTag))
    func otherIndustriesKeepNoteOne(industryTag: String?) {
        let tags = [financialAudit, taxAudit, accounting] + (industryTag.map { [$0] } ?? [])
        let codes = qcm.fetchNotes(subsetOf: tags).map(\.uniqueCode)
        #expect(codes.first == "16")
        #expect(!codes.contains("26"))
    }

    /// 整條只印業務給的那一句：有稅簽也不接 16 的第二句（2026-10-16 業務裁定）。
    @Test("專營投資業 — 註一內容，有稅簽也只有這一句")
    func investmentOnlyNoteOneContent() throws {
        #expect(try composed("26", [financialAudit, taxAudit, accounting, investmentOnly]) == "專營投資(控股)公司以持有3家未上市櫃公司為限報價，若有超過3家以上及買賣上市櫃公司股票或其他金融資產，將視進出筆數另與 貴公司討論報價金額。")
    }

    @Test("專營投資業但只有工商登記 — 兩版註一都不出現")
    func investmentOnlyCompanyRegistrationHasNoNoteOne() throws {
        #expect(try composed("16", [companyRegistration, investmentOnly]) == nil)
        #expect(try composed("26", [companyRegistration, investmentOnly]) == nil)
    }

    // MARK: 註二

    @Test("註二 — 財簽＋稅簽＋記帳：簽證那句去重成一次")
    func noteTwoWithEverything() throws {
        let content = try #require(try composed("21", [financialAudit, taxAudit, accounting]))
        #expect(content == """
        簽證公費請於當年度12月31日前支付半數，另外半數請於次年度5月31日前支付；稅務申報服務作業費用%AccountingPeriod%，並%AccountingBilling%，並應支付至本事務所指定之銀行帳戶。
        承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款。
        """)
        // 財簽與稅簽的付款句內容一模一樣；同一條備註裡只能出現一次。
        #expect(content.components(separatedBy: "簽證公費請於當年度12月31日前支付半數").count - 1 == 1)
    }

    @Test("註二 — 只有簽證沒有記帳：中段消失，標點要收斂")
    func noteTwoAuditOnly() throws {
        #expect(try composed("21", [financialAudit]) == """
        簽證公費請於當年度12月31日前支付半數，另外半數請於次年度5月31日前支付。
        承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款。
        """)
    }

    @Test("註二 — 只有記帳：簽證那句消失，由記帳那段起頭")
    func noteTwoAccountingOnly() throws {
        #expect(try composed("21", [accounting], for: CurrentMaster.standard) == """
        帳務整理作業費用%AccountingPeriod%，並%AccountingBilling%，並應支付至本事務所指定之銀行帳戶。
        承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款。
        """)
    }

    // 代墊費用那段本身無條件，但註二整條只在有財簽／稅簽／記帳任一時才出現，
    // 所以純工商登記的案子連註二都沒有、不會印到代墊費用。
    @Test("純工商登記 — 註一與註二都不出現")
    func companyRegistrationOnlyHasNeitherNote() throws {
        #expect(try composed("16", [companyRegistration]) == nil)
        #expect(try composed("21", [companyRegistration]) == nil)
    }

    // MARK: 排序

    // 母版順序：註一（巨額變動）→ 註二（付款條件）→ 註三（稅簽優點）→ 註四（CTP）→ 註五（補充保費）
    // → 註六（非稅簽查核）→ 註七（最新稅務訊息）。
    @Test("母版 A 的組合排出來的註號順序")
    func noteOrderMatchesMaster() {
        let tags = [
            financialAudit, taxAudit, accounting,
            "ServiceItem/Ctp",
            "ServiceItem/AssistanceAnnualSupplementaryPremiumDeductionDetailsReporting",
            "general", "Tip/benefit",
        ]
        let codes = qcm.fetchNotes(subsetOf: tags).map(\.uniqueCode)
        #expect(codes == ["16", "21", "13", "1", "7", "14", "2"])
    }

    // 註一（巨額變動）→ 整帳電子檔 → 薪資 → 出納兩條 → 付款條件 → 工商登記…（2026-10-15 業務裁定）。
    // 整帳一定掛在記帳卡下、註一必在，所以有整帳時整帳電子檔就是註二、薪資註三、出納註四與註五。
    @Test("整帳、薪資、出納的備註緊接在註一之後，付款條件往後退")
    func accountingReformPayrollCashierNoteOrder() {
        let tags = [
            accounting, "ServiceItem/AccountingReform", "ServiceItem/PayrollSupportOperation", "ServiceItem/CashierOperation",
            companyRegistration, "general", "Tip/benefit",
        ]
        let codes = qcm.fetchNotes(subsetOf: tags).map(\.uniqueCode)
        #expect(codes == ["16", "22", "23", "24", "25", "21", "15", "3", "14", "2"])
    }

    @Test("沒有薪資時，整帳電子檔後面直接接付款條件")
    func accountingReformNoteOrderWithoutPayroll() {
        let codes = qcm.fetchNotes(subsetOf: [accounting, "ServiceItem/AccountingReform"]).map(\.uniqueCode)
        #expect(codes == ["16", "22", "21", "14"])
    }

    @Test("專營投資業：投資業版註一排在原本 16 的位置")
    func investmentOnlyNoteOrder() {
        let tags = [
            accounting, "ServiceItem/AccountingReform", "ServiceItem/PayrollSupportOperation",
            IndustrialType.investmentOnly.contractNoteTag,
        ]
        let codes = qcm.fetchNotes(subsetOf: tags).map(\.uniqueCode)
        #expect(codes == ["26", "22", "23", "21", "14"])
    }
}
