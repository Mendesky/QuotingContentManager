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

    public var rightsAndObligations: ProvisionsSection {
        get {
            .init(title: "權利義務事項", provisions: [
                "本事務所提供%AccountingWorkName%處理作業服務將依據　貴公司所提供之資料及文件，利用會計專業知識蒐集、分類及彙總資訊，進而提供%AccountingWorkName%處理作業服務項目，本事務所對資料並無查核或核閱義務，本事務所僅係依 貴公司所提供之資訊完成%AccountingWorkName%處理作業服務。",
                "本事務所所提供%AccountingWorkName%處理作業服務，僅係依 貴公司提供之文件與資料分類及彙總，並僅限協助　貴公司為%AccountingWorkName%處理作業服務使用。除本事務所分類及彙總有過失之情形外，如本事務所於本報價單意旨提供%AccountingWorkName%處理作業服務事項，而遭致第三人向本事務所為法律上之主張而致生損害時，貴公司同意負責補償該損害。另未經本事務所書面同意，本事務所所提供之服務不得提供他人使用；且若有此種情形致他人權益受損，本事務所不負任何責任。",
                "本事務所對　貴公司所提供之各項資料或相關文件，當盡保密之責。",
            ])
        }
    }

    public var agreementTerms: ProvisionsSection {
        get {
            .init(title: "其它約定事項", provisions: [
                "上開服務公費自本函發出日有效期間為三個月，倘　貴公司簽署回函時點已逾本函發出日三個月以上，本事務所保有修改本服務委任書之權利。",
                "在本報價單所載之工作服務期間，任何一方可提前三個月要求終止服務或終止雙方之委任關係，惟 貴公司仍應支付本事務所已完成工作之服務費用。貴公司同意於雙方之委任關係終止後15日內，不經本事務所催告即應對本事務所清償所有 貴公司應付之費用。",
                "貴公司或 貴公司之代理人或使用人所提供之文件將暫存於本事務所處，本事務所將依本事務所當時之正常文件管理方式保管之。本事務所得於每年度終了或特定服務完成後，返還本事務所為 貴公司所留存之文件。於 貴公司請求返還之情形下，本事務所將於收訖 貴公司應給付之全部費用後，儘速返還本事務所為 貴公司所留存之文件。除前述 貴公司交付之文件資料外，本事務所得留存相關文件影本、紀錄，包括草稿、筆記、利害衝突確認紀錄、帳務及財務資訊、內部紀錄及其他工作成果，除依法應保存之文件、紀錄或資訊外，本事務所得於委任關係終止或特定服務履行完成後，銷毀或以其他方式處分該等文件、紀錄或資訊。\n有關本報價單所生之相關爭議，均應以中華民國法令為準據法。",
            ])
        }
    }
}
