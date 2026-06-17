import Foundation

public struct AdditionalServiceNameFormat: Codable, Sendable, Equatable {
    public let template: String
    public let requiresCount: Bool

    public init(template: String, requiresCount: Bool) {
        self.template = template
        self.requiresCount = requiresCount
    }

    /// 把 template 內的 `{price}` / `{count}` placeholder 換成實際值，算出內嵌金額的附加服務名稱。
    /// `count` 為 nil 時 `{count}` 換空字串（`requiresCount == false` 的 template 本就不含 `{count}`）。
    public func render(price: Decimal, count: Int?) -> String {
        template
            .replacingOccurrences(of: "{price}", with: Self.formatPrice(price))
            .replacingOccurrences(of: "{count}", with: count.map(String.init) ?? "")
    }

    private static func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }
}
