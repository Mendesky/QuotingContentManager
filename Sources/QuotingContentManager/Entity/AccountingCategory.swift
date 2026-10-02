//
//  AccountingCategory.swift
//  QuotingContentManager
//

/// 文案取版依據的帳別。
///
/// 與 OpportunityContext 領域的 `AccountingType` 一一對應——QCM 不能依賴 OC，所以自己宣告一份。
/// 兩邊的轉換只在 OC 寫一處（窮舉 switch），領域新增帳別時那裡會編譯不過，逼人決定新帳別的文案。
///
/// 所有取版的 API 都收 `AccountingCategory?`：`nil` 代表**判定不出帳別**（例如案件只有工商登記、出納），
/// 一律取一般版。
public enum AccountingCategory: String, Sendable, CaseIterable {
    /// 純簽證
    case auditCertification
    /// 稅務帳
    case taxAccount
    /// 管理帳
    case managementAccount
    /// 財務帳
    case financialAccount
}

extension Optional where Wrapped == AccountingCategory {
    /// **「哪些帳別印稅務帳版文案」的唯一決策點。**
    ///
    /// 目前文案只有兩版：一般版，與稅務帳版（各型別的 `taxAccount…` 欄位，nil 代表沿用一般版）。
    /// 純簽證／管理帳／財務帳與判定不出帳別，都印一般版——這是文案決策，所以留在 QCM。
    ///
    /// 日後某個帳別需要自己的版本：在各型別加對應欄位，並改這裡的 switch。
    var usesTaxAccountCopy: Bool {
        switch self {
        case .some(.taxAccount):
            true
        case .some(.auditCertification), .some(.managementAccount), .some(.financialAccount), .none:
            false
        }
    }

    /// 取該帳別要印的版本：稅務帳有專屬版本就用，否則一般版。
    func pick(standard: String, taxAccount: String?) -> String {
        usesTaxAccountCopy ? (taxAccount ?? standard) : standard
    }
}
