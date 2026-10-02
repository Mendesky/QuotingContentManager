import Testing
@testable import QuotingContentManager

/// 1150828 報價單母版改版（藍儀 CPA）的內容契約。
///
/// 母版有兩份：A 稅務帳、B 一套帳。許多段落在兩份之間句型不同（不只是名詞不同），
/// 所以這裡的斷言一律成對——稅務帳走 `forTaxAccount: true`、一套帳走 `false`。
///
/// 下面多數期望值都是「`%AccountingWorkName%` 展開後」的成品字串。那個變數的值由
/// `accountingWorkDisplayName(forAccountingType:)` 決定，本檔第一個測試釘住它；
/// 其餘測試用 `expanded(_:forTaxAccount:)` 做同樣的替換再比對，避免把 placeholder 原文抄進期望值
/// 而讓「值改了但句子沒跟著對」這類錯誤溜過去。
@Suite("1150828 報價單母版")
struct QuotationMasterRevision1150828Tests {

    private let qcm = QuotingContentManager.standard

    private func expanded(_ text: String, forTaxAccount isTaxAccount: Bool) -> String {
        let accountingType = isTaxAccount ? "taxAccount" : "financialAccount"
        return text.replacingOccurrences(
            of: TemplateVariableConcept.accountingWorkName.placeholder(),
            with: qcm.accountingWorkDisplayName(forAccountingType: accountingType)
        )
    }

    // MARK: 變數值

    // 這組值是唯一能讓「目的／服務範圍／酬金補充說明／記帳付款條件註」四句共用同一份 template
    // 的選擇。改它就要重新驗下面所有展開後的期望值。
    @Test("%AccountingWorkName% 的值")
    func accountingWorkName() {
        #expect(qcm.accountingWorkDisplayName(forAccountingType: "taxAccount") == "稅務申報服務")
        #expect(qcm.accountingWorkDisplayName(forAccountingType: "financialAccount") == "帳務整理")
        // 不可辨識的殘值沿用既有語意，視為非稅務帳。
        #expect(qcm.accountingWorkDisplayName(forAccountingType: "whatever") == "帳務整理")
    }

    // MARK: 四句共用 template

    @Test("目的與服務範圍共用同一份 template，兩個帳別都對上母版")
    func purposeAndServiceScopeShareTemplate() {
        #expect(expanded(qcm.purpose.content, forTaxAccount: true).contains("提升整體稅務申報服務品質"))
        #expect(expanded(qcm.purpose.content, forTaxAccount: false).contains("提升整體帳務整理品質"))
        #expect(expanded(qcm.serviceScope.content, forTaxAccount: true).contains("提升整體稅務申報服務品質"))
        #expect(expanded(qcm.serviceScope.content, forTaxAccount: false).contains("提升整體帳務整理品質"))
        // 共用代表沒有帳別變體。
        #expect(qcm.purpose.taxAccountContent == nil)
        #expect(qcm.serviceScope.taxAccountContent == nil)
    }

    @Test("酬金補充說明與記帳付款條件註共用 template，且不再寫死「處理」")
    func paymentItemAndAccountingNoteShareTemplate() throws {
        let supplementary = try #require(qcm.fetchPaymentItems(serviceItem: "Accounting").first).content
        #expect(expanded(supplementary, forTaxAccount: true).hasPrefix("稅務申報服務作業依照預估年營收計"))
        #expect(expanded(supplementary, forTaxAccount: false).hasPrefix("帳務整理作業依照預估年營收計"))

        // 記帳的付款條件已併進註二，用 fullContent 取整條來驗用字。
        let paymentNote = try #require(qcm.getNote(uniqueCode: "17")).fullContent
        #expect(expanded(paymentNote, forTaxAccount: true).contains("稅務申報服務作業費用"))
        #expect(expanded(paymentNote, forTaxAccount: false).contains("帳務整理作業費用"))
        #expect(!paymentNote.contains("處理作業費用"))
    }

    // MARK: 三處分帳別（一個變數表達不了，句子本身要有兩版）

