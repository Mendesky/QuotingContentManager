extension QuotingContentManager {
    public func accountingCategory(forAccountingType rawValue: String) -> String {
        switch rawValue {
        case "taxAccount":
            return "稅務帳務"
        default:
            return "會計帳務"
        }
    }
}
