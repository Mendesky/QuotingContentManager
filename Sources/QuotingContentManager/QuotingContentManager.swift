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

    public init() {}

    public func getServiceItem(type: String) -> ServiceItem? {
        serviceItems.first { $0.type == type }
    }

    public func getNote(uniqueCode: String) -> ContractNoteManager.ContractNoteInfo? {
        contractNoteManager.notes.filter { !$0.deprecated }.first { $0.uniqueCode == uniqueCode }
    }
}
