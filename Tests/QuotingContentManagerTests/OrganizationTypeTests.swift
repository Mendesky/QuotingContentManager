import Testing
@testable import QuotingContentManager

@Suite("OrganizationType.capitalPlaceholderKey")
struct OrganizationTypeTests {

    @Test("股份有限公司 → PaidInCapital(實收)")
    func sharesUsesPaidIn() {
        #expect(OrganizationType.companyLimitedByShares.capitalPlaceholderKey == "PaidInCapital")
    }

    @Test("有限公司、獨資合夥 → RegisteredCapital(登記)")
    func limitedAndSoleUseRegistered() {
        #expect(OrganizationType.limitedCompany.capitalPlaceholderKey == "RegisteredCapital")
        #expect(OrganizationType.soleProprietorshipOrPartnership.capitalPlaceholderKey == "RegisteredCapital")
    }

    @Test("非營利、執行業務所得、境外公司 → 無資本額(nil)")
    func noCapitalTypesNil() {
        #expect(OrganizationType.nonProfitOrganization.capitalPlaceholderKey == nil)
        #expect(OrganizationType.professionalPracticeIncome.capitalPlaceholderKey == nil)
        #expect(OrganizationType.foreignCompany.capitalPlaceholderKey == nil)
    }

    @Test("每個型態的 capitalPlaceholderKey 都落在已知集合(nil / PaidInCapital / RegisteredCapital)")
    func capitalKeysAreKnown() {
        let known: Set<String> = ["PaidInCapital", "RegisteredCapital"]
        for type in OrganizationType.allCases {
            if let key = type.capitalPlaceholderKey {
                #expect(known.contains(key), "未知的 capitalPlaceholderKey: \(key)(\(type))")
            }
        }
    }
}
