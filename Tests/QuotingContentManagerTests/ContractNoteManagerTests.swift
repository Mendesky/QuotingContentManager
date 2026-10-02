import Testing
@testable import QuotingContentManager

@Suite("ContractNoteManager — 工商登記備註一（案件描述）")
struct ContractNoteManagerRegistrationNote1Tests {

    private var notes: [ContractNoteInfo] {
        ContractNoteManager().notes
    }

    @Test("uniqueCode 15 存在，屬 ServiceItem/CompanyRegistration，weight 高於既有備註 3（66）")
    func note15Exists() {
        let note15 = notes.first { $0.uniqueCode == "15" }
        #expect(note15 != nil)
        #expect(note15?.weight == 67)
        #expect(note15?.traits.first?.tags.contains("ServiceItem/CompanyRegistration") == true)
    }

    @Test("備註一內容含四個範本變數（組織型態、登記/實收資本額 exact、地區、股東）")
    func note15ContainsPlaceholders() {
        let content = notes.first { $0.uniqueCode == "15" }?.allSegmentsJoined ?? ""
        #expect(content.contains("%OrganizationTypeName%"))
        #expect(content.contains("%Capital|exact%"))
        // 不再併排實收／登記兩個 token（依組織型態二擇一靠空字串隱藏，編輯器會露出灰底 [Key]）
        #expect(!content.contains("%PaidInCapital|"))
        #expect(!content.contains("%RegisteredCapital|"))
        // `Capital|exact` 的值本身以「資本額」開頭（如「資本額350萬元」），原文不可再寫死前綴，否則印成「資本額資本額…」
        #expect(!content.contains("資本額%Capital|"))
        #expect(content.contains("、%Capital|exact%、"))
        #expect(content.contains("%CompanyRegistrationRegion%"))
        #expect(content.contains("%CompanyRegistrationShareholder%"))
    }

    @Test("備註一（weight 67）排在既有備註 3（weight 66）之前")
    func note15SortsBeforeNote3() {
        let manager = QuotingContentManager.standard
        let fetched = manager.fetchNotes(serviceItem: "CompanyRegistration")
        let codes = fetched.map(\.uniqueCode)
        let index15 = codes.firstIndex(of: "15")
        let index3 = codes.firstIndex(of: "3")
        #expect(index15 != nil)
        #expect(index3 != nil)
        if let index15, let index3 {
            #expect(index15 < index3)
        }
    }
}

@Suite("ContractNoteManager — 工商登記備註二（不包含清單）擴充")
struct ContractNoteManagerRegistrationNote2Tests {

    @Test("備註 3 第一行含投審司、動資查核、工廠及特許項目字樣")
    func note3ExpandedExclusions() {
        let note3 = ContractNoteManager().notes.first { $0.uniqueCode == "3" }
        let content = note3?.allSegmentsJoined ?? ""
        #expect(content.contains("投審司"))
        #expect(content.contains("動資查核"))
        #expect(content.contains("工廠及特許項目"))
        #expect(content.contains("如股東超過5人，第6位起每位加收新台幣500元之防制洗錢查核費"))
    }
}

@Suite("QuotingContentManager — 母版文案")
struct MasterTemplateTests {

    // ⚠️ 這條的期望值在 1150828 母版改版時**反轉**了。
    // commit 5772dba「母版文案去『有關』」刻意把 letter.content 的「有關」拿掉；1150828 母版
    // （藍儀 CPA）又把它加回來，而且該處沒有刪除線標記、是正文。兩次相隔不久，有可能是那份
    // Word 母版在這一句上沒跟上 5772dba 的修訂。已回報待確認，確認前以母版為準。
    //
    // 1150917 最終版又動了同一句：公司名換成「貴公司」（信件不再顯示公司名稱）。
    // 「有關」在這一版仍然保留，所以上面那段反轉的紀錄依然有效。
    @Test("letter.content（母版文案）含「有關」二字，且變數與其餘文字保留")
    func letterContentKeepsYouGuan() {
        let content = QuotingContentManager.standard.letter.content
        #expect(content.contains("茲將附上 貴公司有關\(TemplateVariableConcept.serviceItemNames.placeholder())之專業服務公費報價單。"))
    }

    @Test("contractHeader／purpose／letter.title 的「有關」不受影響")
    func onlyLetterContentChanged() {
        let manager = QuotingContentManager.standard
        #expect(manager.contractHeader.title.contains("有關"))
        #expect(manager.contractHeader.content.contains("有關"))
        #expect(manager.letter.title.contains("有關"))
        #expect(manager.purpose.content.contains("有關"))
    }
}
