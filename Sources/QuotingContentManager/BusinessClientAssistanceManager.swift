//
//  BusinessClientAssistanceManager.swift
//  QuotingContentManager
//
//  Created by Grady Zhuo on 2026/3/2.
//

public struct BusinessClientAssistanceManager: Sendable {
    public var items: [Item] = [
        .init(
            name: "指派專責會計人員",
            content: "為期本專業服務能順利完成，爰建議 貴公司應指派熟悉公司會計作業流程之人員，以作為與本事務所溝通協調及對內對外之窗口。"
        ),
        .init(
            name: "配合及時提供相關資訊",
            content: "為順利達成上述服務，委任人應提供相關之會計資訊、文件及憑證等，供受任人審閱，並答覆有關問題之詢問。委任人會計人員應對會計帳務工作儘量協助，此項協助包括憑證蒐集、對帳、提供有關文件資料、相關問題詢問等;至於其具體配合事項，將由受任人之服務人員於工作開始前，提供應備資料清單，商請委任人有關人員惠予配合。"
        ),
    ]

    public init() {}
}
