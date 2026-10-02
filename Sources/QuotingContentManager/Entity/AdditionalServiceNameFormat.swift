import Foundation

public struct AdditionalServiceNameFormat: Codable, Sendable, Equatable {
    public let template: String
    public let requiresCount: Bool

    /// 同意函勾選項末尾指向合約注意事項的引用（母版：CTP 寫「)(註四)」、補充保費寫「；註五)」）。
    ///
    /// nil 代表這個附加服務不引用任何備註。
    public let noteReference: ContractNoteReference?

    public init(template: String, requiresCount: Bool, noteReference: ContractNoteReference? = nil) {
        self.template = template
        self.requiresCount = requiresCount
        self.noteReference = noteReference
    }

    /// 把 template 內的 `{price}` / `{count}` / `{noteRef}` placeholder 換成實際值。
    ///
    /// - `count` 為 nil 時 `{count}` 換空字串（`requiresCount == false` 的 template 本就不含 `{count}`）。
    /// - `noteNumber` 為 nil（或本 format 沒宣告 `noteReference`）時 `{noteRef}` 換成空字串 ——
    ///   註號取決於該份報價單實際印出哪些備註，算不出來時寧可不印引用，也不要印出「(註)」這種殘缺的東西。
    ///   因此 template 要讓「沒有引用」的版本自己讀得通（例如補充保費的 `)` 留在 template 裡）。
    public func render(price: Decimal, count: Int?, noteNumber: String? = nil) -> String {
        let withValues = template
            .replacingOccurrences(of: "{price}", with: Self.formatPrice(price))
            .replacingOccurrences(of: "{count}", with: count.map(String.init) ?? "")
        return ContractNoteReference.substitute(in: withValues, reference: noteReference, noteNumber: noteNumber)
    }

    /// 阿拉伯數字 ＋ 中文單位（1150828 母版用字：「加收2仟元/家」，不是「貳仟」也不是「2,000」）。
    ///
    /// 百位以上逐級拆出單位、餘數接在後面；不足百的部分與非整數金額維持原本的千分位寫法。
    /// 2000 →「2仟」、20000 →「2萬」、1200 →「1仟2佰」、2500 →「2仟5佰」、
    /// 25000 →「2萬5仟」、800 →「8佰」、150 →「1佰50」、80 →「80」。
    private static func formatPrice(_ price: Decimal) -> String {
        guard let amount = integerAmount(price), amount >= 100 else {
            return decimalString(price)
        }
        var remainder = amount
        var text = ""
        for (unit, label) in [(10000, "萬"), (1000, "仟"), (100, "佰")] {
            let quotient = remainder / unit
            guard quotient > 0 else { continue }
            text += "\(quotient)\(label)"
            remainder -= quotient * unit
        }
        if remainder > 0 {
            text += "\(remainder)"
        }
        return text
    }

    /// 非負整數金額才走中文單位；小數或負值回 nil，由 caller 退回千分位寫法。
    private static func integerAmount(_ price: Decimal) -> Int? {
        guard price >= 0 else { return nil }
        var value = price
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 0, .plain)
        guard rounded == price else { return nil }
        return NSDecimalNumber(decimal: rounded).intValue
    }

    private static func decimalString(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }
}
