@testable import QuotingContentManager

/// QCM 目錄裡一段會被印出來的文案。
struct CatalogText {
    /// 人看得懂的位置，測試失敗時直接指到是哪一段。
    let location: String
    /// 這段文案會經過哪支 QCM render 函式；nil 代表一般文案（不經 QCM 替換，不得含 `{…}`）。
    let field: ContentPlaceholder.Field?
    let text: String
}

/// 測試用：把 QCM 目錄攤平成「每一段文案」的清單，給掃描整份目錄的守衛測試共用
/// （佔位符、範本變數）。
///
/// 新增會被印出來的欄位時，記得加進這裡——沒加的欄位，守衛測試掃不到。
enum QCMTextCatalog {

    static func all(_ qcm: QuotingContentManager = .standard) -> [CatalogText] {
        var texts: [CatalogText] = []
        func add(_ location: String, _ text: String?, _ field: ContentPlaceholder.Field? = nil) {
            guard let text else { return }
            texts.append(.init(location: location, field: field, text: text))
        }

        for item in qcm.serviceItems {
            let at = "serviceItem \(item.type)"
            add("\(at).name", item.name)
            add("\(at).taxAccountName", item.taxAccountName)
            add("\(at).alias", item.alias)
            add("\(at).term", item.term)
            add("\(at).taxAccountTerm", item.taxAccountTerm)
            for term in item.scopeTerms {
                add("\(at).scopeTerms[\(term.name)].name", term.name)
                add("\(at).scopeTerms[\(term.name)].content", term.content)
            }
            add("\(at).paymentItemNameFormat", item.paymentItemNameFormat?.template, .paymentItemNameTemplate)
            if case let .embedsPrice(format) = item.additionalServiceNameStrategy {
                add("\(at).additionalServiceNameFormat", format.template, .additionalServiceNameTemplate)
                add("\(at).additionalServiceNameFormat.noteReference", format.noteReference?.template, .noteReferenceTemplate)
            }
            for workItem in item.workItems {
                let wat = "\(at).workItem \(workItem.type)"
                add("\(wat).content", workItem.content, .workItemContent)
                add("\(wat).taxAccountContent", workItem.taxAccountContent, .workItemContent)
                add("\(wat).description", workItem.description)
                for (index, subItem) in workItem.subItems.enumerated() {
                    add("\(wat).subItems[\(index)]", subItem)
                }
                add("\(wat).noteReference", workItem.noteReference?.template, .noteReferenceTemplate)
            }
        }

        for note in qcm.contractNoteManager.notes {
            for (index, segment) in note.segments.enumerated() {
                add("contractNote \(note.uniqueCode).segments[\(index)]", segment.text)
            }
        }

        for item in qcm.businessClientAssistanceManager.items {
            let at = "businessClientAssistance \(item.uniqueCode)"
            add("\(at).name", item.name)
            add("\(at).content", item.content)
            add("\(at).taxAccountContent", item.taxAccountContent)
        }

        for item in qcm.paymentItemManager.items {
            add("paymentItem \(item.uniqueCode).content", item.content)
        }

        let copywritings: [(String, Copywriting)] = [
            ("contractHeader", qcm.contractHeader),
            ("letter", qcm.letter),
            ("purpose", qcm.purpose),
            ("serviceScope", qcm.serviceScope),
        ]
        for (name, copywriting) in copywritings {
            add("\(name).title", copywriting.title)
            add("\(name).content", copywriting.content)
            add("\(name).taxAccountContent", copywriting.taxAccountContent)
        }

        let sections: [(String, ProvisionsSection)] = [
            ("rightsAndObligations", qcm.rightsAndObligations),
            ("agreementTerms", qcm.agreementTerms),
        ]
        for (name, section) in sections {
            add("\(name).title", section.title)
            for (index, provision) in section.provisions.enumerated() {
                add("\(name).provisions[\(index)].content", provision.content)
                add("\(name).provisions[\(index)].taxAccountContent", provision.taxAccountContent)
            }
        }

        add("paymentTitle", qcm.paymentTitle)
        return texts
    }
}
