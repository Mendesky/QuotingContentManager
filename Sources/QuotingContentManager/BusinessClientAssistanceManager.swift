//
//  BusinessClientAssistanceManager.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

public struct BusinessClientAssistanceManager: Sendable {
    public var items: [Item] = [
        .init(
            uniqueCode: "1",
            name: "指派專責會計人員",
            content: "為期本專業服務能順利完成，爰建議 貴公司應指派熟悉公司會計作業流程之人員，以作為與本事務所溝通協調及對內對外之窗口。"
        ),
        .init(
            uniqueCode: "2",
            name: "網路銀行申請",
            content: "為方便本事務所執行出納事務，故請 貴公司配合申請網路銀行，以利運作順暢。(請提供編輯與審核帳號各一組)。",
            traits: ["ServiceItem/CashierOperation"]
        ),
        .init(
            uniqueCode: "3",
            name: "配合及時提供相關資訊",
            content: "為順利達成上述服務， 貴公司除應提供相關之會計資訊、文件及憑證等，供本事務所審閱，並答覆有關問題之詢問，亦應保證上述資料之真實性。貴公司會計人員應對%AccountingWorkName%工作儘量協助，此項協助包括憑證蒐集、對帳、提供有關文件資料、相關問題詢問等；至於其具體配合事項，將由本事務所之服務人員於工作開始前，提供應備資料清單，商請 貴公司有關人員惠予配合。前述資料如有因 貴公司延遲提供以致影響本事務所工作，或導致 貴公司委託之簽證或服務無法於法定期間內完成，本事務所不負擔任何責任，且本事務所得隨時終止委託。"
        ),
    ]

    public init() {}


}
