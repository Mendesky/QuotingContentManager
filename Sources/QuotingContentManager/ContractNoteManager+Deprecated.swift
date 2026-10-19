//
//  ContractNoteManager+Deprecated.swift
//  QuotingContentManager
//

extension ContractNoteManager {
    /// 停用（deprecated）的備註。不會再被帶到任何報價單（`QuotingContentManager` 的查詢一律排除），
    /// 但**定義不能刪**：OC 同步靠這些定義認出既有報價單上的舊備註，同步時把它們清掉
    /// （刪除與停用的差別見 `ContractNoteManager` 型別說明）。內容照原文保留，只供辨識。
    ///
    /// 2026-10-15 正式 DB 盤點：草稿已沒有這些編號，但已立案未成交 933 張、已成交 121 張仍帶著
    /// （含舊系統搬來、同號不同義的）。刪掉定義的話，已立案的報價單之後一同步，OC 加的舊備註就清不掉，
    /// 會和取代它們的新備註同一個主題印兩次。
    static let deprecatedNotes: [ContractNoteInfo] = [
        // ── 已被註一／註二取代：4 財簽、6 稅簽、8 記帳 ──────────────────────────
        // 1150828 母版改版前，「巨額變動＋付款條件」是三家各一條；改版後併成上面的 16（註一）與 21（註二）。
        // 標 deprecated 而不是刪除：既有報價單同步時要清掉它們，否則會和 16/21 同一個主題印兩次。
        // 內容照 main 上的原文保留，只供辨識，不會再被帶出。
        .init(deprecated: true, uniqueCode: "4", traits: ["ServiceItem/FinancialComplianceAudit"], weight: 75, content: """
        \(TemplateVariableConcept.financialComplianceAuditGroundName.placeholder())若有巨額變動，將另與 貴公司討論報價金額。
        簽證公費請於當年度末日前支付半數，另外半數請於次年度五月末日前支付。
        """),
        .init(deprecated: true, uniqueCode: "6", traits: [
            .init(tags: [
                "ServiceItem/TaxComplianceAudit",
            ]),
        ], weight: 70, content: """
        營業收入總額若有巨額變動，將另與 貴公司討論報價金額。
        簽證公費請於當年度末日前支付半數，另外半數請於次年度五月末日前支付。
        """),
        .init(deprecated: true, uniqueCode: "8", traits: [
            .init(tags: [
                "ServiceItem/Accounting",
            ]),
        ], weight: 65, content: """
        營業收入總額及憑證量若有巨額變動或變更申報方式，將另與 貴公司討論報價金額。
        \(TemplateVariableConcept.accountingWorkName.placeholder())處理作業費用\(TemplateVariableConcept.accountingPeriod.placeholder())，並\(TemplateVariableConcept.accountingBilling.placeholder())，並應支付至本事務所指定之銀行帳戶。
        承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款。
        """),

        // 削價（職業道德）註：1150828 母版拿掉。它的 trait 是稅簽、財簽**任一**（兩個獨立 Trait），
        // 母版 A、B 都有稅簽與財簽卻都沒有這條，所以是刻意拿掉、不是沒觸發。
        // 標 deprecated：既有的未成交報價單也要拿掉（2026-10-05 裁定；原本是刪除、保留既有的）。
        // 內容照 main 上的原文保留，只供辨識，不會再被帶出。
        .init(deprecated: true, uniqueCode: "5", traits: [
            "ServiceItem/TaxComplianceAudit",
            "ServiceItem/FinancialComplianceAudit",
        ], weight: 10, content: """
        依據會計師職業道德，不以不正當之削價方式，延攬業務，故若查明有此事實，將比照前事務所收費辦理。
        """),

        // 本段文案曾有「專案整帳」版本（當時的 uniqueCode 16），已於 2026-09-15 移除——
        // 專案整帳不再有「是否提供電子檔」config（OC 寫側擋掉），該 trait 組合永遠不成立。
        // 16 之後被 1150828 改版重用成註一，見型別說明的「uniqueCode 不可重用」。
        //
        // 2026-10-15 標 deprecated（當時由 22 取代；22 也在 2026-10-19 取消，見下一條）。不改變任何現行行為 ——
        // OC 同步從不帶 `ServiceItemConfig/` 的 tag，這條本來就帶不出來，同步時也一直被當成不適用而清掉。
        .init(deprecated: true, uniqueCode: "9", mutex: .tags(["ServiceItemConfig/is_providing_electronic_file:false"]), traits: [
            .init(tags: [
                "ServiceItem/AccountingReform",
                "ServiceItemConfig/is_providing_electronic_file:true",
            ]),
        ], weight: 50, content: """
        須提供 \(TemplateVariableConcept.reformPeriod.placeholder()) 相關會計帳務報表及帳冊（含日記帳、實帳戶科目餘額明細）Excel 電子檔，若未能提供將另與 貴公司討論報價金額。
        """),

        // 整帳電子檔：2026-10-15 為 1151015 文案新增（有整帳就印、整理費酬金名稱接「；註二」），
        // 2026-10-19 業務取消，連同它專用的日期範本變數（ReformEndDate、ReformOpeningMonth、ReformPeriod 的
        // |plain／|short）與酬金名稱接註號一併拿掉。標 deprecated 而非刪除：QCM main 曾帶著它，若有 OC 以那個版本
        // 同步過報價單，下次同步會把它清掉。
        //
        // 內文**不是**原文：原文引用的範本變數已撤除，留著會讓「文案只用已登記變數」的測試失敗；
        // 這裡只留可辨識的敘述（停用的備註不會被帶出、不會印出）。
        .init(deprecated: true, uniqueCode: "22", traits: ["ServiceItem/AccountingReform"], weight: 83, content: """
        貴公司應提供整帳期間相關帳冊及報表(含科目餘額明細表)之電子檔(excel)，本事務所將依 貴公司提供之整帳期末報表金額作為開帳數。（2026-10-19 取消）
        """),

        // 1150917 母版拿掉了出納這條備註。標 deprecated：不再被帶出，既有報價單同步時清掉；內容保留。
        .init(deprecated: true, uniqueCode: "10", traits: [
            .init(tags: [
                "ServiceItem/CashierOperation",
            ]),
        ], weight: 40, content: """
        出納事務整理作業內容包含：
        A.國內轉帳30 筆；每加⼀筆多50 元。
        B.國外轉帳10 筆；每加⼀筆多100 元。
        C.⼀次薪資轉帳。
        *如出納事務整理作業有重複處理，將額外收取處理費用2,000元/次。
        公費費用\(TemplateVariableConcept.cashierPeriod.placeholder())，並\(TemplateVariableConcept.cashierBilling.placeholder())
        """),

        // 1150917 母版拿掉了薪資這條備註。標 deprecated：不再被帶出，既有報價單同步時清掉；內容保留。
        .init(deprecated: true, uniqueCode: "11", traits: [
            .init(tags: [
                "ServiceItem/PayrollSupportOperation",
            ]),
        ], weight: 35, content: """
        薪資人力支援處理作業500元/人/月；基本收費3,000/月。
        公費費用\(TemplateVariableConcept.payrollSupportPeriod.placeholder())，並\(TemplateVariableConcept.payrollSupportBilling.placeholder())
        """),
    ]
}
