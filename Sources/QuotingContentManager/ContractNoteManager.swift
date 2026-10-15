//
//  ContractNoteManager.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

/// 合約注意事項的目錄。OC 依服務項目的 trait 從這裡挑出該印的備註，寫進報價單。
///
/// ## 備註退場：刪除與 deprecated 的效果不同
///
/// 報價單上的備註是**文字快照**（Quotation 的 `ContractNoteAddedByTraits.note`），讀取時不回頭查這張表，
/// 所以兩種做法都不會讓既有報價單讀取出錯。差別只在既有報價單之後**被重新同步**的時候
/// （有人在該案件加、刪、隱藏服務項目，觸發 OC 的 `ContractNoteSynchronizer`）：
///
/// - **標 `deprecated: true`**：不再被帶到任何報價單；**既有報價單上的這條，同步時會被清掉**。
///   用在「內容被別條取代，或母版拿掉了，既有的也該跟著拿掉」。同步程式靠這筆定義認出它，所以不能刪。
/// - **從陣列刪除**：同步程式不再認得這個 code，**既有報價單上的這條會一直留著**（只能使用者手動刪）。
///   用在「新報價單不再出現，但已經印出去的保留原樣」。刪除時把 code 加進 `retiredUniqueCodes`。
///
/// 已成交的報價單兩種做法都不受影響：Quoting 成交後鎖定，不會再觸發同步。但**取消成交會解鎖**，
/// 之後一同步就照這張表處理——留著 deprecated 的定義，解鎖的舊報價單才會被清乾淨；刪掉的話舊備註
/// 會跟取代它的新備註並存。所以退場預設用 deprecated，定義留著的代價只是目錄多幾筆。
///
/// ## uniqueCode 不可重用
///
/// 既有報價單上的 code 會被同步程式依這張表解讀。重用一個退場的 code，舊報價單上的舊備註就會被當成
/// 新備註處理（內文被改寫，或被當成不適用而清掉）。`retiredUniqueCodes` 列出刪除過的 code，
/// 測試擋住它們再次出現。（16 在 2026-09-15 前是專案整帳的電子檔備註，1150828 改版重用成註一——
/// 發生在正式上線前，只影響開發資料；之後不要再這樣做。）
///
/// ## 檔案編排
///
/// 現行備註在 `currentNotes`，**依報價單上的順序（weight 由高到低）排列**，打開就能對照母版；
/// 停用的在 `ContractNoteManager+Deprecated.swift` 的 `deprecatedNotes`。陣列順序不影響任何行為——
/// 查詢一律依 weight 排序（`QuotingContentManager.fetchNotes`）、依 uniqueCode 查（`getNote`），
/// OC 同步也是依 weight 決定插入位置。
public struct ContractNoteManager: Sendable {
    /// 從目錄刪除過的 uniqueCode，不可再拿來用（理由見型別說明）。
    ///
    /// 只列「刪除」的；deprecated 的仍留在 `notes` 裡，本來就佔著 code。
    public static let retiredUniqueCodes: Set<String> = []

    /// 全部定義：現行的＋停用的。OC 同步要靠停用的定義認出既有報價單上的舊備註，所以兩者都要在這裡。
    public var notes: [ContractNoteInfo] = ContractNoteManager.currentNotes + ContractNoteManager.deprecatedNotes

    public init() {}

