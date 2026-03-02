// The Swift Programming Language
// https://docs.swift.org/swift-book

public struct QuotingContentManager: Sendable {
    public static let standard: Self = .init()

    public var serviceItems: [ServiceItem] = [
        .accounting,
        .accountingReform,
        .financialComplianceAudit,
        .taxComplianceAudit,
        .cashierOperation,
        .payrollSupportOperation,
        .settlementReview,
        .customized,
        .companyRegistration,
        .ctp,
        .assistanceAnnualSupplementaryPremiumDeductionDetailsReporting,
        .assistanceRegistrationByJWServiceItem,
        .assistanceWithCompanyCertificatationApplication,
        .assistanceWithCompanyCorporateSeal,
        .assistanceWithChairmanCorporateSeal,
        .assistanceWithCompanyStamps,
        .assistanceWithCompanyConvenienceStamps,
        .assistanceWithInvoiceStamp,
        .assistanceWithLaborAndHealthInsuranceInsuredUnitSetting,
        .ownerOccupiedResidencePartForBusinessApplication,
    ]

    public var contractNoteManager: ContractNoteManager = .init()
    public var businessClientAssistanceManager: BusinessClientAssistanceManager = .init()

    public init() {}

    public func getServiceItem(type: String) -> ServiceItem? {
        serviceItems.first { $0.type == type }
    }

    public func getNote(uniqueCode: String) -> ContractNoteManager.ContractNoteInfo? {
        contractNoteManager.notes.filter { !$0.deprecated }.first { $0.uniqueCode == uniqueCode }
    }

    public func fetchNotes(tip: String) -> [ContractNoteManager.ContractNoteInfo] {
        fetchNotes(subsetOf: ["Tip/\(tip)"])
    }

    public func fetchNotes(mutexTags: [String]) -> [ContractNoteManager.ContractNoteInfo] {
        contractNoteManager.notes.filter {
            if case let .tags(tags) = $0.mutex {
                Set<String>(mutexTags).isSubset(of: Set<String>(tags))
            } else {
                false
            }
        }
    }

    public func fetchNotes(serviceItem: String) -> [ContractNoteManager.ContractNoteInfo] {
        fetchNotes(subsetOf: ["ServiceItem/\(serviceItem)"])
    }

    public func fetchNotes(serviceItemConfig key: String, value: String) -> [ContractNoteManager.ContractNoteInfo] {
        fetchNotes(subsetOf: ["ServiceItemConfig/\(key):\(value)"])
    }

    public func fetchNotes(subsetOf tags: [String]) -> [ContractNoteManager.ContractNoteInfo] {
        contractNoteManager.notes.filter { note in
            note.isSubsetOf(tags: tags)
        }.sorted { lhs, rhs in
            lhs.weight > rhs.weight
        }
    }

    public func fetchNotes(symmetricDifference tags: [String]) -> [ContractNoteManager.ContractNoteInfo] {
        contractNoteManager.notes.filter { note in
            !note.isSubsetOf(tags: tags)
        }.sorted { lhs, rhs in
            lhs.weight > rhs.weight
        }
    }

    public func fetchBusinessClientAssistances(subsetOf tags: [String]) -> [BusinessClientAssistanceManager.Item] {
        businessClientAssistanceManager.items.filter { $0.isSubsetOf(tags: tags) }
    }

    public func fetchBusinessClientAssistances(symmetricDifference tags: [String]) -> [BusinessClientAssistanceManager.Item] {
        businessClientAssistanceManager.items.filter { !$0.isSubsetOf(tags: tags) }
    }

    public func findIndexToInsert(willInsert noteInfo: ContractNoteManager.ContractNoteInfo, inUniqueCodes uniqueCodes: [String?]) -> Int? {
        uniqueCodes.firstIndex(where: { uniqueCode in
            guard let currentNoteInfo = contractNoteManager.notes.first(where: { $0.uniqueCode == uniqueCode }) else {
                return false
            }
            return currentNoteInfo.weight < noteInfo.weight
        })
    }
}
