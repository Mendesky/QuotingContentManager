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
//        .settlementReview,
        .customized,
        .companyRegistration,
        .ctp,
        .assistanceAnnualSupplementaryPremiumDeductionDetailsReporting,
//        .assistanceRegistrationByJWServiceItem,
        .assistanceWithCompanyCertificatationApplication,
        .assistanceWithCompanySeal,
        .assistanceWithChairmanSeal,
        .assistanceWithCompanyConvenienceSeal,
        .assistanceWithChairmanConvenienceSeal,
        .assistanceWithInvoiceSeal,
        .assistanceWithLaborAndHealthInsuranceInsuredUnitSetting,
        .ownerOccupiedResidencePartForBusinessApplication,
    ]

    public var contractNoteManager: ContractNoteManager = .init()
    public var businessClientAssistanceManager: BusinessClientAssistanceManager = .init()
    public var paymentItemManager: PaymentItemManager = .init()

    public init() {}

    public func getServiceItem(type: String) -> ServiceItem? {
        serviceItems.first { $0.type == type }
    }

    public func getWorkItem(serviceType: String, workItemType: String) -> WorkItem? {
        getServiceItem(type: serviceType)?.workItem(type: workItemType)
    }

    public func getNote(uniqueCode: String) -> ContractNoteInfo? {
        contractNoteManager.notes.filter { !$0.deprecated }.first { $0.uniqueCode == uniqueCode }
    }

    public func fetchNotes(tip: String) -> [ContractNoteInfo] {
        fetchNotes(subsetOf: ["Tip/\(tip)"])
    }

    public func fetchNotes(mutexTags: [String]) -> [ContractNoteInfo] {
        contractNoteManager.notes.filter {
            if case let .tags(tags) = $0.mutex {
                Set<String>(mutexTags).isSubset(of: Set<String>(tags))
            } else {
                false
            }
        }
    }

    public func fetchNotes(serviceItem: String) -> [ContractNoteInfo] {
        fetchNotes(subsetOf: ["ServiceItem/\(serviceItem)"])
    }

    public func fetchNotes(serviceItemConfig key: String, value: String) -> [ContractNoteInfo] {
        fetchNotes(subsetOf: ["ServiceItemConfig/\(key):\(value)"])
    }

    public func fetchNotes(subsetOf tags: [String]) -> [ContractNoteInfo] {
        contractNoteManager.notes.filter { note in
            note.isSubsetOf(tags: tags)
        }.sorted { lhs, rhs in
            lhs.weight > rhs.weight
        }
    }

    public func fetchNotes(symmetricDifference tags: [String]) -> [ContractNoteInfo] {
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

    public func fetchPaymentItems(subsetOf tags: [String]) -> [PaymentItemManager.Item] {
        paymentItemManager.items.filter { $0.isSubsetOf(tags: tags) }
    }

    public func fetchPaymentItems(serviceItem: String) -> [PaymentItemManager.Item] {
        fetchPaymentItems(subsetOf: ["ServiceItem/\(serviceItem)"])
    }

    public func findContactNoteIndexToInsert(willInsert noteInfo: ContractNoteInfo, inUniqueCodes uniqueCodes: [String?]) -> Int? {
        uniqueCodes.firstIndex(where: { uniqueCode in
            guard let currentNoteInfo = contractNoteManager.notes.first(where: { $0.uniqueCode == uniqueCode }) else {
                return false
            }
            return currentNoteInfo.weight < noteInfo.weight
        })
    }
}

extension QuotingContentManager {
    public var paymentTitle: String {
        get {
            "酬金"
        }
    }
}



extension QuotingContentManager {
    public var contractHeader: Copywriting {
        get {
            .init(title: "承 貴公司委任本事務所辦理有關%ServiceItemNames%之專業服務，至深感荷。謹將服務內容及酬金等分別說明如后，敬請卓察賜覆為禱。", content: "感謝 貴公司對本事務所的支持與愛護，本事務所本著積極服務顧客的熱忱，以及專業智慧的多元服務，特將本事務所受託辦理有關%ServiceItemNames%之專業服務的內容概述如後，期盼此項合作能協助 貴公司提升%AccountingWorkName%品質，俾能符合相關稅務法令和企業會計準則之規定。茲將委任之目的、服務範圍、貴公司協助事項、酬金、權利義務事項及同意函列示如下：")
        }
    }
    
    public var letter: Copywriting {
        get {
            .init(title: "本公司同意委託 貴事務所對本公司執行有關%ServiceItemNames%之專業服務及公費報價，請查照。", content: "茲將附上%CompanyName%有關%ServiceItemNames%之專業服務公費報價單。\n我們希望以最專業多元的服務與 貴公司長久配合，公費內容若經確認，煩請將最後一頁同意函簽章並回覆至敝事務所，謝謝您的合作。")
        }
    }
    
    
    public var purpose: Copywriting {
        get {
            .init(title: "目的", content: "貴公司委託本事務所辦理有關%ServiceItemNames%之專業服務，以協助 貴公司提升整體%AccountingWorkName%品質，並符合相關稅務法令和企業會計準則等之規定。")
        }
    }

    public var serviceScope: Copywriting {
        get {
            .init(title: "服務範圍及內容", content: "本項專案作業之服務範圍將根據相關稅務法令、企業會計準則與會計師查核簽證準則之規定，由 貴公司委託本事務所辦理有關%ServiceItemNames%之專業服務，俾能符合相關法令規定與提升整體%AccountingWorkName%品質。有關具體服務事項如下：")
        }
    }
}