    @Test("合約說明：稅務帳版把「稅務申報」寫死")
    func contractHeaderSplitsByAccountType() {
        let header = qcm.contractHeader
        #expect(expanded(header.displayContent(forTaxAccount: true), forTaxAccount: true).contains("提升稅務申報品質"))
        #expect(expanded(header.displayContent(forTaxAccount: false), forTaxAccount: false).contains("提升帳務整理品質"))
        // 稅務版若誤用 %AccountingWorkName%，展開會多出「服務」兩字。
        #expect(!header.displayContent(forTaxAccount: true).contains(TemplateVariableConcept.accountingWorkName.placeholder()))
    }

    @Test("協助事項③：稅務帳接「作業」、一套帳接「工作」")
    func businessClientAssistanceSplitsByAccountType() throws {
        let item = try #require(qcm.businessClientAssistanceManager.items.first { $0.uniqueCode == "3" })
        let tax = expanded(item.displayContent(forTaxAccount: true), forTaxAccount: true)
        let standard = expanded(item.displayContent(forTaxAccount: false), forTaxAccount: false)

        #expect(tax.contains("應對稅務申報服務作業儘量協助"))
        #expect(standard.contains("應對帳務整理工作儘量協助"))
        // 稅務版獨有的兩處改寫（母版沒有刪除線、直接改的）。
        #expect(tax.contains("簽證或稅務申報服務無法如法定期間內完成"))
        #expect(standard.contains("簽證或服務無法於法定期間內完成"))
        // 末句兩版相同。
        #expect(tax.hasSuffix("且本事務所得依第六點(二)之時間終止受託。"))
        #expect(standard.hasSuffix("且本事務所得依第六點(二)之時間終止受託。"))
    }

