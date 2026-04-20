public struct WorkItem: Codable, Sendable, Equatable {
    public let type: String
    public let name: String
    public var tags: [String]

    public init(type: String, name: String, tags: [String] = []) {
        self.type = type
        self.name = name
        self.tags = tags
    }
}
