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
