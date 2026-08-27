# 新設立公司內容修正設計 — 工作包 A

- 日期：2026-08-26
- 來源 PBI：Notion「新設立公司標準金額及文案修改」（PBI Point 12、重要性 9）
- 前置工作包：B（工商登記標準價／級距表）已完成，PR #187（mendesky-web，base main）
- 涉及三個 repo，依賴序：**QuotingContentManager → OpportunityContext → mendesky-web**（三個分開 PR，依序合入）

## 1. 目標

修正工商登記（新設立公司）報價單的內容：服務項目改名（去「經濟部」前綴）、酬金名稱簡化、報價單新增備註一（案件描述，用範本變數組成）、備註二（不包含清單）擴充、母版文案微調。所有會隨案件變動的值（組織型態、資本額、地區、股東人數）一律走範本變數，不寫死（見 memory `quoting-notes-use-template-variables`）。

## 2. Worktree / 分支

| Repo | Worktree | 分支 | 基底 |
|---|---|---|---|
| QuotingContentManager | `.claude/worktrees/registration-content-revision` | `dev/registrationContentRevision` | `origin/main` |
| OpportunityContext | `.claude/worktrees/registration-content-revision` | `dev/registrationContentRevision` | `origin/dev/existingClientQuoting` |
| mendesky-web | `.claude/worktrees/registration-content-revision` | `dev/registrationContentRevision` | `origin/main` |

## 3. 設計決策紀錄

| 決策 | 選擇 | 理由 |
|---|---|---|
| 組織型態範本變數 | 新概念 `OrganizationTypeName`，**case 級**（同 `paidInCapital`/`registeredCapital`） | QCM 現有機制最直接的走法；exhaustive `scope` switch 會強制分層，不會漏 |
| 括號變體範圍 | 只套備註一實際用到的 3 個既有變數（資本額 exact、地區、股東人數） | 範圍最小、與本次 PBI 需求直接對齊；不擴大到其他帶括號變數（申報方式等），降低風險 |
| 跨 repo 落地順序 | 三個分開 PR，QCM → OC → 前端依序合入 | OC 對 QCM 是浮動 `branch: main` 依賴，QCM 未合入前 OC 引用不到新 concept；前端三份清單是純字串、不依賴後端 API，可與 OC PR 平行 review，只需晚合併 |
| 落層 | QCM 管詞彙與文案 SSOT；OC 管求值；前端管顯示 | 沿用專案既有分工（CLAUDE.md／`.ai/conventions`），不新開落層 |

## 4. QuotingContentManager 改動

### 4.1 服務項目改名（去「經濟部」前綴）

`Sources/QuotingContentManager/Entity/ServiceItem.swift:381-388`，`companyRegistration(paymentItemNameFormat:)` 的 `workItems`：

| workItem type | 現行 content | 改後 content |
|---|---|---|
| `companyNameAndBusinessScopeReservation` | 經濟部公司名稱預查 | 公司名稱預查 |
| `economicMinistryRegistration` | 經濟部設立登記 | 公司設立登記 |
| `regulationsGoverningAuditingAndAttestationCertification` | 設立資本額查核簽證 | （不變） |
| `antiMoneyLaunderingCertification` | 防洗錢查核簽證 | （不變） |
| `exporterImporterRegistration` | 國貿局進出口登記 | （不變） |
| `companyRegistration` | 國稅局營業登記 | （不變） |
| `uniformInvoicePurchasing` | 國稅局購票證申報 | （不變） |
| `ctpOfCompanyRegistration` | 經濟部CTP申報事宜 | （不變，CTP 本身是機關代辦事項慣用全稱，予以保留） |

`Sources/QuotingContentManager/UseCase/Port/TermManager.swift:58-74` 有第二份平行 hardcode（untracked 檔案，屬同事 `dev/addProvisionalIncomeTaxAudit` 的 WIP），本次**不動**——它不在 main 分支上，且不屬本次 PBI 範圍；若該分支合併後仍存在重複定義，留給後續 PBI 處理。

### 4.2 酬金名稱簡化

