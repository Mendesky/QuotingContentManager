//
//  IndustrialType.swift
//  QuotingContentManager
//

/// 報價案的行業別。case 名稱（raw value）與 OC 的 `IndustrialType` 相同。
///
/// 目前只用來挑合約備註：專營投資業的註一換成投資業版（uniqueCode 26 取代 16）。
public enum IndustrialType: String, Codable, Sendable, CaseIterable {
    case sales                    // 買賣業
    case construction             // 營建業
    case manufacturingAndOthers   // 製造業與其他
    case investmentOnly           // 專營投資業

    /// 合約備註 trait tag 的前綴。消費端（OC）以此辨識「挑選結果依行業別而定」的備註。
    public static let contractNoteTagPrefix = "IndustrialType/"

    /// 挑合約備註用的行業別 trait tag：`IndustrialType/<rawValue>`（例：`IndustrialType/investmentOnly`）。
    ///
    /// 消費端（OC）為每個案件在 ServiceItem tag 集合之外多帶這一個（與 `OrganizationType.contractNoteTag` 同一套做法），
    /// `ContractNoteManager` 以 `tags` / `excluded` 分流一般版與投資業版的註一（uniqueCode 16 ↔ 26）。
    public var contractNoteTag: String {
        "\(Self.contractNoteTagPrefix)\(rawValue)"
    }
}
