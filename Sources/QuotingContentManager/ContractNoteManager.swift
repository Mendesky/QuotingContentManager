//
//  ContractNoteManager.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

public struct ContractNoteManager: Sendable {
    public var notes: [ContractNoteInfo] = [
        .init(uniqueCode: "1", traits: ["ServiceItem/CTP"], weight: 30, content: """
        附加服務選項：代辦年度CTP申報(每年3月)，依據公司法增訂第22條之1是為了配合洗錢防制政策，協助建置完善洗錢防制體制，強化洗錢防制作為，以增加法人(公司)之透明度，並有效掌握公司負責人(董事、監察人及經理人)及主要股東(持有超過10%股份或出資額股東)之持股或出資額。
        """),
        .init(uniqueCode: "2", traits: ["general", "Tip/benefit"], weight: 0, content: """
        最新稅務訊息通知，本事務所另將不定期以電子郵件寄送最新稅務法令之變更、稅捐獎勵減免等有關訊息供　貴公司參考，亦可免費參加本所舉辦之教育訓練課程，以使　貴公司與本事務所共同成長。
        """),
        .init(uniqueCode: "3", traits: ["ServiceItem/CompanyRegistration"], weight: 66, content: """
        工商登記費用不包含政府規費及代墊雜項費用，服務公費及代墊費用請於辦理完成時支付。
        如股東超過5人，第6位起每位加收新台幣500元之防制洗錢查核費。
        """),
        .init(uniqueCode: "4", traits: ["ServiceItem/FinancialComplianceAudit"], weight: 75, content: """
        %FinancialComplianceAuditGroundName%若有巨額變動，將另與　貴公司討論報價金額。
        簽證公費請於當年度末日前支付半數，另外半數請於次年度五月末日前支付。
        """),
        .init(uniqueCode: "5", traits: [
            "ServiceItem/TaxComplianceAudit",
            "ServiceItem/FinancialComplianceAudit",
        ], weight: 10, content: """
        依據會計師職業道德，不以不正當之削價方式，延攬業務，故若查明有此事實，將比照前事務所收費辦理。
        """),
        .init(uniqueCode: "6", traits: [
            .init(tags: [
                "ServiceItem/TaxComplianceAudit",
            ]),
        ], weight: 70, content: """
        營業收入總額若有巨額變動，將另與　貴公司討論報價金額。
        簽證公費請於當年度末日前支付半數，另外半數請於次年度五月末日前支付。
        """),
        .init(uniqueCode: "7", traits: [
            "ServiceItem/AssistanceAnnualSupplementaryPremiumDeductionDetailsReporting",
        ], weight: 25, content: """
        依全民健康保險扣取及繳納補充保費辦法第10條規定，扣繳義務人申報扣費明細時點，採年度申報應於每年1/31前將上一年度向保險對象扣取之補充保費金額，填報扣費明細彙報健保署。
        """),
        .init(uniqueCode: "8", traits: [
            .init(tags: [
                "ServiceItem/Accounting",
            ]),
        ], weight: 65, content: """
        營業收入總額及憑證量若有巨額變動或變更申報方式，將另與　貴公司討論報價金額。
        %AccountingWorkName%處理作業費用一年以十四個月計算，並請於單月份之末日前支付前兩個月之公費(舉例而言，3月31日前應支付1月份與2月份之公費，而當年度11月與12月之費用應於次年1月31日前支付)，並應支付至本事務所指定之銀行帳戶。
        承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款。
        """),
        .init(uniqueCode: "9", mutex: .tags(["ServiceItemConfig/is_providing_electronic_file:false"]), traits: [
            .init(tags: [
                "ServiceItem/AccountingReform",
                "ServiceItemConfig/is_providing_electronic_file:true",
            ]),
        ], weight: 50, content: """
        須提供 %Reform:period% 相關會計帳務報表及帳冊（含日記帳、實帳戶科目餘額明細）Excel 電子檔，若未能提供將另與　貴公司討論報價金額。
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
        %CashierPeriod%，並%CashierBilling%
        """),
        .init(uniqueCode: "11", traits: [
            .init(tags: [
                "ServiceItem/PayrollSupportOperation",
            ]),
        ], weight: 35, content: """
        薪資人力支援處理作業500元/人/月；基本收費3,000/月。
        %PayrollSupportPeriod%，並%PayrollSupportBilling%
        """),
        .init(uniqueCode: "12", mutex: .codes(["13"]), traits: [
            .init(tags: [
                "ServiceItem/TaxComplianceAudit",
            ], excluded: [
                "ServiceItem/FinancialComplianceAudit",
            ]),
        ], weight: 20, content: """
        營利事業所得稅查核簽證包括營利事業所得稅結算申報及依「所得稅法」規定進行查核簽證。
        有關會計師稅務簽證之優點列舉如下：
        1.提高交際費限額，較普通申報案件高出30%。
        2.享有盈虧互抵之優惠。
        3.降低國稅局抽查查帳比率，倘若有查帳情況將由本事務所會計師親至國稅局處理之。
        """),
        .init(uniqueCode: "13", mutex: .codes(["12"]), traits: [
            .init(tags: [
                "ServiceItem/TaxComplianceAudit",
                "ServiceItem/FinancialComplianceAudit",
            ]),
        ], weight: 20, content: """
        營利事業所得稅查核簽證包括營利事業所得稅結算申報及依「所得稅法」規定進行查核簽證。
        有關會計師稅務簽證之優點列舉如下：
        1.提高交際費限額，較普通申報案件高出30%。
        2.享有盈虧互抵之優惠。
        3.降低國稅局抽查查帳比率，倘若有查帳情況將由本事務所會計師親至國稅局處理之。
        """),
        .init(uniqueCode: "14", traits: ["ServiceItem/Accounting"], weight: 5, content: """
        採非稅務簽證申報之案件當年度若需協助國稅局營所稅查核，將另與　貴公司討論服務費報價金額。
        """),
    ]

    public init() {}

}
