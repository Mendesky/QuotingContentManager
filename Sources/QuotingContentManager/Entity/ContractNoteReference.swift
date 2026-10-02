/// 指向某條合約注意事項的引用，例如同意函勾選項末尾的「(註四)」、
/// 服務範圍「二代健保申報作業。(註五)」。
///
/// **標點與被引用的對象都留在 QCM**：各處的寫法不同（CTP 在括號外另開括號、補充保費在括號內用
/// 分號、服務範圍直接接在句號後），那是文案決定；「這裡引用的是哪一條註」同樣是文案決定。
/// 兩者散到呼叫端，就會變成讀取端硬寫一張對照表，改文案時沒人記得去同步。
///
/// **號碼不在這裡**：註號是該條備註在那份報價單最終清單中的序位，取決於實際印出哪幾條備註
/// （隱藏服務 → 少一條；使用者拖曳 → 換順序）。由讀取端算出來後以 `render(noteNumber:)` 填入。
public struct ContractNoteReference: Codable, Sendable, Equatable {
    /// 被引用的備註在 `ContractNoteManager` 的 `uniqueCode`。
    public let contractNoteUniqueCode: String

    /// 引用的寫法；`{noteNo}` 由呼叫端換成實際註號（中文數字）。
    public let template: String

    public init(contractNoteUniqueCode: String, template: String) {
        self.contractNoteUniqueCode = contractNoteUniqueCode
        self.template = template
    }

    public func render(noteNumber: String) -> String {
        template.replacingOccurrences(of: "{noteNo}", with: noteNumber)
    }

    /// 把 `text` 裡的 `{noteRef}` 換成引用；`noteNumber` 為 nil（算不出註號）時換成空字串。
    ///
    /// 算不出註號的情形是真實存在的：被引用的備註要有對應服務才會出現（例如沒加購補充保費時
    /// 那條就不在清單上）。此時**整段引用消失**，而不是印出「(註)」這種殘缺的東西 ——
    /// 所以每個帶 `{noteRef}` 的文案都要讓「沒有引用」的版本自己讀得通。
    public static func substitute(in text: String, reference: ContractNoteReference?, noteNumber: String?) -> String {
        let rendered = noteNumber.flatMap { reference?.render(noteNumber: $0) } ?? ""
        return text.replacingOccurrences(of: "{noteRef}", with: rendered)
    }
}
