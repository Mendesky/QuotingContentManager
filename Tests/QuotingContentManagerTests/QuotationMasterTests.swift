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

    @Test("酬金補充說明與記帳付款條件註共用 template，且不寫死「處理」")
    func paymentItemAndAccountingNoteShareTemplate() throws {
        let supplementary = try #require(qcm.fetchPaymentItems(serviceItem: "Accounting").first).content
        #expect(CurrentMaster.expanded(supplementary, for: CurrentMaster.tax).hasPrefix("稅務申報服務作業依照預估年營收計"))
        #expect(CurrentMaster.expanded(supplementary, for: CurrentMaster.standard).hasPrefix("帳務整理作業依照預估年營收計"))

        // 記帳的付款條件在註二裡，用 allSegmentsJoined 取整條來驗用字。
        let paymentNote = try #require(qcm.getNote(uniqueCode: "17")).allSegmentsJoined
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
        #expect(tax[2] == "本事務所對　貴公司所提供之各項資料或相關文件，當盡保密之責。")
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
        #expect(taxTerms.first?.content == "由　貴公司委託本事務所代辦相關作業，包括以下內容：")
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
        let content = try #require(qcm.getNote(uniqueCode: "17")).allSegmentsJoined
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

    // MARK: 母版拿掉的備註

    @Test("削價註已刪除，code 5 列入退場清單")
    func priceUndercuttingNoteRemoved() {
        #expect(qcm.getNote(uniqueCode: "5") == nil)
        #expect(!qcm.contractNoteManager.notes.contains { $0.allSegmentsJoined.contains("不以不正當之削價方式") })
        #expect(ContractNoteManager.retiredUniqueCodes.contains("5"))
    }

    /// 被註一／註二取代的 4（財簽）、6（稅簽）、8（記帳），以及母版拿掉的 10（出納）、11（薪資）：
    /// 標 deprecated——不再被帶出，但定義要留著，OC 同步時才認得出它們、把既有報價單上的清掉。
    @Test("被取代或拿掉的備註：不再被帶出，定義保留且標 deprecated",
          arguments: ["4", "6", "8", "10", "11"])
    func deprecatedNotesAreRetainedButNotFetched(uniqueCode: String) throws {
        #expect(qcm.getNote(uniqueCode: uniqueCode) == nil)

        let note = try #require(qcm.contractNoteManager.notes.first { $0.uniqueCode == uniqueCode }, "定義要留著")
        #expect(note.deprecated)
        // 用它自己的 trait 去撈，最能證明「條件成立也不會被帶出」。
        let ownTags = note.traits.flatMap { Array($0.tags) }
        #expect(!qcm.fetchNotes(subsetOf: ownTags).map(\.uniqueCode).contains(uniqueCode))
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
    // 第一句的主詞隨服務裁剪（2026-10-02 裁定）；第二句不綁稅簽，一律出現。
    private static let noteOneTail = """
    若有巨額變動或變更申報方式，將另與　貴公司討論報價金額。
    又 貴公司若後續無營利事業所得稅查核簽證及未分配盈餘查核簽證服務，本事務所就已提供服務範圍，將另行收取費用。
    """

    /// 七種服務組合 × 第一句的主詞（**註一組合規則的唯一一份表**）。
    ///
    /// 記帳那段自己就含「營業收入總額」，所以同時有稅簽時稅簽那段要讓位（`excluded`）——
    /// 否則會印成「營業收入總額、營業收入總額及憑證量」。這是去重，不是互斥。
    @Test("註一 — 第一句的主詞隨選到的服務裁剪",
          arguments: [
            (["ServiceItem/FinancialComplianceAudit"], "資產總額"),
            (["ServiceItem/TaxComplianceAudit"], "營業收入總額"),
            (["ServiceItem/Accounting"], "營業收入總額及憑證量"),
            (["ServiceItem/FinancialComplianceAudit", "ServiceItem/TaxComplianceAudit"], "資產總額、營業收入總額"),
            (["ServiceItem/FinancialComplianceAudit", "ServiceItem/Accounting"], "資產總額、營業收入總額及憑證量"),
            (["ServiceItem/TaxComplianceAudit", "ServiceItem/Accounting"], "營業收入總額及憑證量"),
            (["ServiceItem/FinancialComplianceAudit", "ServiceItem/TaxComplianceAudit", "ServiceItem/Accounting"],
             "資產總額、營業收入總額及憑證量"),
          ])
    func noteOneSubjectFollowsSelectedServices(tags: [String], subject: String) throws {
        #expect(try composed("16", tags) == subject + Self.noteOneTail)
    }

    @Test("註一 — 稅簽＋記帳不會把營業收入總額印兩次")
    func noteOneDoesNotRepeatRevenue() throws {
        let content = try #require(try composed("16", [taxAudit, accounting]))
        #expect(content.components(separatedBy: "營業收入總額").count - 1 == 1)
    }

    /// 第二句不綁稅簽：只要這條備註出現就印（2026-09 裁定）。
    @Test("註一 — 第二句不綁稅簽",
          arguments: [["ServiceItem/FinancialComplianceAudit"], ["ServiceItem/Accounting"]])
    func noteOneTaxConsultingSentenceAlwaysPrints(tags: [String]) throws {
        let content = try #require(try composed("16", tags))
        #expect(content.contains("又 貴公司若後續無營利事業所得稅查核簽證及未分配盈餘查核簽證服務"))
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

    // MARK: 註二

    @Test("註二 — 財簽＋稅簽＋記帳：簽證那句去重成一次")
    func noteTwoWithEverything() throws {
        let content = try #require(try composed("17", [financialAudit, taxAudit, accounting]))
        #expect(content == """
        簽證公費請於當年度12月31日前支付半數，另外半數請於次年度5月31日前支付；稅務申報服務作業費用%AccountingPeriod%，並%AccountingBilling%，並應支付至本事務所指定之銀行帳戶。
        承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款。
        """)
        // 財簽與稅簽的付款句內容一模一樣；同一條備註裡只能出現一次。
        #expect(content.components(separatedBy: "簽證公費請於當年度12月31日前支付半數").count - 1 == 1)
    }

    @Test("註二 — 只有簽證沒有記帳：中段消失，標點要收斂")
    func noteTwoAuditOnly() throws {
        #expect(try composed("17", [financialAudit]) == """
        簽證公費請於當年度12月31日前支付半數，另外半數請於次年度5月31日前支付。
        承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款。
        """)
    }

    @Test("註二 — 只有記帳：簽證那句消失，由記帳那段起頭")
    func noteTwoAccountingOnly() throws {
        #expect(try composed("17", [accounting], for: CurrentMaster.standard) == """
        帳務整理作業費用%AccountingPeriod%，並%AccountingBilling%，並應支付至本事務所指定之銀行帳戶。
        承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款。
        """)
    }

    // 代墊費用那段本身無條件，但註二整條只在有財簽／稅簽／記帳任一時才出現，
    // 所以純工商登記的案子連註二都沒有、不會印到代墊費用。
    @Test("純工商登記 — 註一與註二都不出現")
    func companyRegistrationOnlyHasNeitherNote() throws {
        #expect(try composed("16", [companyRegistration]) == nil)
        #expect(try composed("17", [companyRegistration]) == nil)
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
        #expect(codes == ["16", "17", "13", "1", "7", "14", "2"])
    }
}
