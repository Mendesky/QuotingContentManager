import Testing
@testable import QuotingContentManager

@Suite("ServiceItem.companyRegistration(for:) 資本額段")
struct CompanyRegistrationNameTests {

    private func template(for type: OrganizationType) -> String {
        ServiceItem.companyRegistration(for: type).paymentItemNameFormat?.template ?? ""
    }

    @Test("股份有限公司模板含 %PaidInCapital|exact%(實收)")
    func sharesContainsPaidIn() {
        #expect(template(for: .companyLimitedByShares).contains("%PaidInCapital|exact%"))
    }

    @Test("有限公司、獨資合夥模板含 %RegisteredCapital|exact%(登記)", arguments: [
        OrganizationType.limitedCompany,
        .soleProprietorshipOrPartnership,
    ])
    func registeredTypesContainPlaceholder(_ type: OrganizationType) {
        #expect(template(for: type).contains("%RegisteredCapital|exact%"))
    }

    @Test("無資本額型態不含任何資本額 placeholder", arguments: [
        OrganizationType.nonProfitOrganization,
        .professionalPracticeIncome,
        .foreignCompany,
    ])
    func noCapitalTypesOmitPlaceholder(_ type: OrganizationType) {
        let t = template(for: type)
        #expect(!t.contains("%PaidInCapital"))
        #expect(!t.contains("%RegisteredCapital"))
    }

    @Test("所有型態保留動資查核與區域、股東段", arguments: OrganizationType.allCases)
    func retainsOtherSegments(_ type: OrganizationType) {
        let t = template(for: type)
        #expect(t.contains("(不含動資查核)"))
        #expect(t.contains("%CompanyRegistrationRegion%"))
        #expect(t.contains("%CompanyRegistrationShareholder%"))
    }

    @Test("目錄版(無參數)預設採股份有限公司情境(實收資本額)")
    func catalogVersionDefaultsToShares() {
        let catalog = ServiceItem.companyRegistration.paymentItemNameFormat?.template
        let shares = ServiceItem.companyRegistration(for: .companyLimitedByShares).paymentItemNameFormat?.template
        #expect(catalog == shares)
        #expect(catalog?.contains("%PaidInCapital|exact%") == true)
    }
}

@Suite("QuotingContentManager.companyRegistration(for:)")
struct ManagerCompanyRegistrationTests {

    @Test("manager 對無資本額型態回傳省略資本額的模板")
    func managerOmitsForNoCapital() {
        let item = QuotingContentManager.standard.companyRegistration(for: .nonProfitOrganization)
        let t = item.paymentItemNameFormat?.template ?? ""
        #expect(!t.contains("%PaidInCapital"))
        #expect(!t.contains("%RegisteredCapital"))
    }

    @Test("manager 對股份回傳實收、對有限回傳登記")
    func managerTypeAware() {
        let shares = QuotingContentManager.standard.companyRegistration(for: .companyLimitedByShares)
        #expect(shares.paymentItemNameFormat?.template.contains("%PaidInCapital|exact%") == true)
        let limited = QuotingContentManager.standard.companyRegistration(for: .limitedCompany)
        #expect(limited.paymentItemNameFormat?.template.contains("%RegisteredCapital|exact%") == true)
    }
}