    @Test("權利義務(一)(二)：稅務帳版沒有句尾的「服務」，(三) 兩版相同")
    func rightsAndObligationsSplitsByAccountType() {
        let tax = qcm.rightsAndObligations.displayProvisions(forTaxAccount: true).map { expanded($0, forTaxAccount: true) }
        let standard = qcm.rightsAndObligations.displayProvisions(forTaxAccount: false).map { expanded($0, forTaxAccount: false) }
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

    @Test("其它約定(三)：稅務帳版的文件留存範圍改成「稅務申報資訊」")
    func agreementTermsSplitOnlyOnThirdProvision() {
        let tax = qcm.agreementTerms.displayProvisions(forTaxAccount: true)
        let standard = qcm.agreementTerms.displayProvisions(forTaxAccount: false)
        #expect(tax.count == 3)
        #expect(tax[0] == standard[0])
        #expect(tax[1] == standard[1])
        #expect(tax[2].contains("利害衝突確認紀錄、稅務申報資訊、內部紀錄"))
        #expect(standard[2].contains("利害衝突確認紀錄、帳務及財務資訊、內部紀錄"))
    }

    // MARK: 記帳卡

    @Test("記帳卡名稱兩個帳別都換掉了")
    func accountingServiceItemNames() {
        #expect(ServiceItem.accounting.displayName(forTaxAccount: true) == "稅務申報服務作業")
        #expect(ServiceItem.accounting.displayName(forTaxAccount: false) == "帳務整理作業")
        #expect(ServiceItem.accountingReform.displayName(forTaxAccount: true) == "稅務整理作業")
        #expect(ServiceItem.accountingReform.displayName(forTaxAccount: false) == "帳務整理作業")
    }

    // 一套帳的前言在母版被整句劃掉——不是空字串，是整段不印。
    @Test("記帳卡服務範圍前言只有稅務帳有")
    func accountingTermOnlyForTaxAccount() {
        let taxTerms = ServiceItem.accounting.effectiveScopeTerms(forTaxAccount: true)
        #expect(taxTerms.count == 1)
        #expect(taxTerms.first?.name == "稅務申報服務作業")
        #expect(taxTerms.first?.content == "由　貴公司委託本事務所代辦相關作業，包括以下內容：")
        #expect(ServiceItem.accounting.effectiveScopeTerms(forTaxAccount: false).isEmpty)
    }

    // 定義一定要留著：下游 GetServiceScope 查不到 workItemType 會 throw，
    // 存量案件勾過的項目若從陣列刪掉，整份 PDF 會 500 而不是少印一行。
    @Test("不顯示的 workItem 仍然查得到，只是不進服務範圍")
    func hiddenWorkItemsStillResolve() throws {
        let settlement = try #require(ServiceItem.accounting.workItem(type: "financialSettlement"))
        #expect(settlement.isVisibleInServiceScope(forTaxAccount: true) == false)
        #expect(settlement.isVisibleInServiceScope(forTaxAccount: false) == false)

        let daily = try #require(ServiceItem.accounting.workItem(type: "accounting"))
        #expect(daily.isVisibleInServiceScope(forTaxAccount: true) == false)
        #expect(daily.isVisibleInServiceScope(forTaxAccount: false) == true)
        #expect(daily.displayContent(forTaxAccount: false) == "憑證整理歸檔")
        #expect(daily.description == nil)

        let costAnalysis = try #require(ServiceItem.accounting.workItem(type: "costAnalysis"))
        #expect(costAnalysis.displayContent(forTaxAccount: true) == "成本表申報作業")
        #expect(costAnalysis.displayContent(forTaxAccount: false) == "成本表稅務申報作業")
        #expect(costAnalysis.isVisibleInServiceScope(forTaxAccount: true) == true)
    }

    // MARK: 服務範圍條文

    @Test("財簽與營所稅條文不再重複印服務名稱")
    func scopeTermsDropLeadingServiceName() throws {
        #expect(ServiceItem.financialComplianceAudit.term == "主要係依照「審計準則」查核財務報表是否依照「企業會計準則」編製並出具財務簽證查核報告，內容包括會計師查核報告書、財務報表、財務報表附註及相關財務資訊等項目。")

        for item in [ServiceItem.taxComplianceAudit, ServiceItem.taxComplianceAuditAndUndistributedEarningsAudit] {
            let first = try #require(item.scopeTerms.first)
            #expect(first.content.hasPrefix("主要係包括執行營利事業所得稅結算申報程序"))
        }

        let undistributed = try #require(ServiceItem.taxComplianceAuditAndUndistributedEarningsAudit.scopeTerms.last)
        #expect(undistributed.content == "主要係未分配盈餘結算申報與查核。")
    }

    // MARK: 合約注意事項

    @Test("削價註已移除")
    func priceUndercuttingNoteRemoved() {
        #expect(qcm.getNote(uniqueCode: "5") == nil)
        #expect(!qcm.contractNoteManager.notes.contains { $0.fullContent.contains("不以不正當之削價方式") })
    }

    /// 母版上這兩條備註是以「附加服務選項1：」「附加服務選項2：」開頭的，但**序號不寫在這裡** ——
    /// 它取決於該份報價單最後印出哪幾條，由 OC `GetContractNotes` 依最終清單編號後掛上前綴。
    /// 這裡只驗內文用字；號碼與前綴的契約在 `ContractNoteOptionGroupTests`。
    @Test("附加服務兩條註的用字")
    func additionalServiceNotes() throws {
        let ctp = try #require(qcm.getNote(uniqueCode: "1"))
        #expect(ctp.optionGroup == .additionalService)
        #expect(ctp.fullContent.hasPrefix("代辦年度CTP申報"))
        #expect(ctp.fullContent.contains("依據公司法第22條之1"))
        #expect(!ctp.fullContent.contains("增訂"))
        #expect(ctp.fullContent.contains("(董事、監察及經理人)"))

        let premium = try #require(qcm.getNote(uniqueCode: "7"))
        #expect(premium.optionGroup == .additionalService)
        #expect(premium.fullContent.hasPrefix("依全民健康保險扣取"))
    }

    @Test("稅簽優點第 3 點改成電腦選案比率")
    func taxAuditBenefitNote() throws {
        for code in ["12", "13"] {
            let note = try #require(qcm.getNote(uniqueCode: code)).fullContent
            #expect(note.contains("3.降低國稅局電腦選案比率，"))
            #expect(!note.contains("抽查查帳比率"))
        }
    }

    @Test("最新稅務訊息註加上「(除特定專案外)」")
    func taxNewsNote() throws {
        let note = try #require(qcm.getNote(uniqueCode: "2")).fullContent
        #expect(note.contains("教育訓練課程(除特定專案外)，"))
    }

    // MARK: 信件

    @Test("信件內文在公司名與服務名之間補「有關」")
    func letterContent() {
        #expect(qcm.letter.content.hasPrefix(
            "茲將附上\(TemplateVariableConcept.quotingCaseName.placeholder())有關\(TemplateVariableConcept.serviceItemNames.placeholder())之專業服務公費報價單。"
        ))
    }
}

