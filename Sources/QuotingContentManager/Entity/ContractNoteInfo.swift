//
//  ContractNoteInfo.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

public extension ContractNoteManager {
    struct ContractNoteInfo: Sendable {
        public let uniqueCode: String
        public let content: String
        public let traits: [Trait]
        public let mutex: Mutex?
        public let weight: Int

        init(uniqueCode: String, mutex: Mutex? = nil, traits: [Trait], weight: Int, content: String) {
            self.uniqueCode = uniqueCode
            self.content = content
            self.traits = traits
            self.mutex = mutex
            self.weight = weight
        }

        package func isSubsetOf(tags: [String]) -> Bool {
            traits.contains {
                let result = $0.tags.isSubset(of: tags) && ($0.excluded.isEmpty || !$0.excluded.isSubset(of: tags))
                return result
            }
        }
    }
}

public extension ContractNoteManager.ContractNoteInfo {
    enum Mutex: Sendable {
        case codes([String])
        case tags([String])
    }

    struct Trait: Sendable {
        public var tags: Set<String>
        public var excluded: Set<String>

        public init(tags: Set<String>, excluded: Set<String>) {
            self.tags = tags
            self.excluded = excluded
        }

        public init(tags: [String], excluded: [String] = []) {
            self.tags = .init(tags)
            self.excluded = .init(excluded)
        }
    }
}

extension ContractNoteManager.ContractNoteInfo.Trait: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public init(stringLiteral value: String) {
        self.init(tags: [value], excluded: [])
    }
}

extension ContractNoteManager.ContractNoteInfo.Trait: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = String

    public init(arrayLiteral elements: String...) {
        self.init(tags: elements, excluded: [])
    }
}

extension ContractNoteManager.ContractNoteInfo.Trait: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.tags == rhs.tags
    }
}

extension ContractNoteManager.ContractNoteInfo.Trait: SetAlgebra {
    public typealias Element = String

    public init() {
        self.init(tags: [], excluded: [])
    }

    public func contains(_ member: String) -> Bool {
        tags.contains(member)
    }

    public mutating func insert(_ newMember: __owned String) -> (inserted: Bool, memberAfterInsert: String) {
        tags.insert(newMember)
    }

    public mutating func remove(_ member: String) -> String? {
        tags.remove(member)
    }

    public mutating func update(with newMember: __owned String) -> String? {
        tags.update(with: newMember)
    }

    public func union(_ other: __owned ContractNoteManager.ContractNoteInfo.Trait) -> ContractNoteManager.ContractNoteInfo.Trait {
        .init(tags: tags.union(other.tags), excluded: excluded.union(other.excluded))
    }

    public func intersection(_ other: ContractNoteManager.ContractNoteInfo.Trait) -> ContractNoteManager.ContractNoteInfo.Trait {
        .init(tags: tags.intersection(other.tags), excluded: excluded.intersection(other.excluded))
    }

    public func symmetricDifference(_ other: __owned ContractNoteManager.ContractNoteInfo.Trait) -> ContractNoteManager.ContractNoteInfo.Trait {
        .init(tags: tags.symmetricDifference(other.tags), excluded: excluded.symmetricDifference(other.excluded))
    }

    public mutating func formUnion(_ other: __owned ContractNoteManager.ContractNoteInfo.Trait) {
        tags.formUnion(other.tags)
    }

    public mutating func formIntersection(_ other: ContractNoteManager.ContractNoteInfo.Trait) {
        tags.formIntersection(other.tags)
    }

    public mutating func formSymmetricDifference(_ other: __owned ContractNoteManager.ContractNoteInfo.Trait) {
        tags.formSymmetricDifference(other.tags)
    }
}