`Sources/QuotingContentManager/Entity/ServiceItem.swift:361-367`，`companyRegistration(for:)` 目前組出的模板：

```swift
let format = PaymentItemNameFormat(
    template: "{name}\(capitalSegment)\(TemplateVariableConcept.companyRegistrationRegion.placeholder())(不含動資查核)\(TemplateVariableConcept.companyRegistrationShareholder.placeholder())"
)
```

改為：

```swift
let format = PaymentItemNameFormat(template: "{name}")
```

`capitalSegment` 區域變數與整段組裝邏輯一併移除（不再需要依組織型態切資本額 placeholder）；`companyRegistration(for:)` 的 `organizationType` 參數簽名保留（呼叫端 `WhenCompanyRegistrationAdded` 不需改），僅內部不再使用該參數組模板——若編譯器對未使用參數警告，加 `_ organizationType: OrganizationType` 底線化參數名。

測試 `Tests/QuotingContentManagerTests/CompanyRegistrationNameTests.swift` 全部重寫：斷言 `paymentItemName(forTaxAccount: false)` 對任一 `OrganizationType` 皆回傳 serviceItem 的 `name`（即「工商登記處理作業」），不再驗資本額/地區/股東/動資查核片段。

### 4.3 新增 `OrganizationTypeName` 範本變數概念

`Sources/QuotingContentManager/Entity/TemplateVariableConcept.swift`：

```swift
// case 級
case organizationTypeName = "OrganizationTypeName"
```

加入 `case` 段（`quotingCaseName`、`paidInCapital` 等同組），並在 `scope` 的 exhaustive switch 的 `.caseLevel` 分支列表加入 `.organizationTypeName`（放在 `.paidInCapital, .registeredCapital,` 之後）。不需要 variant（無 exact/fuzzy 之分）。

### 4.4 新增備註一（案件描述）

`Sources/QuotingContentManager/ContractNoteManager.swift`，`notes` 陣列尾端加一筆（下一個可用 `uniqueCode` 為 `"15"`；`weight: 67` 使其排在既有 `uniqueCode: "3"`（weight 66）之前 —— `fetchNotes` 依 `weight` 遞減排序，見 `QuotingContentManager.swift:83,91`）：

```swift
.init(uniqueCode: "15", traits: ["ServiceItem/CompanyRegistration"], weight: 67, content: """
工商登記處理作業：\(TemplateVariableConcept.organizationTypeName.placeholder())、資本額\(TemplateVariableConcept.paidInCapital.placeholder(variant: "exact"))\(TemplateVariableConcept.registeredCapital.placeholder(variant: "exact"))、\(TemplateVariableConcept.companyRegistrationRegion.placeholder())、\(TemplateVariableConcept.companyRegistrationShareholder.placeholder())。
"""),
```

`%PaidInCapital|exact%` 與 `%RegisteredCapital|exact%` 併排寫入是刻意設計：依組織型態，OC 端只會對其中一個發值（另一個發空字串，見 `CaseTemplateVariableContributor.swift:50-105` 的 guard），求值後兩者只有一個顯示，語意等同「資本額」單一欄位。§5 的括號變體改動生效後，這裡引用的是**無括號**版本（預設變體）。

### 4.5 備註二（不包含清單）擴充

`ContractNoteManager.swift:17`（`uniqueCode: "3"`）第一行：

```
工商登記費用不包含政府規費及代墊雜項費用，服務公費及代墊費用請於辦理完成時支付。
```

改為：

```
工商登記費用不包含政府規費、投審司（外國人）、動資查核、工廠及特許項目之登記及代墊之什項費用(依其收據請款)，服務公費及代墊費用請於辦理完成時支付。
```

第二行（防洗錢 5 人規則）不動——已是新版。

### 4.6 母版文案

`Sources/QuotingContentManager/QuotingContentManager.swift:141`：

```
茲將附上%QuotingCaseName%有關%ServiceItemNames%之專業服務公費報價單。
```

改為：

```
茲將附上%QuotingCaseName%%ServiceItemNames%之專業服務公費報價單。
```

（純刪除「有關」二字，變數與其餘文字不動。）

## 5. 括號變體機制

