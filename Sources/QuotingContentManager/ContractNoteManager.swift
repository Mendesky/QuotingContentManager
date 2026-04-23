//
//  ContractNoteManager.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

public struct ContractNoteManager: Sendable {
    public var notes: [ContractNoteInfo] = [
        .init(uniqueCode: "1", traits: ["ServiceItem/CTP"], weight: 30, content: """
        附加服務選項：代辦年度 CTP 申報(每年 3 月)，依據公司法增訂第 22 條之 1 是為了配合洗錢防制政策，協助建置完善洗錢防制體制，強化洗錢防制作為，以增加法人(公司)之透明度，並有效掌握公司負責人(董事、監察人及經理人)及主要股東(持有超過 10%股份或出資額股東)之持股或出資額。
        """),
        .init(uniqueCode: "2", traits: ["general", "Tip/benefit"], weight: 0, content: """
        最新稅務訊息通知及教育訓練免費參加本事務所將定期以電子郵件寄送最新稅務法令之變更、稅捐獎勵減免、會計審計學術專論等有關訊息供　貴公司參考。
        另外，本事務所將針對客戶之需要，開設不同財稅課程，對於本事務所之客戶將可免費參加，以使　貴公司與本事務所共同成長。
        """),
        .init(uniqueCode: "3", traits: ["ServiceItem/Accounting"], weight: 15, content: """
        本事務所將依據  貴公司所提供之資料及文件，利用會計專業知識蒐集、分類及彙總財務資訊，進而提供會計帳務處理作業服務項目，無須對資訊加以查核或核閱，所提供之財務資訊亦不提供任何程度之確信。
        """),
        .init(uniqueCode: "4", traits: ["ServiceItem/Accounting"], weight: 15, content: """
        本事務所所提供會計帳務處理作業服務，僅限協助 貴公司完成相關專業服務使用。除本事務所有可歸責之情形外，如本事務所於本報價單意旨提供會計帳務處理作業服務事項，而遭致第三人向本事務所為法律上之主張而致生損害時， 貴公司同意負責補償。另未經本事務所書面同意，本事務所所提供之服務不得提供他人使用(其中不包含提供予股東開會使用)；且若有此種情形致他人權益受損，本事務所不負任何責任。
        """),
        .init(uniqueCode: "7", traits: ["ServiceItem/CompanyRegistration"], weight: 66, content: """
        工商登記費用不包含政府規費及代墊雜項費用，服務公費及代墊費用請於辦理完成時支付。
        如股東超過5人，第6位起每位加收新台幣500元之防制洗錢查核費。
        """),
        .init(uniqueCode: "8", traits: ["ServiceItem/FinancialComplianceAudit"], weight: 75, content: """
        %FinancialComplianceAuditGroundName%若有巨額變動，將另與　貴公司討論報價金額。
        簽證公費請於當年底時支付半數，另外半數請於交付報告時支付。
        承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款。
        """),
        .init(uniqueCode: "10", traits: [
            "ServiceItem/TaxComplianceAudit",
            "ServiceItem/FinancialComplianceAudit",
        ], weight: 10, content: """
        依據會計師職業道德，不以不正當之削價方式，延攬業務，故若查明有此事實，將比照前事務所收費辦理。
        """),
        .init(uniqueCode: "11", traits: [
            .init(tags: [
                "ServiceItem/TaxComplianceAudit",
            ]),
        ], weight: 70, content: """
        營業收入總額若有巨額變動，將另與　貴公司討論報價金額。
        簽證公費請於當年底時支付半數，另外半數請於交付報告時支付。
        承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款。
        """),
        .init(uniqueCode: "12", traits: [
            "ServiceItem/AssistanceAnnualSupplementaryPremiumDeductionDetailsReporting",
        ], weight: 25, content: """
        依全民健康保險扣取及繳納補充保費辦法第10條規定，扣繳義務人申報扣費明細時點，採年度申報應於每年1/31前將上一年度向保險對象扣取之補充保費金額，填報扣費明細彙報健保署。
        """),
        .init(uniqueCode: "13", traits: [
            .init(tags: [
                "ServiceItem/Accounting",
            ]),
        ], weight: 65, content: """
        營業收入總額及憑證量若有巨額變動或變更稅務申報方式，將另與　貴公司討論報價金額。
        %AccountingPeriod%，並%AccountingBilling%
        """),
        .init(uniqueCode: "15", mutex: .tags(["ServiceItemConfig/is_providing_electronic_file:false"]), traits: [
            .init(tags: [
                "ServiceItem/AccountingReform",
                "ServiceItemConfig/is_providing_electronic_file:true",
            ]),
        ], weight: 50, content: """
        須提供 %Reform:period% 相關會計帳務報表及帳冊（含日記帳、實帳戶科目餘額明細）Excel 電子檔，若未能提供將另與　貴公司討論報價金額。
        """),
        .init(uniqueCode: "16", traits: [
            .init(tags: [
                "ServiceItem/CashierOperation",
            ]),
        ], weight: 40, content: """
        出納事務處理作業內容包含：
        A.國內轉帳30 筆；每加⼀筆多50 元。
        B.國外轉帳10 筆；每加⼀筆多100 元。
        C.⼀次薪資轉帳。
        *如出納事務處理作業有重複處理，將額外收取處理費用2,000元/次。
        %CashierPeriod%，並%CashierBilling%
        """),
        .init(uniqueCode: "17", traits: [
            .init(tags: [
                "ServiceItem/PayrollSupportOperation",
            ]),
        ], weight: 35, content: """
        薪資人力支援處理作業500元/人/月；基本收費3,000/月。
        %PayrollSupportPeriod%，並%PayrollSupportBilling%
        """),
        .init(uniqueCode: "18", mutex: .codes(["19"]), traits: [
            .init(tags: [
                "ServiceItem/TaxComplianceAudit",
            ], excluded: [
                "ServiceItem/FinancialComplianceAudit",
            ]),
        ], weight: 20, content: """
        營利事業所得稅查核簽證包括營利事業所得稅結算申報及依「所得稅法」規定進行查核簽證。
        有關會計師稅務簽證之優點列舉如下：
        1、提高交際費限額，較普通申報案件高出 30%。
        2、享有盈虧互抵之優惠。
        3、降低國稅局抽查查帳比率，倘若有查帳情況將由本事務所會計師親至國稅局處理之。
        """),
        .init(uniqueCode: "19", mutex: .codes(["18"]), traits: [
            .init(tags: [
                "ServiceItem/TaxComplianceAudit",
                "ServiceItem/FinancialComplianceAudit",
            ]),
        ], weight: 20, content: """
        營利事業所得稅查核簽證包括營利事業所得稅結算申報及依「所得稅法」規定進行查核簽證。
        有關會計師稅務簽證之優點列舉如下：
        1、提高交際費限額，較普通申報案件高出 30%。
        2、享有盈虧互抵之優惠。
        3、降低國稅局抽查查帳比率，倘若有查帳情況將由本事務所會計師親至國稅局處理之。
        4、未分配盈餘之課稅規定，其課稅所得額以會計師簽證之申報數為準，不須按核定所得額計算。
        """),
        .init(uniqueCode: "20", traits: ["ServiceItem/Accounting"], weight: 5, content: """
        採查帳申報(非稅簽案件)當年度若需協助國稅局營所稅查核，將另與　貴公司討論服務費報價金額。
        """),
    ]

    public init() {}

}
