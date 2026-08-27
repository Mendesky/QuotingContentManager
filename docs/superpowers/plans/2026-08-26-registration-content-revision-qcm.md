# 新設立公司內容修正（QCM）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 工商登記服務項目改名、酬金名稱簡化為 `{name}`、新增 `OrganizationTypeName` 範本變數概念、新增備註一（案件描述，用範本變數組成）、備註二擴充、母版文案去「有關」。

**Architecture:** 純 QCM 內部改動（詞彙與文案 SSOT），無跨套件依賴。三個任務依序：服務項目改名/酬金簡化（Task 1）→ 新概念（Task 2，Task 3 需要它）→ 備註/母版（Task 3）。

**Tech Stack:** Swift 6, Swift Testing（`@Suite`/`@Test`/`#expect`），`swift test`。

**Spec:** `docs/superpowers/specs/2026-08-26-registration-content-revision-design.md`

## Global Constraints

- commit 訊息**不要**加 `Co-Authored-By:` 行（`CLAUDE.local.md` 明文規定，QCM 專屬，與其他 repo 不同）。
- 一律在 worktree `dev/registrationContentRevision`（基底 `origin/main`）內操作，不要碰主 checkout。
- 這是 QCM→OC→前端三個分開 PR 的第一個，本計畫合入 main 後 OC/前端才能接手（OC 對 QCM 是浮動 `branch: main` 依賴）。
- `OrganizationType.capitalPlaceholderKey`（`Entity/OrganizationType.swift:20`）是公開 API、有獨立測試（`OrganizationTypeTests.swift`），Task 1 移除它唯一的呼叫點後**不要**刪除或改動這個屬性——它是不相關的既有 API，本次任務範圍外。
- 不動 `Sources/QuotingContentManager/UseCase/Port/TermManager.swift`（untracked、屬同事 WIP，不在 main 上）。

---

### Task 1: 服務項目改名＋酬金名稱簡化

**Files:**
- Modify: `Sources/QuotingContentManager/Entity/ServiceItem.swift:347-388`
- Modify: `Tests/QuotingContentManagerTests/CompanyRegistrationNameTests.swift`（整檔重寫）

**Interfaces:**
- Consumes: 無新依賴。
- Produces: `ServiceItem.companyRegistration(for:)` 回傳的 `paymentItemNameFormat.template` 恆為 `"{name}"`；`companyRegistration(paymentItemNameFormat:)` 私有 helper 的 `workItems` content 改名。下游 Task 3 不消費本 task 產出（無耦合）。

- [ ] **Step 1: Write the failing tests**

整檔改寫 `Tests/QuotingContentManagerTests/CompanyRegistrationNameTests.swift`：

```swift
import Testing
@testable import QuotingContentManager

@Suite("ServiceItem.companyRegistration(for:) 酬金名稱")
struct CompanyRegistrationNameTests {

    private func template(for type: OrganizationType) -> String {
        ServiceItem.companyRegistration(for: type).paymentItemNameFormat?.template ?? ""
    }

    @Test("所有組織型態的酬金名稱模板皆為 {name}（不再附加資本額/地區/股東/動資查核）", arguments: OrganizationType.allCases)
    func templateIsPlainName(_ type: OrganizationType) {
        #expect(template(for: type) == "{name}")
    }

    @Test("目錄版（無參數）與依組織型態版本模板相同")
    func catalogVersionMatchesAnyType() {
        let catalog = ServiceItem.companyRegistration.paymentItemNameFormat?.template
        let shares = ServiceItem.companyRegistration(for: .companyLimitedByShares).paymentItemNameFormat?.template
        #expect(catalog == shares)
        #expect(catalog == "{name}")
    }

    @Test("服務項目名稱與 workItem 皆已去除經濟部前綴")
    func workItemNamesRenamed() {
        let item = ServiceItem.companyRegistration
        #expect(item.workItems.first { $0.type == "companyNameAndBusinessScopeReservation" }?.content == "公司名稱預查")
        #expect(item.workItems.first { $0.type == "economicMinistryRegistration" }?.content == "公司設立登記")
        #expect(item.workItems.first { $0.type == "regulationsGoverningAuditingAndAttestationCertification" }?.content == "設立資本額查核簽證")
        #expect(item.workItems.first { $0.type == "antiMoneyLaunderingCertification" }?.content == "防洗錢查核簽證")
        #expect(item.workItems.first { $0.type == "exporterImporterRegistration" }?.content == "國貿局進出口登記")
        #expect(item.workItems.first { $0.type == "companyRegistration" }?.content == "國稅局營業登記")
        #expect(item.workItems.first { $0.type == "uniformInvoicePurchasing" }?.content == "國稅局購票證申報")
        #expect(item.workItems.first { $0.type == "ctpOfCompanyRegistration" }?.content == "經濟部CTP申報事宜")
    }
}

@Suite("QuotingContentManager.companyRegistration(for:)")
struct ManagerCompanyRegistrationTests {

    @Test("manager 對任一組織型態皆回傳 {name} 模板", arguments: OrganizationType.allCases)
    func managerAlwaysReturnsPlainName(_ type: OrganizationType) {
        let item = QuotingContentManager.standard.companyRegistration(for: type)
        #expect(item.paymentItemNameFormat?.template == "{name}")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter CompanyRegistrationNameTests`
