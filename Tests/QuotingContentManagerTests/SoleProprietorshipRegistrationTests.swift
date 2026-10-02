import Testing
@testable import QuotingContentManager

/// 行號（獨資合夥）工商登記：文案分流、新子項、備註分流（2026-10-01 跨 repo 契約 C1–C3）。
///
/// 公司（及其他非行號型態）的文案與挑選結果必須**完全不變**——每個分流都成對驗「行號走新版、公司維持原版」。
@Suite("行號（獨資合夥）工商登記 — 備註分流")
struct SoleProprietorshipContractNoteTests {

    private let manager = QuotingContentManager.standard
    private let soleProprietorshipTag = OrganizationType.soleProprietorshipOrPartnership.contractNoteTag

    private func codes(for tags: [String]) -> [String] {
        manager.fetchNotes(subsetOf: tags).map(\.uniqueCode)
    }

    @Test("組織型態 tag 為 OrganizationType/<rawValue>")
    func contractNoteTagFormat() {
        #expect(OrganizationType.soleProprietorshipOrPartnership.contractNoteTag == "OrganizationType/soleProprietorshipOrPartnership")
        for type in OrganizationType.allCases {
            #expect(type.contractNoteTag == "\(OrganizationType.contractNoteTagPrefix)\(type.rawValue)")
        }
    }

    @Test("行號 tag 集合挑到 17、18，挑不到 3、15")
    func soleProprietorshipPicksSoleProprietorshipNotes() {
        let picked = codes(for: ["ServiceItem/CompanyRegistration", soleProprietorshipTag])
        #expect(picked.contains("17"))
        #expect(picked.contains("18"))
        #expect(!picked.contains("3"))
        #expect(!picked.contains("15"))
    }

    @Test("非行號型態 tag 集合挑到 3、15，挑不到 17、18", arguments: OrganizationType.allCases.filter { $0 != .soleProprietorshipOrPartnership })
    func companyPicksCompanyNotes(_ type: OrganizationType) {
        let picked = codes(for: ["ServiceItem/CompanyRegistration", type.contractNoteTag])
        #expect(picked.contains("3"))
        #expect(picked.contains("15"))
        #expect(!picked.contains("17"))
        #expect(!picked.contains("18"))
    }

    @Test("沒有組織型態 tag（舊呼叫端）→ 維持公司版 3、15")
    func missingOrganizationTypeTagKeepsCompanyNotes() {
        let picked = codes(for: ["ServiceItem/CompanyRegistration"])
        #expect(picked.contains("3"))
        #expect(picked.contains("15"))
        #expect(!picked.contains("17"))
        #expect(!picked.contains("18"))
        // fetchNotes(serviceItem:) 是同一條路徑的便利版，結果必須一致。
        let viaServiceItem = manager.fetchNotes(serviceItem: "CompanyRegistration").map(\.uniqueCode)
        #expect(Set(viaServiceItem) == Set(picked))
    }

    @Test("只有行號 tag、沒有工商登記 → 17、18 都不挑")
    func soleProprietorshipTagAloneDoesNotPickRegistrationNotes() {
        let picked = codes(for: [soleProprietorshipTag])
        #expect(!picked.contains("17"))
        #expect(!picked.contains("18"))
    }

    @Test("17 = 行號版案件描述（weight 67），placeholder 由 concept 組字")
    func note17Content() {
        let note = manager.getNote(uniqueCode: "17")
        #expect(note?.weight == 67)
        #expect(note?.allSegmentsJoined == "工商登記處理作業：%SoleProprietorshipOrPartnershipName%、%Capital|exact%、%CompanyRegistrationRegion%、%CompanyRegistrationShareholder%。")
        #expect(note?.traits.first?.tags == ["ServiceItem/CompanyRegistration", "OrganizationType/soleProprietorshipOrPartnership"])
        // trait 仍含 ServiceItem/ 前綴 tag —— OC ContractNoteSynchronizer 的 stale 清理只處理這類 uniqueCode。
        #expect(note?.traits.contains { $0.tags.contains { $0.hasPrefix("ServiceItem/") } } == true)
    }

    @Test("18 = 行號版不包含清單（weight 66）：去掉「動資查核、」且沒有股東超過 5 人那行")
    func note18Content() {
        let note = manager.getNote(uniqueCode: "18")
        #expect(note?.weight == 66)
        #expect(note?.allSegmentsJoined == "工商登記費用不包含政府規費、投審司（外國人）、工廠及特許項目之登記及代墊之什項費用(依其收據請款)，服務公費及代墊費用請於辦理完成時支付。")
        #expect(note?.allSegmentsJoined.contains("動資查核") == false)
        #expect(note?.allSegmentsJoined.contains("股東超過5人") == false)
        #expect(note?.traits.first?.tags == ["ServiceItem/CompanyRegistration", "OrganizationType/soleProprietorshipOrPartnership"])
    }

