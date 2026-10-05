//
//  ContentPlaceholder.swift
//  QuotingContentManager
//

/// QCM 自己替換的佔位符（`{…}`）。
///
/// ## 文案裡的三套佔位符
///
/// 依「誰負責替換」區分，看到一個佔位符先問這句：
///
/// | 語法 | 誰替換 | 何時 | 例 |
/// |---|---|---|---|
/// | `%Key%`、`%Key\|variant%` | 下游（OC 的範本變數 API、mendesky-web 的 chip） | 讀取／顯示時 | `%AccountingStart%` |
/// | `{name}`、`{price}`、`{count}`、`{noteRef}` | QCM，組字串的那支函式 | 呼叫 render 時 | `加收{price}元` |
/// | `{noteNo}` | QCM，第二段 | `{noteRef}` 展開成引用的當下 | `(註{noteNo})` |
///
/// - `%…%` 的鍵與語意由 `TemplateVariableConcept` 管；前端也依這個格式解析，**不能**改成 `{…}`。
/// - `{…}` 只在 QCM 內部流通，出了 QCM 一定已經被換掉。每個 token 能出現在哪種欄位，
///   由 `allowedFields` 規定、測試掃過整份目錄驗證——寫錯位置（例如在備註裡寫 `{price}`）
///   不會有任何人替換它，報價單上就會印出大括號。
/// - `{noteRef}` 要分兩段，是因為**號碼**由讀取端算（取決於最終印出哪些備註），**寫法**由 QCM 定
///   （見 `ContractNoteReference`）。
public enum ContentPlaceholder: String, CaseIterable, Sendable {
    /// 服務項目的顯示名稱。由 `PaymentItemNameFormat.resolve(name:for:)` 替換。
    case name = "{name}"
    /// 附加服務的金額（中文單位）。由 `AdditionalServiceNameFormat.render` 替換。
    case price = "{price}"
    /// 附加服務的數量。由 `AdditionalServiceNameFormat.render` 替換。
    case count = "{count}"
    /// 指向合約注意事項的引用整段；算不出註號時換成空字串。由 `ContractNoteReference.substitute` 替換。
    case noteRef = "{noteRef}"
    /// 引用裡的註號（中文數字）。由 `ContractNoteReference.render(noteNumber:)` 替換。
    case noteNo = "{noteNo}"

    /// 可以出現這個 token 的欄位種類。其餘欄位一律不得出現任何 `{…}`。
    public var allowedFields: Set<Field> {
        switch self {
        case .name: [.paymentItemNameTemplate]
        case .price, .count: [.additionalServiceNameTemplate]
        case .noteRef: [.additionalServiceNameTemplate, .workItemContent]
        case .noteNo: [.noteReferenceTemplate]
        }
    }

    /// 會被 QCM render 函式處理的欄位種類。
    public enum Field: Sendable, CaseIterable {
        /// `PaymentItemNameFormat.template`
        case paymentItemNameTemplate
        /// `AdditionalServiceNameFormat.template`
        case additionalServiceNameTemplate
        /// `WorkItem.content` / `taxAccountContent`
        case workItemContent
        /// `ContractNoteReference.template`
        case noteReferenceTemplate
    }
}