Expected: FAIL — `templateIsPlainName`/`workItemNamesRenamed` 等斷言不成立（現行模板仍含資本額/地區/股東/動資查核片段，workItem 仍帶「經濟部」前綴）。

- [ ] **Step 3: Write minimal implementation**

`Sources/QuotingContentManager/Entity/ServiceItem.swift`，把 :364-367 的 `companyRegistration(for:)` 改為：

```swift
    /// 依組織型態回傳工商登記服務項目。酬金名稱不再依組織型態/資本額/地區/股東人數變化
    /// （這些案件細節改由報價單備註一承載，見 QCM ContractNoteManager uniqueCode "15"）；
    /// 保留 `organizationType` 參數是為了不動呼叫端簽名（OC `WhenCompanyRegistrationAdded` 沿用既有呼叫）。
    public static func companyRegistration(for organizationType: OrganizationType) -> Self {
        companyRegistration(paymentItemNameFormat: PaymentItemNameFormat(template: "{name}"))
    }
```

同檔 :381-388 的 `workItems` 改名（只改這 3 行 content，其餘 5 行不變）：

```swift
                .init(type: "companyNameAndBusinessScopeReservation", content: "公司名稱預查"),
                .init(type: "economicMinistryRegistration", content: "公司設立登記"),
```

（`regulationsGoverningAuditingAndAttestationCertification`、`antiMoneyLaunderingCertification`、`exporterImporterRegistration`、`companyRegistration`、`uniformInvoicePurchasing`、`ctpOfCompanyRegistration` 六個 content 保持原字串不動。）

檔頭 :347-356 的 doc comment（描述 `paymentItemNameFormat` 依組織型態產出不同資本額狀態）已與新行為不符，一併改為：

```swift
    /// 工商登記服務項目(目錄/預設版)。
    ///
    /// 酬金名稱模板固定為 `{name}`（工商登記處理作業），不因組織型態變化。
    public static var companyRegistration: Self {
        get {
            companyRegistration(for: .companyLimitedByShares)
        }
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter CompanyRegistrationNameTests`
Expected: PASS（全部綠燈）。

- [ ] **Step 5: Run full test suite to check for regressions**

Run: `swift test`
Expected: 全綠。特別確認 `OrganizationTypeTests`（不受影響，`capitalPlaceholderKey` 本身未被改動）與其他消費 `ServiceItem.companyRegistration` 的既有測試仍通過。

- [ ] **Step 6: Commit**

```bash
git add Sources/QuotingContentManager/Entity/ServiceItem.swift Tests/QuotingContentManagerTests/CompanyRegistrationNameTests.swift
git commit -m "[UPDATE] 工商登記服務項目改名＋酬金名稱簡化為 {name}"
```

---

### Task 2: 新增 `OrganizationTypeName` 範本變數概念

**Files:**
- Modify: `Sources/QuotingContentManager/Entity/TemplateVariableConcept.swift`
- Test: `Tests/QuotingContentManagerTests/TemplateVariableConceptTests.swift`（若不存在則新建；先檢查 `Tests/QuotingContentManagerTests/` 是否已有同名或相關檔案，若有既有 `TemplateVariableConcept` 測試檔則加測試進去，不要建立重複檔案）

**Interfaces:**
- Consumes: 無。
- Produces: `TemplateVariableConcept.organizationTypeName`（case，rawValue `"OrganizationTypeName"`），`scope == .caseLevel`。Task 3 消費 `TemplateVariableConcept.organizationTypeName.placeholder()`。