現況：`buildPaidInCapitalGlance`／`buildRegisteredCapitalGlance`（`CaseTemplateVariableContributor.swift`）與 `buildCompanyRegistrationRegion`／`buildCompanyRegistrationShareholder`（`BundleTemplateVariableContributor.swift`）的**預設**（`isDefault: true`）變體目前都輸出帶括號的字串（如 `(資本額100萬元)`、`(雙北地區)`、`(股東3人)`）。

**改動**：這四個 contributor 方法的預設變體輸出改為**無括號**（`資本額100萬元`、`雙北地區`、`股東3人`），並新增一個帶括號的 glance 選項（`isDefault: false`，`optionName: "帶括號"`，同一 `groupKey`）供既有的 glance 下拉切換使用。值缺時（如地區未填）兩個變體都輸出空字串，行為不變。

variant key 命名：無括號沿用原 concept key 不變（`PaidInCapital|exact` 等，向下相容其他消費者的 key 引用）；帶括號版本新增 `|exact-paren`／`|paren` 後綴變體（`CompanyRegistrationRegion|paren`、`CompanyRegistrationShareholder|paren`）。

**影響範圍確認**：搜尋這四個 concept 的既有消費者，酬金名稱模板（§4.2 已改為 `{name}`）不再引用；未發現其他消費者依賴帶括號的預設輸出。故本次改動對現有行為零回歸風險，純粹是「新增一個選項＋改預設值」。

## 6. OpportunityContext 改動

### 6.1 `OrganizationTypeName` contributor

`Sources/OpportunityContext/Adapter/GetTemplateVariables/CaseTemplateVariableContributor.swift`，新增一個 `buildOrganizationTypeName` static method（同檔 `buildPaidInCapitalGlance` 旁）：

```swift
/// `OrganizationTypeName` — 組織型態中文名（如「股份有限公司」），供備註一等文案引用。
package static func buildOrganizationTypeName(
    organizationType: OrganizationType?
) -> [TemplateVariable] {
    guard let organizationType else { return [] }
    return [.init(
        key: TemplateVariableConcept.organizationTypeName.key(),
        value: organizationTypeDisplayName(organizationType),
        remark: "組織型態"
    )]
}

private static func organizationTypeDisplayName(_ type: OrganizationType) -> String {
    switch type {
    case .companyLimitedByShares: return "股份有限公司"
    case .limitedCompany: return "有限公司"
    case .soleProprietorshipOrPartnership: return "獨資合夥"
    case .nonProfitOrganization: return "非營利事務組織"
    case .professionalPracticeIncome: return "執行業務所得"
    case .foreignCompany: return "境外公司"
    }
}
```

`organizationTypeDisplayName` 用 exhaustive switch（無 `default`），新增組織型態時編譯器強制補上中文名——與 §4.3 的用語對齊 Notion PBI 訪談紀錄（總所/台北所/嘉義所/台中所報價差異段落所用的組織型態中文名）。

### 6.2 組裝進 case 級變數

`Sources/OpportunityContext/Adapter/GetTemplateVariables/GetTemplateVariablesApplicationService.swift`，`buildCase`（約 :129）或其呼叫端加入 `organizationTypeNameVariable = CaseTemplateVariableContributor.buildOrganizationTypeName(organizationType: ...)`，併入既有 `caseVariables` 組裝（同檔約 :200 的 `(basic + paidInCapitalGlance + registeredCapitalGlance + ground + supplementary + serviceItemNamesVars)` 那一行，加上新變數）。`organizationType` 的取得方式沿用同函式已有的讀取路徑（與 `paidInCapitalGlance`/`registeredCapitalGlance` 共用的 case 讀取結果）。

### 6.3 括號變體求值改動

- `CaseTemplateVariableContributor.swift:50-105`（`buildPaidInCapitalGlance`／`buildRegisteredCapitalGlance`）：`exact` 變體的 `value` 由 `"(資本額\(representPrice(...)))"` 改為 `"資本額\(representPrice(...))"`；新增 `exact-paren` 變體，`value` 為原本帶括號的字串，`glance: .init(optionName: "帶括號", groupKey: <同組>, isDefault: false)`。`fuzzy` 變體（100 萬內特例）比照處理，新增對應 `fuzzy-paren`。
- `BundleTemplateVariableContributor.swift:122-149`（`buildCompanyRegistrationRegion`／`buildCompanyRegistrationShareholder`）：同上模式，`value` 去括號為預設，新增 `|paren` variant 帶括號。