    /// 現行備註，依報價單上的順序（weight 由高到低）排列。
    static let currentNotes: [ContractNoteInfo] = [
        // ── 註一：巨額變動與後續服務費用 ────────────────────────────────
        // 財簽／稅簽／記帳三家的報價基準（「…依預估…報價」）只住在**酬金補充說明**
        // （`PaymentItemManager`），不複製進合約注意事項。
        //
        // 第一句的**主詞隨選到的服務裁剪**（2026-10-02 業務裁定）：每個服務各自貢獻一段主詞，
        // 依序以「、」相接——財簽 → 資產總額／稅簽 → 營業收入總額／記帳 → 營業收入總額及憑證量。
        //
        // 記帳那段**已經含「營業收入總額」**，所以稅簽那段在同時有記帳時要讓位（`excluded`），
        // 否則會印成「營業收入總額、營業收入總額及憑證量」。這是去重，不是互斥 ——
        // 兩個服務講的是同一個指標，只是記帳多管一個憑證量。
        //
        // 七種組合各自的結果**以測試為準**：`CompositeContractNoteTests.noteOneFollowsSelectedServices`
        // （QuotationMasterTests.swift）。改這裡的段落或條件時先改那張表，不在註解另抄一份。
        //
        // 主詞一段都沒命中是不可能的：整條備註的 trait 就是這三個的 ANY-of，命中才會出現這條
        // （所以純工商登記的案子連這條都沒有）。
        //
        // 第二句（後續無簽證服務時另行收費）**只在有稅簽時印**（2026-10-13 裁定；原本 2026-09 裁定為不綁稅簽、一律印）。
        //
        // weight 2026-10-15 從 80 改 84：整帳（22）、薪資（23）、出納（24、25）四條要排在這條與註二（21，78）之間。
        // 這條本來就排第一，往上調不改變任何既有的相對順序。
        .init(uniqueCode: "16", traits: [
            "ServiceItem/FinancialComplianceAudit",
            "ServiceItem/TaxComplianceAudit",
            "ServiceItem/Accounting",
        ], weight: 84, segments: [
            .init("資產總額", traits: ["ServiceItem/FinancialComplianceAudit"]),
            .init(
                "營業收入總額",
                separator: "、",
                traits: [.init(tags: ["ServiceItem/TaxComplianceAudit"], excluded: ["ServiceItem/Accounting"])]
            ),
            .init("營業收入總額及憑證量", separator: "、", traits: ["ServiceItem/Accounting"]),
            .init("若有巨額變動或變更申報方式，將另與 貴公司討論報價金額。"),
            .init(
                "又 貴公司若後續無營利事業所得稅查核簽證及未分配盈餘查核簽證服務，本事務所就已提供服務範圍，將另行收取費用。",
                separator: "\n",
                traits: ["ServiceItem/TaxComplianceAudit"]
            ),
        ]),

        // ── 整帳、薪資、出納（註一之後、付款條件之前；2026-10-15 業務裁定）──────────
        // 順序：註一（16）→ 整帳 22 → 薪資 23 → 出納 24、25 → 付款條件（21）。各自只在選到該服務時出現，
        // 號碼依實際印出的條數往前遞補（例如沒有整帳時，薪資就是註二）。
        //
        // 編號從 22 起：1～20 是舊系統（QuotingContext）搬來的備註也在用的編號，同號不同義，
        // 撤回成交解鎖後同步會把它們當成同一條（見 21 上方說明），所以新備註一律避開。

        // 整帳：期初帳冊電子檔與開帳。只要有整帳（記帳卡下的整理費）就印，不論整帳卡有沒有勾「提供電子檔」；
        // 專案整帳（整理費(專案)）不印。整帳一定掛在記帳卡下、註一必在，所以有整帳時就是註二。
        // 整帳的酬金名稱會指回這條（`ServiceItem.accountingReform` 的 `paymentItemNameFormat.noteReference`）。
        //
        // 日期全部取自整帳區間：期間（`|plain`／`|short`）、期間最後一天、期間的下一個月（開帳月）。
        // 取代 9 —— 9 是同一件事（提供電子檔）的舊寫法，且只在勾了提供電子檔時才出現。
        .init(uniqueCode: "22", traits: ["ServiceItem/AccountingReform"], weight: 83, content: """
        貴公司應提供\(TemplateVariableConcept.reformPeriod.placeholder(variant: "plain"))相關帳冊及報表(含科目餘額明細表)之電子檔(excel)，本事務所將依 貴公司提供之\(TemplateVariableConcept.reformEndDate.placeholder())報表金額作為\(TemplateVariableConcept.reformOpeningMonth.placeholder())開帳數，且免對於\(TemplateVariableConcept.reformPeriod.placeholder(variant: "short"))帳務做整理覆核，若後續因報表核實表達因素，導致需大量調整，將另與 貴公司討論報價金額。
        """),

        // 薪資：人數級距加價。1150917 母版拿掉的舊薪資備註是 11（已 deprecated，內容不同）。
        .init(uniqueCode: "23", traits: ["ServiceItem/PayrollSupportOperation"], weight: 82, content: """
        薪資人力支援作業基本以每月5人內計算，超過人數(第6位起)每位加價1,000元。
        """),

        // 出納：兩條都在選到出納時印。用字統一成「整理」（服務名稱是「出納事務整理作業」，1150917 從「處理」改來）。
        // 25 的內容與 1150917 母版拿掉的 10（deprecated）幾乎相同，但不重新啟用 10，理由同上（舊系統的 10 是職業道德）。
        .init(uniqueCode: "24", traits: ["ServiceItem/CashierOperation"], weight: 81, content: """
        出納事務整理作業內容包含：
        A.每月一次薪資轉帳。
        B.每月一次廠商批次付款。
        C.每週一次臨時付款。
        """),
        .init(uniqueCode: "25", traits: ["ServiceItem/CashierOperation"], weight: 80, content: """
        出納事務整理作業內容包含：
        A.國內轉帳30 筆；每加一筆多50 元。
        B.國外轉帳10 筆；每加一筆多100 元。
        C.一次薪資轉帳。
        *如出納事務整理作業有重複處理，將額外收取處理費用2,000元/次。
        """),

        // ── 付款條件（1150828 母版的「註二」；前面有整帳／薪資／出納時號碼往後退）────────
        // 同樣是母版併成一條。簽證那句財簽與稅簽各有一份且字一樣，兩個都選時只印一次（去重）——
        // 寫成單一段落、trait 列兩個 tag（ANY-of）即可，不必在呼叫端做字串比對去重。
        //
        // 代墊費用那段**無條件**，但註二整條只在有財簽／稅簽／記帳任一時才出現，
        // 所以純工商登記的案子連註二都沒有，不會印到它。
        //
        // 編號 21：17／18 已是行號（獨資合夥）的工商登記備註；19／20 跳過——舊系統（QuotingContext）搬來的
        // 備註帶的是舊系統的編號，19／20 在已成交的報價單上仍在用，撤回成交解鎖後同步會把它們當成同號的這條。
        .init(uniqueCode: "21", traits: [
            "ServiceItem/FinancialComplianceAudit",
            "ServiceItem/TaxComplianceAudit",
            "ServiceItem/Accounting",
        ], weight: 78, segments: [
            .init("簽證公費請於當年度12月31日前支付半數，另外半數請於次年度5月31日前支付",
                  traits: ["ServiceItem/FinancialComplianceAudit", "ServiceItem/TaxComplianceAudit"]),
            .init("\(TemplateVariableConcept.accountingWorkName.placeholder())作業費用\(TemplateVariableConcept.accountingPeriod.placeholder())，並\(TemplateVariableConcept.accountingBilling.placeholder())，並應支付至本事務所指定之銀行帳戶",
                  separator: "；", traits: ["ServiceItem/Accounting"]),
            .init("承辦委任事項所發生之代墊費用，包括機票、簽證、住宿等，另行檢具相關憑證向 貴公司請款",
                  separator: "。\n"),
        ], terminator: "。"),

        // ── 工商登記 ────────────────────────────────────────────────────
        .init(uniqueCode: "15", traits: [
            .init(tags: ["ServiceItem/CompanyRegistration"], excluded: [OrganizationType.soleProprietorshipOrPartnership.contractNoteTag]),
        ], weight: 67, content: """
        工商登記處理作業：\(TemplateVariableConcept.organizationTypeName.placeholder())、\(TemplateVariableConcept.capital.placeholder(variant: "exact"))、\(TemplateVariableConcept.companyRegistrationRegion.placeholder())、\(TemplateVariableConcept.companyRegistrationShareholder.placeholder())。
        """),
        // 3 / 15 是公司版（含其他非行號型態）；行號版為 18 / 17，以組織型態 tag 分流 —— 見 18 上方說明。
        .init(uniqueCode: "3", traits: [
            .init(tags: ["ServiceItem/CompanyRegistration"], excluded: [OrganizationType.soleProprietorshipOrPartnership.contractNoteTag]),
        ], weight: 66, content: """
        工商登記費用不包含政府規費、投審司（外國人）、動資查核、工廠及特許項目之登記及代墊之什項費用(依其收據請款)，服務公費及代墊費用請於辦理完成時支付。
        如股東超過5人，第6位起每位加收新台幣500元之防制洗錢查核費。
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

        // ── 稅簽說明（12／13 互斥：有沒有同時選財簽）──────────────────────────
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

        // ── 附加服務 ────────────────────────────────────────────────────
        // 前綴「附加服務選項：」**不帶序號**（1150917 母版定案）。曾經實作過依最終清單現算的序號
        // （附加服務選項1／2），母版最終版拿掉了編號，整套機制隨之移除 —— 要撿回來見 commit 64cc61c。
        .init(uniqueCode: "1", traits: ["ServiceItem/Ctp"], weight: 30, content: """
        附加服務選項：代辦年度CTP申報(每年3月)，依據公司法第22條之1是為了配合洗錢防制政策，協助建置完善洗錢防制體制，強化洗錢防制作為，以增加法人(公司)之透明度，並有效掌握公司負責人(董事、監察及經理人)及主要股東(持有超過10%股份或出資額股東)之持股或出資額。
        """),
        .init(uniqueCode: "7", traits: [
            "ServiceItem/AssistanceAnnualSupplementaryPremiumDeductionDetailsReporting",
        ], weight: 25, content: """
        附加服務選項：依全民健康保險扣取及繳納補充保費辦法第10條規定，扣繳義務人申報扣費明細時點，採年度申報應於每年1/31前將上一年度向保險對象扣取之補充保費金額，填報扣費明細彙報健保署。
        """),

        // ── 記帳：非稅簽申報的查核 ──────────────────────────────────────────
        .init(uniqueCode: "14", traits: ["ServiceItem/Accounting"], weight: 5, content: """
        採非稅務簽證申報之案件當年度若需協助國稅局營所稅查核，將另與 貴公司討論服務費報價金額。
        """),

        // ── 一般（不由服務項目帶出，`WhenQuotationCreated` 加）─────────────────────
        .init(uniqueCode: "2", traits: ["general", "Tip/benefit"], weight: 0, content: """
        最新稅務訊息通知，本事務所另將不定期以電子郵件寄送最新稅務法令之變更、稅捐獎勵減免等有關訊息供 貴公司參考，亦可免費參加本所舉辦之教育訓練課程(除特定專案外)，以使 貴公司與本事務所共同成長。
        """),
    ]
}