/// 註一（報價基準）／註二（付款條件）的動態組裝。
///
/// 1150828 母版把三家服務的報價基準併成一條註、付款條件併成另一條，但內容要依實際選到的服務裁剪
/// （只選財簽就只印財簽那句）。一條 note 一個固定字串表達不了，所以 `ContractNoteInfo` 改成
/// 由數個帶 trait 條件的 `Segment` 組成，由 `composedContent(subsetOf:)` 在加進報價單時組出成品。
///
/// 期望值寫完整字串而不是 `contains`，因為這兩條註的**標點銜接**正是容易出錯的地方：
/// 少印中間某一段時，段落之間的「，」「；」「。」要跟著收斂。
@Suite("1150828 註一／註二 的動態組裝")
struct CompositeContractNoteTests {

    private let qcm = QuotingContentManager.standard

    private let financialAudit = "ServiceItem/FinancialComplianceAudit"
    private let taxAudit = "ServiceItem/TaxComplianceAudit"
    private let accounting = "ServiceItem/Accounting"
    private let companyRegistration = "ServiceItem/CompanyRegistration"

    private func composed(_ uniqueCode: String, _ tags: [String], forTaxAccount isTaxAccount: Bool = true) throws -> String? {
        let note = try #require(qcm.getNote(uniqueCode: uniqueCode))
        guard note.isSubsetOf(tags: tags) else { return nil }   // 整條備註不適用
        guard let content = note.composedContent(subsetOf: tags) else { return nil }
        return content.replacingOccurrences(
            of: TemplateVariableConcept.accountingWorkName.placeholder(),
            with: qcm.accountingWorkDisplayName(forAccountingType: isTaxAccount ? "taxAccount" : "financialAccount")
        )
    }

    // MARK: 註一

    // 註一原本還包含三句報價基準（「…依預估…報價」）。最後裁定那三句只住在酬金補充說明
    // （`PaymentItemManager`），不複製進合約注意事項 —— 下面兩條釘住這件事，
    // 避免日後有人又把它搬回來造成 PDF 上印兩次。
    //
    // 第一句的主詞隨服務裁剪（2026-10-02 裁定）；第二句（稅務諮詢費用）不綁稅簽，一律出現。
    private static let noteOneTail = """
    若有巨額變動或變更申報方式，將另與　貴公司討論報價金額。
    又 貴公司若後續無營利事業所得稅查核簽證及未分配盈餘查核簽證服務，本事務所將另行收取稅務諮詢費用。
    """

    /// 七種服務組合 × 第一句的主詞。記帳那段自己就含「營業收入總額」，所以同時有稅簽時
    /// 稅簽那段要讓位 —— 否則會印成「營業收入總額、營業收入總額及憑證量」。
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

    /// 主詞不會重複印「營業收入總額」—— 稅簽與記帳講的是同一個指標，記帳只是多管一個憑證量。
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
        簽證公費請於當年度末日前支付半數，另外半數請於次年度五月末日前支付；稅務申報服務作業費用%AccountingPeriod%，並%AccountingBilling%，並應支付至本事務所指定之銀行帳戶。
        承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款。
        """)
        // 財簽與稅簽的付款句在改版前是兩條 note 各一份、內容一模一樣；併條之後只能出現一次。
        #expect(content.components(separatedBy: "簽證公費請於當年度末日前支付半數").count - 1 == 1)
    }

    @Test("註二 — 只有簽證沒有記帳：中段消失，標點要收斂")
    func noteTwoAuditOnly() throws {
        #expect(try composed("17", [financialAudit]) == """
        簽證公費請於當年度末日前支付半數，另外半數請於次年度五月末日前支付。
        承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款。
        """)
    }

    @Test("註二 — 只有記帳：簽證那句消失，由記帳那段起頭")
    func noteTwoAccountingOnly() throws {
        #expect(try composed("17", [accounting], forTaxAccount: false) == """
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

    // 母版順序：註一（報價基準）→ 註二（付款條件）→ 註三（稅簽優點）→ 註四（CTP）→ 註五（補充保費）
    // → 註六（非稅簽查核）→ 註七（最新稅務訊息）。改版前 CTP（30）排在稅簽優點（20）之前，與母版相反。
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
