import Testing
import Foundation
@testable import QuotingContentManager

/// `TemplateVariableConcept` 是報價文本 placeholder 的**單一真值**（名稱 + scope）。
/// 這些測試守住「模板只用已登記的 concept」，避免未來有人手打 raw `%NewThing%` 造成 drift。
@Suite("TemplateVariableConcept — 詞彙契約")
struct TemplateVariableConceptTests {

    private static let knownConcepts = Set(TemplateVariableConcept.allCases.map(\.rawValue))

    private func assertPlaceholders(in text: String, where location: String) {
        // 抓 `%Concept%` 或 `%Concept|variant%`，capture concept（|variant 前）。local regex 避免 static 非 Sendable。
        let regex = try! Regex("%([A-Za-z][A-Za-z0-9]*)(?:\\|[a-z]+)?%")
        for match in text.matches(of: regex) {
            let concept = String(match.output[1].substring ?? "")
            #expect(
                Self.knownConcepts.contains(concept),
                "未登記的 template concept %\(concept)%（於 \(location)）— 請在 TemplateVariableConcept 加對應 case，勿手打 raw 字串"
            )
        }
    }

    /// 合約備註（長 prose）內的每個 placeholder concept 都必須是已登記的 concept。
    @Test("合約備註內的 placeholder 皆為已登記 concept")
    func contractNotePlaceholdersAreKnownConcepts() {
        for note in QuotingContentManager.standard.contractNoteManager.notes {
            assertPlaceholders(in: note.content, where: "contractNote uniqueCode=\(note.uniqueCode)")
        }
    }

    /// scope 為總函式（allCases 皆有分層）——由 exhaustive switch 編譯保證；此測試防呆並鎖語意。
    @Test("每個 concept 都有 scope（分層完整）")
    func everyConceptHasScope() {
        for concept in TemplateVariableConcept.allCases {
            _ = concept.scope // 不 crash 即通過；scope 為 exhaustive switch，無 default
        }
        #expect(TemplateVariableConcept.allCases.count == Set(TemplateVariableConcept.allCases.map(\.rawValue)).count)
    }

    /// 暫繳簽證年度 concept：bundle 級、值含「年度」語意單位（見 design spec 決策 2）。
    @Test("provisionalIncomeTaxAuditStartYear 已登記且為 bundle 級")
    func provisionalIncomeTaxAuditStartYearIsRegisteredBundleConcept() {
        #expect(TemplateVariableConcept.provisionalIncomeTaxAuditStartYear.rawValue == "ProvisionalIncomeTaxAuditStartYear")
        #expect(TemplateVariableConcept.provisionalIncomeTaxAuditStartYear.scope == .bundle)
        #expect(TemplateVariableConcept.provisionalIncomeTaxAuditStartYear.placeholder() == "%ProvisionalIncomeTaxAuditStartYear%")
    }
}