### 6.4 付款名稱模板消費點

`Sources/OpportunityContext/Listener/Quoting/WhenCompanyRegistrationAdded.swift:83-95` 不需改動——QCM 端模板已砍到 `{name}`（§4.2），此處呼叫 `quotingContentManager.companyRegistration(for: organizationType)` 與 `paymentItemName(forTaxAccount: false)` 的既有呼叫方式不變，模板變薄是 QCM 內部改動的自然結果。

## 7. mendesky-web 改動

### 7.1 服務項目名稱同步（三份平行清單）

去「經濟部」前綴，與 §4.1 QCM 改動的中文字串逐字對齊：

- `src/app/features/quoting-cases/models/p2-template.model.ts:789-824`（`registration` module 的 tags A/B）
- `src/app/features/quoting-cases/components/case-edit-modal/pages/p4-contract/models/p4-contract.model.ts:761-768`（服務範圍 8 項）
- `src/app/features/quoting-cases/components/case-edit-modal/components/case-view-modal/case-view-mock.ts:674-680`

### 7.2 酬金 badge 簡化

`p4-contract.model.ts:403-435`（registration badge 組裝邏輯）與 `:428`（無條件附加 `(不含動資查核)`）：移除動資查核片段；badge 不再組裝資本額/地區/股東人數片段（這些資訊改由備註一承載，與 §4.2 的酬金名稱簡化語意一致）。組裝函式收斂為單純顯示 `serviceItem.name`（工商登記處理作業），如同函式因此變成 trivial 可考慮移除、改直接讀名稱——實際處理方式留給實作階段依當時程式碼判斷，不在此規定。

### 7.3 母版文案同步

`src/app/features/quoting-cases/components/case-edit-modal/pages/p5-letter/p5-letter.component.ts:9-11`（`LETTER_CONTENT_TEMPLATE`）去「有關」，與 §4.6 QCM 改動逐字對齊。

## 8. Non-goals（本工作包不做）

- 服務項目改名不涉及新增/移除 workItem（那是工作包 C 的範圍：商業登記名稱預查、小規模免用統一發票）。
- 不做工作包 D 的閉鎖型公司相關文案。
- `TermManager.swift` 第二份平行 hardcode（§4.1 已註明）本次不動。
- 括號變體機制不擴大到其他既有帶括號變數（申報方式長短描述等）。

## 9. 測試

- QCM：`CompanyRegistrationNameTests.swift` 重寫（§4.2）；`ContractNoteManager` 新增備註一的斷言（uniqueCode "15" 存在、weight 排序在 "3" 之前、content 含正確 placeholder）；`TemplateVariableConcept` 的 `organizationTypeName` scope 測試（`.caseLevel`）。
- OC：`buildOrganizationTypeName` 六種組織型態各一條斷言；括號/無括號 variant 各自輸出正確性測試（含缺值回空字串迴歸）。
- 前端：三份清單字串同步的既有 snapshot/spec 測試更新；badge 組裝測試更新去動資查核片段。

## 10. 前置依賴與風險

- QCM PR 合入 main 後，OC 因浮動 `branch: main` 依賴，下次 resolve（CI 或本機 `swift package update`）即取得新 concept；OC PR 開發期間需自行 pin/resolve 到 QCM 開發中版本或等 QCM 先合併（依 §3 已定案順序，QCM 先行）。
- QCM 本機另有同事 untracked 的 `TermManager.swift`/`Term.swift`（`dev/addProvisionalIncomeTaxAudit` 分支 WIP），本次 worktree 基於 `origin/main` 切出，不受影響；QCM PR 合併順序若與該分支交錯，需留意 `TermManager.swift` 若日後併入 main 是否與 §4.1 的改名重複，由後續 PBI 處理。