- [ ] **Step 1: Write the failing test**

先確認既有測試檔案位置：

```bash
ls Tests/QuotingContentManagerTests/ | grep -i templatevariable
```

若找到既有檔案（如 `TemplateVariableConceptTests.swift`），把以下 `@Test` 加進該檔的既有 `@Suite` 內；若沒有則新建檔案並用以下完整內容：

```swift
import Testing
@testable import QuotingContentManager

@Suite("TemplateVariableConcept.organizationTypeName")
struct TemplateVariableConceptOrganizationTypeNameTests {

    @Test("organizationTypeName 是 case 級變數")
    func isCaseLevel() {
        #expect(TemplateVariableConcept.organizationTypeName.scope == .caseLevel)
    }

    @Test("organizationTypeName 的 placeholder 為 %OrganizationTypeName%")
    func placeholderIsCorrect() {
        #expect(TemplateVariableConcept.organizationTypeName.placeholder() == "%OrganizationTypeName%")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter organizationTypeName` （或若加進既有檔案：`swift test --filter TemplateVariableConcept`）
Expected: FAIL — `error: type 'TemplateVariableConcept' has no member 'organizationTypeName'`（編譯錯誤，屬預期的 RED）。

- [ ] **Step 3: Write minimal implementation**

`Sources/QuotingContentManager/Entity/TemplateVariableConcept.swift`，在 `// case 級` 區塊、`case registeredCapital = "RegisteredCapital"` 之後加一行：

```swift
    case organizationTypeName = "OrganizationTypeName"
```

`scope` 的 exhaustive switch，`.caseLevel` 分支（`case .quotingCaseName, .defaultToName, .totalAssets, .estimatedAnnualRevenue, .paidInCapital, .registeredCapital,` 這一行）加入新 case：

```swift
        case .quotingCaseName, .defaultToName, .totalAssets, .estimatedAnnualRevenue,
             .paidInCapital, .registeredCapital, .organizationTypeName,
             .financialComplianceAuditGroundName, .financialComplianceAuditGroundAmount,
             .defaultAccountingPaymentItemSupplementaryNote,
             .defaultFinancialComplianceAuditPaymentItemSupplementaryNote,
             .defaultTaxComplianceAuditPaymentItemSupplementaryNote:
            return .caseLevel
```

（不加會編譯失敗——exhaustive switch 沒有 `default`，這是刻意設計，見檔頭 doc comment。）

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter organizationTypeName`（或對應 filter）
Expected: PASS。

- [ ] **Step 5: Run full test suite**

Run: `swift test`
Expected: 全綠，無其他 exhaustive switch 因新 case 漏分層而編譯失敗（`TemplateVariableConcept.swift` 內只有這一個 switch 需要更新，已在 Step 3 處理）。

- [ ] **Step 6: Commit**

```bash
git add Sources/QuotingContentManager/Entity/TemplateVariableConcept.swift Tests/QuotingContentManagerTests/
git commit -m "[ADD] 範本變數概念 OrganizationTypeName（case 級）"
```

---

### Task 3: 新增備註一＋備註二擴充＋母版文案

**Files:**
- Modify: `Sources/QuotingContentManager/ContractNoteManager.swift`
- Modify: `Sources/QuotingContentManager/QuotingContentManager.swift:141`
- Test: `Tests/QuotingContentManagerTests/ContractNoteManagerTests.swift`（若不存在則新建；先檢查是否已有測試該 manager 的既有檔案）

**Interfaces:**
- Consumes: Task 2 的 `TemplateVariableConcept.organizationTypeName`；既有 `TemplateVariableConcept.paidInCapital`/`.registeredCapital`/`.companyRegistrationRegion`/`.companyRegistrationShareholder`。
- Produces: 無下游任務消費（本計畫最後一個 task）。OC 端 Task（另一份 plan）會消費 `%OrganizationTypeName%` 這個 placeholder 字串本身（透過 QCM 合入 main 後的浮動依賴），不消費 Swift 型別。

- [ ] **Step 1: Write the failing tests**

先確認既有測試檔案：

```bash
ls Tests/QuotingContentManagerTests/ | grep -i contractnote
```

若找到既有檔案則把以下 `@Test` 加進去；否則新建 `Tests/QuotingContentManagerTests/ContractNoteManagerTests.swift`：

```swift
import Testing
@testable import QuotingContentManager

