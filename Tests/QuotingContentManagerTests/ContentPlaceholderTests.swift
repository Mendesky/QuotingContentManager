import Testing
@testable import QuotingContentManager

/// `{…}` 佔位符的守衛：每個 token 都已登記，而且只出現在會被 QCM 替換的欄位。
///
/// 寫錯位置的 `{…}` 沒有任何人會替換它——例如在備註裡寫 `{price}`，報價單上就會原樣印出大括號。
/// 語法總覽見 `ContentPlaceholder` 的說明。
@Suite("ContentPlaceholder — {…} 只出現在會被替換的欄位")
struct ContentPlaceholderTests {

    @Test("每個 {…} 都是已登記的 token，且只出現在允許的欄位")
    func tokensAppearOnlyWhereTheyAreSubstituted() {
        var checked = 0
        for entry in QCMTextCatalog.all() {
            for match in entry.text.matches(of: #/\{[A-Za-z]+\}/#) {
                checked += 1
                let token = String(entry.text[match.range])
                guard let placeholder = ContentPlaceholder(rawValue: token) else {
                    Issue.record("未登記的佔位符 \(token)（於 \(entry.location)）——請在 ContentPlaceholder 加 case，或改用 %…% 範本變數")
                    continue
                }
                let allowed = entry.field.map { placeholder.allowedFields.contains($0) } ?? false
                #expect(allowed, "\(token) 不該出現在 \(entry.location)：那裡不會被替換")
            }
        }
        #expect(checked > 0, "fixture 前提：目錄裡有 {…}")
    }

    /// 沒人用的 token 留在 enum 裡，會讓人以為某處還在替換它。
    @Test("每個已登記的 token 至少被用到一次")
    func everyPlaceholderIsUsed() {
        let allText = QCMTextCatalog.all().map(\.text).joined(separator: "\n")
        for placeholder in ContentPlaceholder.allCases {
            #expect(allText.contains(placeholder.rawValue), "\(placeholder.rawValue) 沒有任何文案在用")
        }
    }
}
