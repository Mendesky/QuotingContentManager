import Foundation

/// 附加服務在報價單上的「名稱顯示策略」——顯式宣告這個附加服務的名稱**是否內嵌金額**，
/// 取代過去用 `additionalServiceNameFormat: AdditionalServiceNameFormat?` 是否為 nil 來反推。
///
/// 為什麼要顯式：`format == nil` 過去同時代表兩件事——(a) 純名稱附加服務（如自用住宅，合法）、
/// (b) 價格型附加服務漏設 format（錯誤），caller 無法區分。改用本 enum 後，「價格型一定帶 format」
/// 由 `.embedsPrice` 的 associated value 強制，判斷顯示走哪條路也直接 switch 策略、語意清楚。
public enum AdditionalServiceNameStrategy: Codable, Sendable, Equatable {
    /// 純名稱附加服務（如自用住宅）：報價單上用 `ServiceItem.name`，名稱不內嵌金額。
    /// 一般（非附加）serviceItem 也採此預設。
    case flatName
    /// 名稱內嵌金額（如 CTP「代辦年度CTP申報(每年3月；加收 {price} 元/家)」）：必帶 format template。
    case embedsPrice(AdditionalServiceNameFormat)
}