@Suite("ContractNoteManager — 工商登記備註一（案件描述）")
struct ContractNoteManagerRegistrationNote1Tests {

    private var notes: [ContractNoteInfo] {
        ContractNoteManager().notes
    }

    @Test("uniqueCode 15 存在，屬 ServiceItem/CompanyRegistration，weight 高於既有備註 3（66）")
    func note15Exists() {
        let note15 = notes.first { $0.uniqueCode == "15" }
        #expect(note15 != nil)
        #expect(note15?.weight == 67)
        #expect(note15?.traits.first?.tags.contains("ServiceItem/CompanyRegistration") == true)
    }

    @Test("備註一內容含四個範本變數（組織型態、資本額 exact 雙版本、地區、股東）")
    func note15ContainsPlaceholders() {
        let content = notes.first { $0.uniqueCode == "15" }?.content ?? ""
        #expect(content.contains("%OrganizationTypeName%"))
        #expect(content.contains("%PaidInCapital|exact%"))
        #expect(content.contains("%RegisteredCapital|exact%"))
        #expect(content.contains("%CompanyRegistrationRegion%"))
        #expect(content.contains("%CompanyRegistrationShareholder%"))
    }

    @Test("備註一（weight 67）排在既有備註 3（weight 66）之前")
    func note15SortsBeforeNote3() {
        let manager = QuotingContentManager.standard
        let fetched = manager.fetchNotes(serviceItem: "CompanyRegistration")
        let codes = fetched.map(\.uniqueCode)
        let index15 = codes.firstIndex(of: "15")
        let index3 = codes.firstIndex(of: "3")
        #expect(index15 != nil)
        #expect(index3 != nil)
        if let index15, let index3 {
            #expect(index15 < index3)
        }
    }
}

@Suite("ContractNoteManager — 工商登記備註二（不包含清單）擴充")
struct ContractNoteManagerRegistrationNote2Tests {

    @Test("備註 3 第一行含投審司、動資查核、工廠及特許項目字樣")
    func note3ExpandedExclusions() {
        let note3 = ContractNoteManager().notes.first { $0.uniqueCode == "3" }
        let content = note3?.content ?? ""
        #expect(content.contains("投審司"))
        #expect(content.contains("動資查核"))
        #expect(content.contains("工廠及特許項目"))
        #expect(content.contains("如股東超過5人，第6位起每位加收新台幣500元之防制洗錢查核費"))
    }
}

@Suite("QuotingContentManager — 母版文案")
struct MasterTemplateTests {

    @Test("letter.content（母版文案）不含「有關」二字，且變數與其餘文字保留")
    func letterContentOmitsYouGuan() {
        let content = QuotingContentManager.standard.letter.content
        #expect(!content.contains("有關"))
        #expect(content.contains("茲將附上\(TemplateVariableConcept.quotingCaseName.placeholder())\(TemplateVariableConcept.serviceItemNames.placeholder())之專業服務公費報價單。"))
    }

    @Test("contractHeader／purpose／letter.title 的「有關」不受影響（本次僅動 letter.content 一處）")
    func onlyLetterContentChanged() {
        let manager = QuotingContentManager.standard
        #expect(manager.contractHeader.title.contains("有關"))
        #expect(manager.contractHeader.content.contains("有關"))
        #expect(manager.letter.title.contains("有關"))
        #expect(manager.purpose.content.contains("有關"))
    }
}
```

`QuotingContentManager.swift` 內「有關」共出現 4 處（`contractHeader.title`、`contractHeader.content`、`letter.title`、`purpose.content`），本次**只改 `letter.content` 一處**（即 spec §4.6 指定的母版文案，`:141` 那一行 `.init(title: ..., content: "茲將附上...")` 的 `content` 參數）——其餘三處保留「有關」不動，`onlyLetterContentChanged` 這條測試就是鎖住「範圍沒有擴大」。

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter ContractNoteManagerRegistrationNote1Tests`
Expected: FAIL — `note15Exists`：找不到 uniqueCode "15"。

Run: `swift test --filter ContractNoteManagerRegistrationNote2Tests`
Expected: FAIL — `note3ExpandedExclusions`：目前內容不含「投審司」「動資查核」「工廠及特許項目」。

Run: `swift test --filter MasterTemplateTests`
Expected: `letterContentOmitsYouGuan` FAIL（目前 `letter.content` 含「有關」）；`onlyLetterContentChanged` PASS（其餘三處目前皆含「有關」，屬於「先確認現況」的基準測試，不會因本次改動而變動）。

