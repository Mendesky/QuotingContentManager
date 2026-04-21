public struct WorkItem: Codable, Sendable, Equatable {
    public let type: String
    public let content: String
    public let taxAccountContent: String?
    public let description: String?
    public let subItems: [String]?

    public init(
        type: String,
        content: String,
        taxAccountContent: String? = nil,
        description: String? = nil,
        subItems: [String]? = nil
    ) {
        self.type = type
        self.content = content
        self.taxAccountContent = taxAccountContent
        self.description = description
        self.subItems = subItems
    }

    public func displayContent(forTaxAccount isTaxAccount: Bool) -> String {
        isTaxAccount ? (taxAccountContent ?? content) : content
    }
}
