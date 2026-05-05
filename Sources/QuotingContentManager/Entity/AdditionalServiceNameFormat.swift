public struct AdditionalServiceNameFormat: Codable, Sendable, Equatable {
    public let template: String
    public let requiresCount: Bool

    public init(template: String, requiresCount: Bool) {
        self.template = template
        self.requiresCount = requiresCount
    }
}