- [ ] **Step 3: Write minimal implementation**

**備註一（新增）**：`Sources/QuotingContentManager/ContractNoteManager.swift`，在 `notes` 陣列最後一筆（`uniqueCode: "14"`）之後加：

```swift
        .init(uniqueCode: "15", traits: ["ServiceItem/CompanyRegistration"], weight: 67, content: """
        工商登記處理作業：\(TemplateVariableConcept.organizationTypeName.placeholder())、資本額\(TemplateVariableConcept.paidInCapital.placeholder(variant: "exact"))\(TemplateVariableConcept.registeredCapital.placeholder(variant: "exact"))、\(TemplateVariableConcept.companyRegistrationRegion.placeholder())、\(TemplateVariableConcept.companyRegistrationShareholder.placeholder())。
        """),
```

**備註二（擴充）**：同檔 `uniqueCode: "3"` 的 content 第一行，從：

```
工商登記費用不包含政府規費及代墊雜項費用，服務公費及代墊費用請於辦理完成時支付。
```

改為：

```
工商登記費用不包含政府規費、投審司（外國人）、動資查核、工廠及特許項目之登記及代墊之什項費用(依其收據請款)，服務公費及代墊費用請於辦理完成時支付。
```

第二行（`如股東超過5人，第6位起每位加收新台幣500元之防制洗錢查核費。`）不動。

**母版文案**：`Sources/QuotingContentManager/QuotingContentManager.swift:141`，`letter` 屬性的 `content` 參數，從：

```swift
content: "茲將附上\(TemplateVariableConcept.quotingCaseName.placeholder())有關\(TemplateVariableConcept.serviceItemNames.placeholder())之專業服務公費報價單。\n我們希望以最專業多元的服務與 貴公司長久配合，公費內容若經確認，煩請將最後一頁同意函簽章並回覆至敝事務所，謝謝您的合作。"
```

改為（只刪除「有關」二字，`title` 參數與 `content` 其餘文字、變數皆不動）：

```swift
content: "茲將附上\(TemplateVariableConcept.quotingCaseName.placeholder())\(TemplateVariableConcept.serviceItemNames.placeholder())之專業服務公費報價單。\n我們希望以最專業多元的服務與 貴公司長久配合，公費內容若經確認，煩請將最後一頁同意函簽章並回覆至敝事務所，謝謝您的合作。"
```

`letter.title`（同 `.init` 的 `title:` 參數）、`contractHeader`、`purpose` 三個屬性不動。

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter ContractNoteManagerRegistrationNote1Tests`
Run: `swift test --filter ContractNoteManagerRegistrationNote2Tests`
Run: `swift test --filter MasterTemplateTests`
Expected: 全部 PASS。

- [ ] **Step 5: Run full test suite**

Run: `swift test`
Expected: 全綠。特別確認既有依賴備註 3 內容字串做精確比對的測試（若有）已同步更新，而非因字串變長而漏改導致誤判斷。

- [ ] **Step 6: Commit**

```bash
git add Sources/QuotingContentManager/ContractNoteManager.swift Sources/QuotingContentManager/QuotingContentManager.swift Tests/QuotingContentManagerTests/
git commit -m "[ADD] 工商登記備註一（案件描述，範本變數組成）＋備註二擴充＋母版文案去「有關」"
```

---

## Self-Review 紀錄

- **Spec coverage**：spec §4.1→Task 1；§4.3→Task 2；§4.4/§4.5/§4.6→Task 3。§5（括號變體）不屬本計畫——那是 OC 側求值改動，另一份 plan（OC）處理，本計畫只負責 QCM 詞彙定義本身（本次未新增任何帶括號/不帶括號的 variant key，因為 QCM 層不編碼格式差異，只有 concept 名稱）。§9 QCM 測試項目全數對應到三個 task。§10 前置依賴已在 Global Constraints 註明。
- **Placeholder scan**：Step 1 測試若既有檔案不存在時的檔名判斷（Task 2/3）留了條件分支給執行者現場確認，但兩種分支的完整程式碼都已給出，不是「待補」。
- **Type consistency**：`TemplateVariableConcept.organizationTypeName` 在 Task 2 定義、Task 3 消費，命名一致；`ContractNoteInfo` 建構參數與既有筆數風格（`uniqueCode`/`traits`/`weight`/`content`）一致。