    @Test("公司版 3、15 內容不變，trait 排除行號 tag")
    func companyNotesUnchangedButExcludeSoleProprietorship() {
        let note3 = manager.getNote(uniqueCode: "3")
        #expect(note3?.allSegmentsJoined == """
        工商登記費用不包含政府規費、投審司（外國人）、動資查核、工廠及特許項目之登記及代墊之什項費用(依其收據請款)，服務公費及代墊費用請於辦理完成時支付。
        如股東超過5人，第6位起每位加收新台幣500元之防制洗錢查核費。
        """)
        #expect(note3?.weight == 66)
        #expect(note3?.traits.first?.tags == ["ServiceItem/CompanyRegistration"])
        #expect(note3?.traits.first?.excluded == ["OrganizationType/soleProprietorshipOrPartnership"])

        let note15 = manager.getNote(uniqueCode: "15")
        #expect(note15?.allSegmentsJoined == "工商登記處理作業：%OrganizationTypeName%、%Capital|exact%、%CompanyRegistrationRegion%、%CompanyRegistrationShareholder%。")
        #expect(note15?.weight == 67)
        #expect(note15?.traits.first?.tags == ["ServiceItem/CompanyRegistration"])
        #expect(note15?.traits.first?.excluded == ["OrganizationType/soleProprietorshipOrPartnership"])
    }

    @Test("行號版排序：17（67）在 18（66）之前")
    func soleProprietorshipNotesOrder() {
        let picked = codes(for: ["ServiceItem/CompanyRegistration", soleProprietorshipTag])
        guard let index17 = picked.firstIndex(of: "17"), let index18 = picked.firstIndex(of: "18") else {
            Issue.record("17 / 18 未被挑到：\(picked)")
            return
        }
        #expect(index17 < index18)
    }
}

@Suite("行號（獨資合夥）工商登記 — 服務項目 / 工作項目文案")
struct SoleProprietorshipWorkItemContentTests {

    private let item = ServiceItem.companyRegistration

    private func workItem(_ type: String) -> WorkItem? {
        item.workItems.first { $0.type == type }
    }

    @Test("A 公司名稱預查：行號顯示「商業登記名稱預查」，其他型態不變")
    func reservationContent() {
        let reservation = workItem("companyNameAndBusinessScopeReservation")
        #expect(reservation?.content == "公司名稱預查")
        #expect(reservation?.displayContent(for: .financialAccount, organizationType: .soleProprietorshipOrPartnership) == "商業登記名稱預查")
        for type in OrganizationType.allCases where type != .soleProprietorshipOrPartnership {
            #expect(reservation?.displayContent(for: .financialAccount, organizationType: type) == "公司名稱預查")
        }
        #expect(reservation?.displayContent(for: .financialAccount, organizationType: nil) == "公司名稱預查")
    }

    @Test("B 公司設立登記：行號顯示「商業設立登記」，其他型態不變")
    func registrationContent() {
        let registration = workItem("economicMinistryRegistration")
        #expect(registration?.content == "公司設立登記")
        #expect(registration?.displayContent(for: .financialAccount, organizationType: .soleProprietorshipOrPartnership) == "商業設立登記")
        for type in OrganizationType.allCases where type != .soleProprietorshipOrPartnership {
            #expect(registration?.displayContent(for: .financialAccount, organizationType: type) == "公司設立登記")
        }
    }

    @Test("只有 A、B 有行號專用內容，其餘工作項目行號與公司同字")
    func onlyReservationAndRegistrationDiverge() {
        let divergent = item.workItems.filter {
            $0.displayContent(for: .financialAccount, organizationType: .soleProprietorshipOrPartnership) != $0.content
        }.map(\.type)
        #expect(divergent == ["companyNameAndBusinessScopeReservation", "economicMinistryRegistration"])
    }

    @Test("新子項 smallScaleUniformInvoiceExemption（申請小規模免用統一發票）排在 H（ctpOfCompanyRegistration）之後")
    func smallScaleUniformInvoiceExemptionOrder() {
        let types = item.workItems.map(\.type)
        guard let indexH = types.firstIndex(of: "ctpOfCompanyRegistration"),
              let indexI = types.firstIndex(of: "smallScaleUniformInvoiceExemption") else {
            Issue.record("工作項目缺 H 或 I：\(types)")
            return
        }
        #expect(indexI == indexH + 1)
        #expect(workItem("smallScaleUniformInvoiceExemption")?.content == "申請小規模免用統一發票")
    }

    @Test("帳別版 displayContent(for:) 行為不變（記帳卡稅務帳）")
    func taxAccountContentUnchanged() {
        let accounting = ServiceItem.accounting.workItems.first { $0.type == "accounting" }
        #expect(accounting?.displayContent(for: .taxAccount) == "平時稅務帳務作業")
        #expect(accounting?.displayContent(for: .taxAccount, organizationType: .soleProprietorshipOrPartnership) == "平時稅務帳務作業")
        #expect(accounting?.displayContent(for: .financialAccount, organizationType: .soleProprietorshipOrPartnership) == "平時會計帳務作業")
    }

    @Test("QuotingContentManager.getWorkItem 取得新子項")
    func managerGetWorkItem() {
        let workItem = QuotingContentManager.standard.getWorkItem(serviceType: "CompanyRegistration", workItemType: "smallScaleUniformInvoiceExemption")
        #expect(workItem?.content == "申請小規模免用統一發票")
    }
}

@Suite("TemplateVariableConcept.soleProprietorshipOrPartnershipName")
struct SoleProprietorshipOrPartnershipNameConceptTests {

    @Test("key 為 SoleProprietorshipOrPartnershipName，bundle 級")
    func keyAndScope() {
        #expect(TemplateVariableConcept.soleProprietorshipOrPartnershipName.rawValue == "SoleProprietorshipOrPartnershipName")
        #expect(TemplateVariableConcept.soleProprietorshipOrPartnershipName.scope == .bundle)
        #expect(TemplateVariableConcept.soleProprietorshipOrPartnershipName.placeholder() == "%SoleProprietorshipOrPartnershipName%")
    }
}
