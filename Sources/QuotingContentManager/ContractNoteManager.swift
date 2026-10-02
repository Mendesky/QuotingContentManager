//
//  ContractNoteManager.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

public struct ContractNoteManager: Sendable {
    public var notes: [ContractNoteInfo] = [
        // ── 註一：變動條款與稅務諮詢費 ──────────────────────────────────
        // 1150828 母版的註一原本還包含財簽／稅簽／記帳三家的報價基準（「…依預估…報價」）。
        // 最後裁定那三句只住在**酬金補充說明**（`PaymentItemManager`），不複製進合約注意事項。
        //
        // 第一句的**主詞隨選到的服務裁剪**（2026-10-02 業務裁定，推翻先前「不裁剪」的裁定）：
        // 每個服務各自貢獻一段主詞，依序以「、」相接。
        //
        //   財簽 → 資產總額　／　稅簽 → 營業收入總額　／　記帳 → 營業收入總額及憑證量
        //
        // 記帳那段**已經含「營業收入總額」**，所以稅簽那段在同時有記帳時要讓位（`excluded`），
        // 否則會印成「營業收入總額、營業收入總額及憑證量」。這是去重，不是互斥 ——
        // 兩個服務講的是同一個指標，只是記帳多管一個憑證量。
        //
        // 七種組合的結果：
        //   財簽            → 資產總額
        //   稅簽            → 營業收入總額
        //   記帳            → 營業收入總額及憑證量
        //   財簽＋稅簽       → 資產總額、營業收入總額
        //   財簽＋記帳       → 資產總額、營業收入總額及憑證量
        //   稅簽＋記帳       → 營業收入總額及憑證量
        //   財簽＋稅簽＋記帳  → 資產總額、營業收入總額及憑證量
        //
        // 主詞一段都沒命中是不可能的：整條備註的 trait 就是這三個的 ANY-of，命中才會出現這條
        // （所以純工商登記的案子連這條都沒有）。
        //
        // 第二句（稅務諮詢費用）**不綁稅簽**，只要這條備註出現就印（2026-09 裁定，未變）。
        .init(uniqueCode: "16", traits: [
            "ServiceItem/FinancialComplianceAudit",
            "ServiceItem/TaxComplianceAudit",
            "ServiceItem/Accounting",
        ], weight: 80, segments: [
            .init("資產總額", traits: ["ServiceItem/FinancialComplianceAudit"]),
            .init(
                "營業收入總額",
                separator: "、",
                traits: [.init(tags: ["ServiceItem/TaxComplianceAudit"], excluded: ["ServiceItem/Accounting"])]
            ),
            .init("營業收入總額及憑證量", separator: "、", traits: ["ServiceItem/Accounting"]),
            .init("""
            若有巨額變動或變更申報方式，將另與　貴公司討論報價金額。
            又 貴公司若後續無營利事業所得稅查核簽證及未分配盈餘查核簽證服務，本事務所將另行收取稅務諮詢費用。
            """),
        ]),

        // ── 註二：付款條件 ────────────────────────────────────────────────
        // 同樣是母版併成一條。簽證那句財簽與稅簽各有一份且字一樣，兩個都選時只印一次（去重）——
        // 寫成單一段落、trait 列兩個 tag（ANY-of）即可，不必在呼叫端做字串比對去重。
        //
        // 代墊費用那段**無條件**，但註二整條只在有財簽／稅簽／記帳任一時才出現，
        // 所以純工商登記的案子連註二都沒有，不會印到它。
        .init(uniqueCode: "17", traits: [
            "ServiceItem/FinancialComplianceAudit",
            "ServiceItem/TaxComplianceAudit",
            "ServiceItem/Accounting",
        ], weight: 78, segments: [
            .init("簽證公費請於當年度末日前支付半數，另外半數請於次年度五月末日前支付",
                  traits: ["ServiceItem/FinancialComplianceAudit", "ServiceItem/TaxComplianceAudit"]),
            .init("\(TemplateVariableConcept.accountingWorkName.placeholder())作業費用\(TemplateVariableConcept.accountingPeriod.placeholder())，並\(TemplateVariableConcept.accountingBilling.placeholder())，並應支付至本事務所指定之銀行帳戶",
                  separator: "；", traits: ["ServiceItem/Accounting"]),
            .init("承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款",
                  separator: "。\n"),
        ], terminator: "。"),

        // 前綴「附加服務選項N：」不寫死在這裡 —— 序號取決於當下有幾條同群組備註與其排序，
        // 由讀取端算（見 `ContractNoteInfo.OptionGroup`）。
        .init(uniqueCode: "1", traits: ["ServiceItem/Ctp"], weight: 30, optionGroup: .additionalService, content: """
        代辦年度CTP申報(每年3月)，依據公司法第22條之1是為了配合洗錢防制政策，協助建置完善洗錢防制體制，強化洗錢防制作為，以增加法人(公司)之透明度，並有效掌握公司負責人(董事、監察及經理人)及主要股東(持有超過10%股份或出資額股東)之持股或出資額。
        """),
        .init(uniqueCode: "2", traits: ["general", "Tip/benefit"], weight: 0, content: """
        最新稅務訊息通知，本事務所另將不定期以電子郵件寄送最新稅務法令之變更、稅捐獎勵減免等有關訊息供　貴公司參考，亦可免費參加本所舉辦之教育訓練課程(除特定專案外)，以使　貴公司與本事務所共同成長。
        """),
        // 3 / 15 是公司版（含其他非行號型態）；行號版為 18 / 17，以組織型態 tag 分流 —— 見 18 上方說明。
        .init(uniqueCode: "3", traits: [
            .init(tags: ["ServiceItem/CompanyRegistration"], excluded: [OrganizationType.soleProprietorshipOrPartnership.contractNoteTag]),
        ], weight: 66, content: """
        工商登記費用不包含政府規費、投審司（外國人）、動資查核、工廠及特許項目之登記及代墊之什項費用(依其收據請款)，服務公費及代墊費用請於辦理完成時支付。
        如股東超過5人，第6位起每位加收新台幣500元之防制洗錢查核費。
        """),
        // uniqueCode 5（「依據會計師職業道德，不以不正當之削價方式…」）已於 1150828 母版改版移除。
        // 它的 trait 是「稅簽＋財簽同時存在」，而母版 A、B 正好都是這個組合卻都沒有這條，
        // 所以是刻意拿掉、不是沒觸發。存量報價單不受影響：備註內容是快照寫進 Quotation 的
        // `ContractNoteAddedByTraits.note`。
        .init(uniqueCode: "7", traits: [
            "ServiceItem/AssistanceAnnualSupplementaryPremiumDeductionDetailsReporting",
        ], weight: 25, optionGroup: .additionalService, content: """
        依全民健康保險扣取及繳納補充保費辦法第10條規定，扣繳義務人申報扣費明細時點，採年度申報應於每年1/31前將上一年度向保險對象扣取之補充保費金額，填報扣費明細彙報健保署。
        """),
        // 曾有一筆 uniqueCode 16 是本段文案的「專案整帳」版本，已於 2026-09-15 移除——
        // 專案整帳不再有「是否提供電子檔」config（OC 寫側擋掉），該 trait 組合永遠不成立。
        // 存量報價單不受影響：備註內容是快照寫進 Quotation 的 `ContractNoteAddedByTraits.note`。
        .init(uniqueCode: "9", mutex: .tags(["ServiceItemConfig/is_providing_electronic_file:false"]), traits: [
            .init(tags: [
                "ServiceItem/AccountingReform",
                "ServiceItemConfig/is_providing_electronic_file:true",
            ]),
        ], weight: 50, content: """
        須提供 \(TemplateVariableConcept.reformPeriod.placeholder()) 相關會計帳務報表及帳冊（含日記帳、實帳戶科目餘額明細）Excel 電子檔，若未能提供將另與　貴公司討論報價金額。
        """),
        .init(uniqueCode: "10", traits: [
            .init(tags: [
                "ServiceItem/CashierOperation",
            ]),
        ], weight: 40, content: """
        出納事務處理作業內容包含：
        A.國內轉帳30 筆；每加⼀筆多50 元。
        B.國外轉帳10 筆；每加⼀筆多100 元。
        C.⼀次薪資轉帳。
        *如出納事務處理作業有重複處理，將額外收取處理費用2,000元/次。
        公費費用\(TemplateVariableConcept.cashierPeriod.placeholder())，並\(TemplateVariableConcept.cashierBilling.placeholder())
        """),
        .init(uniqueCode: "11", traits: [
            .init(tags: [
                "ServiceItem/PayrollSupportOperation",
            ]),
        ], weight: 35, content: """
        薪資人力支援處理作業500元/人/月；基本收費3,000/月。
        公費費用\(TemplateVariableConcept.payrollSupportPeriod.placeholder())，並\(TemplateVariableConcept.payrollSupportBilling.placeholder())
        """),
        .init(uniqueCode: "12", mutex: .codes(["13"]), traits: [
            .init(tags: [
                "ServiceItem/TaxComplianceAudit",
            ], excluded: [
                "ServiceItem/FinancialComplianceAudit",
            ]),
        ], weight: 32, content: """
        營利事業所得稅查核簽證包括營利事業所得稅結算申報及依「所得稅法」規定進行查核簽證。
        有關會計師稅務簽證之優點列舉如下：
        1.提高交際費限額，較普通申報案件高出30%。
        2.享有盈虧互抵之優惠。
        3.降低國稅局電腦選案比率，倘若有查帳情況將由本事務所會計師親至國稅局處理之。
        """),
        .init(uniqueCode: "13", mutex: .codes(["12"]), traits: [
            .init(tags: [
                "ServiceItem/TaxComplianceAudit",
                "ServiceItem/FinancialComplianceAudit",
            ]),
        ], weight: 32, content: """
        營利事業所得稅查核簽證包括營利事業所得稅結算申報及依「所得稅法」規定進行查核簽證。
        有關會計師稅務簽證之優點列舉如下：
        1.提高交際費限額，較普通申報案件高出30%。
        2.享有盈虧互抵之優惠。
        3.降低國稅局電腦選案比率，倘若有查帳情況將由本事務所會計師親至國稅局處理之。
        """),
        .init(uniqueCode: "14", traits: ["ServiceItem/Accounting"], weight: 5, content: """
        採非稅務簽證申報之案件當年度若需協助國稅局營所稅查核，將另與　貴公司討論服務費報價金額。
        """),
        .init(uniqueCode: "15", traits: [
            .init(tags: ["ServiceItem/CompanyRegistration"], excluded: [OrganizationType.soleProprietorshipOrPartnership.contractNoteTag]),
        ], weight: 67, content: """
        工商登記處理作業：\(TemplateVariableConcept.organizationTypeName.placeholder())、\(TemplateVariableConcept.capital.placeholder(variant: "exact"))、\(TemplateVariableConcept.companyRegistrationRegion.placeholder())、\(TemplateVariableConcept.companyRegistrationShareholder.placeholder())。
        """),
        // 行號（獨資合夥）版工商登記備註：17 對應 15、18 對應 3。行號依商業登記法辦商業登記
        // （不是向經濟部辦公司登記）—— 沒有動資查核、也沒有股東超過 5 人的防制洗錢查核費。
        //
        // 分流靠 OC 為每個案件多帶的組織型態 tag（`OrganizationType.contractNoteTag`）：行號版要求它、
        // 公司版以 `excluded` 排除它。trait 刻意**保留** `ServiceItem/CompanyRegistration` ——
        // OC `ContractNoteSynchronizer` 的 stale 清理只處理 trait 含 `ServiceItem/` 前綴的 uniqueCode，
        // 少了它，改型態或移除工商登記卡後這兩筆會殘留在報價單上。
        .init(uniqueCode: "17", traits: [
            .init(tags: ["ServiceItem/CompanyRegistration", OrganizationType.soleProprietorshipOrPartnership.contractNoteTag]),
        ], weight: 67, content: """
        工商登記處理作業：\(TemplateVariableConcept.soleProprietorshipOrPartnershipName.placeholder())、\(TemplateVariableConcept.capital.placeholder(variant: "exact"))、\(TemplateVariableConcept.companyRegistrationRegion.placeholder())、\(TemplateVariableConcept.companyRegistrationShareholder.placeholder())。
        """),
        .init(uniqueCode: "18", traits: [
            .init(tags: ["ServiceItem/CompanyRegistration", OrganizationType.soleProprietorshipOrPartnership.contractNoteTag]),
        ], weight: 66, content: """
        工商登記費用不包含政府規費、投審司（外國人）、工廠及特許項目之登記及代墊之什項費用(依其收據請款)，服務公費及代墊費用請於辦理完成時支付。
        """),
    ]

    public init() {}

}
