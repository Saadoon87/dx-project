/**
 * UlsCalculatorDtoTest
 *
 * Purpose:
 * - Provides direct coverage for DTO request/response wrappers.
 * - Verifies DTO fields can be assigned and read safely.
 * - Does not perform DML.
 * - Does not perform HTTP callouts.
 */
@IsTest
private class UlsCalculatorDtoTest {
  @IsTest
  static void dtoFields_canBeAssignedAndRead() {
    UlsCalculatorDto.ApiError apiError = new UlsCalculatorDto.ApiError();
    apiError.errorCode = 'TEST_ERROR';
    apiError.message = 'Test message';

    UlsCalculatorDto.Benefit benefit = new UlsCalculatorDto.Benefit();
    benefit.name = 'Life Cover';
    benefit.amount = 100000;
    benefit.description = 'Base benefit';

    UlsCalculatorDto.InvestmentFund investmentFund = new UlsCalculatorDto.InvestmentFund();
    investmentFund.fundId = 'FUND-001';
    investmentFund.fundName = 'Active Fund';
    investmentFund.allocationPercentage = 100;
    investmentFund.currentValue = 50000;

    UlsCalculatorDto.PolicyResponse policy = new UlsCalculatorDto.PolicyResponse();
    policy.policyNumber = '8000082';
    policy.productName = 'NEW ULS - Dreams';
    policy.issuanceDate = '08/06/2026';
    policy.maturityDate = '08/06/2039';
    policy.frequency = 'Monthly';
    policy.initialPremium = 2500;
    policy.currentPremium = 2500;
    policy.missedPremiums = 0;
    policy.currentUav = 50000;
    policy.totalPaidPremiums = 10000;
    policy.customerName = 'Test Customer';
    policy.ageGender = '25 / M';
    policy.lifeInsuredAge = 25;
    policy.lifeInsuredGender = 'M';
    policy.lifeInsuredDOB = '20/04/2001';
    policy.insuredDob = '20/04/2001';
    policy.childDob = '01/01/2015';
    policy.investmentStrategy = 'Balanced';
    policy.benefits = new List<UlsCalculatorDto.Benefit>{ benefit };
    policy.investmentFunds = new List<UlsCalculatorDto.InvestmentFund>{
      investmentFund
    };

    UlsCalculatorDto.ApiResponse apiResponse = new UlsCalculatorDto.ApiResponse();
    apiResponse.success = true;
    apiResponse.data = policy;
    apiResponse.errorCode = null;
    apiResponse.userMessage = null;
    apiResponse.correlationId = 'TEST-CORR-DTO-001';
    apiResponse.supportDetails = 'Safe support details';

    UlsCalculatorDto.BackendPolicyResponse backendPolicy = new UlsCalculatorDto.BackendPolicyResponse();
    backendPolicy.policyNumber = '8000082';
    backendPolicy.productName = 'Backend Product';
    backendPolicy.issuanceDate = '08/06/2026';
    backendPolicy.maturityDate = '08/06/2039';
    backendPolicy.frequency = 'Monthly';
    backendPolicy.initialPremium = 2500;
    backendPolicy.currentPremium = 2500;
    backendPolicy.missedPremiums = 0;
    backendPolicy.currentUAV = 50000;
    backendPolicy.totalPaidPremiums = 10000;
    backendPolicy.customerName = 'Backend Customer';
    backendPolicy.lifeInsuredName = 'Life Insured';
    backendPolicy.lifeInsuredDOB = '20/04/2001';
    backendPolicy.lifeInsuredAge = 25;
    backendPolicy.lifeInsuredGender = 'M';
    backendPolicy.nominatedChildDOB = '01/01/2015';
    backendPolicy.childDOB = '01/01/2015';
    backendPolicy.investmentStrategy = 'Balanced';

    UlsCalculatorDto.BackendBenefit backendBenefit = new UlsCalculatorDto.BackendBenefit();
    backendBenefit.benefitName = 'Accidental Death Insurance';
    backendBenefit.totalSumInsured = 450000;
    backendBenefit.description = 'Backend benefit';

    UlsCalculatorDto.BackendInvestmentFund backendInvestmentFund = new UlsCalculatorDto.BackendInvestmentFund();
    backendInvestmentFund.fundCode = 'ACTIVE';
    backendInvestmentFund.fundId = 'FUND-ACTIVE';
    backendInvestmentFund.fundName = 'Active Fund';
    backendInvestmentFund.nameEn = 'Active Fund EN';
    backendInvestmentFund.nameAr = 'Active Fund AR';
    backendInvestmentFund.percentage = 100;
    backendInvestmentFund.allocationPercentage = 100;
    backendInvestmentFund.currentValue = 50000;

    backendPolicy.benefits = new List<UlsCalculatorDto.BackendBenefit>{
      backendBenefit
    };
    backendPolicy.investmentFunds = new List<UlsCalculatorDto.BackendInvestmentFund>{
      backendInvestmentFund
    };

    UlsCalculatorDto.BackendFundOption backendFundOption = new UlsCalculatorDto.BackendFundOption();
    backendFundOption.fundId = 'FUND-ACTIVE';
    backendFundOption.fundCode = 'ACTIVE';
    backendFundOption.fundName = 'Active Fund';
    backendFundOption.nameEn = 'Active Fund EN';
    backendFundOption.nameAr = 'Active Fund AR';
    backendFundOption.lowReturnRate = 3.5;
    backendFundOption.highReturnRate = 7.5;

    UlsCalculatorDto.BackendFundsResponse backendFunds = new UlsCalculatorDto.BackendFundsResponse();
    backendFunds.funds = new List<UlsCalculatorDto.BackendFundOption>{
      backendFundOption
    };

    UlsCalculatorDto.BackendTermExtensionOptionsResponse backendTermOptions = new UlsCalculatorDto.BackendTermExtensionOptionsResponse();
    backendTermOptions.policyNumber = '8000082';
    backendTermOptions.availableExtensions = new List<Integer>{ 5, 10 };
    backendTermOptions.options = new List<Integer>{ 15 };

    UlsCalculatorDto.BackendDocumentResponse backendDocument = new UlsCalculatorDto.BackendDocumentResponse();
    backendDocument.documentId = 'DOC-001';
    backendDocument.downloadUrl = 'https://example.invalid/document';
    backendDocument.emailedToClient = true;
    backendDocument.statusMessage = 'Generated';
    backendDocument.fileName = 'projection.pdf';

    UlsCalculatorDto.InflationRateResponse inflationRate = new UlsCalculatorDto.InflationRateResponse();
    inflationRate.inflationRate = 5.0;

    UlsCalculatorDto.InflationAdjustedUavRequest inflationRequest = new UlsCalculatorDto.InflationAdjustedUavRequest();
    inflationRequest.policyNumber = '8000082';
    inflationRequest.initialUAV = 100000;

    UlsCalculatorDto.InflationAdjustedUavResponse inflationResponse = new UlsCalculatorDto.InflationAdjustedUavResponse();
    inflationResponse.policyNumber = '8000082';
    inflationResponse.initialUAV = 100000;
    inflationResponse.inflationRate = 5.0;
    inflationResponse.remainingYears = 10;
    inflationResponse.inflationAdjustedAmount = 162889.46;

    UlsCalculatorDto.SuggestedPremiumRequest suggestedPremiumRequest = new UlsCalculatorDto.SuggestedPremiumRequest();
    suggestedPremiumRequest.policyNumber = '8000082';
    suggestedPremiumRequest.targetFinalUAV = 250000;

    UlsCalculatorDto.SuggestedPremiumResponse suggestedPremiumResponse = new UlsCalculatorDto.SuggestedPremiumResponse();
    suggestedPremiumResponse.policyNumber = '8000082';
    suggestedPremiumResponse.targetFinalUAV = 250000;
    suggestedPremiumResponse.suggestedPremium = 3500;
    suggestedPremiumResponse.currentPremium = 1000;
    suggestedPremiumResponse.difference = 2500;

    UlsCalculatorDto.FinalUavRequest finalUavRequest = new UlsCalculatorDto.FinalUavRequest();
    finalUavRequest.policyNumber = '8000082';
    finalUavRequest.requestedPremium = 3000;

    UlsCalculatorDto.FinalUavResponse finalUavResponse = new UlsCalculatorDto.FinalUavResponse();
    finalUavResponse.policyNumber = '8000082';
    finalUavResponse.requestedPremium = 3000;
    finalUavResponse.currentPremium = 1000;
    finalUavResponse.difference = 2000;
    finalUavResponse.projectedFinalUAV = 225000;

    UlsCalculatorDto.FundOption fundOption = new UlsCalculatorDto.FundOption();
    fundOption.fundId = 'FUND-ACTIVE';
    fundOption.fundName = 'Active Fund';
    fundOption.lowReturnRate = 3.5;
    fundOption.highReturnRate = 7.5;

    UlsCalculatorDto.FundsResponse fundsResponse = new UlsCalculatorDto.FundsResponse();
    fundsResponse.funds = new List<UlsCalculatorDto.FundOption>{ fundOption };

    UlsCalculatorDto.TermExtensionOptionsResponse termOptions = new UlsCalculatorDto.TermExtensionOptionsResponse();
    termOptions.policyNumber = '8000082';
    termOptions.options = new List<Integer>{ 5, 10, 15 };

    UlsCalculatorDto.FundAllocation allocation = new UlsCalculatorDto.FundAllocation();
    allocation.fundId = 'FUND-ACTIVE';
    allocation.fundName = 'Active Fund';
    allocation.allocationPercentage = 100;

    UlsCalculatorDto.FundSwitch fundSwitch = new UlsCalculatorDto.FundSwitch();
    fundSwitch.enabled = true;
    fundSwitch.allocations = new List<UlsCalculatorDto.FundAllocation>{
      allocation
    };

    UlsCalculatorDto.Asp asp = new UlsCalculatorDto.Asp();
    asp.enabled = true;
    asp.amount = 10000;
    asp.fundId = 'FUND-ACTIVE';
    asp.fundName = 'Active Fund';

    UlsCalculatorDto.PremiumRedirection premiumRedirection = new UlsCalculatorDto.PremiumRedirection();
    premiumRedirection.enabled = true;
    premiumRedirection.allocations = new List<UlsCalculatorDto.FundAllocation>{
      allocation
    };

    UlsCalculatorDto.PremiumChange premiumChange = new UlsCalculatorDto.PremiumChange();
    premiumChange.enabled = true;
    premiumChange.requestedPremium = 3000;

    UlsCalculatorDto.TermExtension termExtension = new UlsCalculatorDto.TermExtension();
    termExtension.enabled = true;
    termExtension.selectedTerm = 10;

    UlsCalculatorDto.AlterationRequest alteration = new UlsCalculatorDto.AlterationRequest();
    alteration.policyNumber = '8000082';
    alteration.fundSwitch = fundSwitch;
    alteration.asp = asp;
    alteration.premiumRedirection = premiumRedirection;
    alteration.premiumChange = premiumChange;
    alteration.termExtension = termExtension;

    UlsCalculatorDto.PersonalInfo personalInfo = new UlsCalculatorDto.PersonalInfo();
    personalInfo.customerName = 'Test Customer';
    personalInfo.policyNumber = '8000082';
    personalInfo.ageGender = '25 / M';
    personalInfo.insuredDob = '20/04/2001';
    personalInfo.childDob = '01/01/2015';

    UlsCalculatorDto.QuotationInfo quotationInfo = new UlsCalculatorDto.QuotationInfo();
    quotationInfo.maturityDate = '08/06/2039';
    quotationInfo.frequency = 'Monthly';
    quotationInfo.projectionDate = '30/06/2026';

    UlsCalculatorDto.PremiumsAndAllocations premiums = new UlsCalculatorDto.PremiumsAndAllocations();
    premiums.initialPremium = 2500;
    premiums.currentPremium = 2500;
    premiums.requestedPremium = 3000;
    premiums.totalPaidPremiums = 10000;
    premiums.missedPremiums = 0;

    UlsCalculatorDto.InsuranceBenefit insuranceBenefit = new UlsCalculatorDto.InsuranceBenefit();
    insuranceBenefit.name = 'Life Cover';
    insuranceBenefit.amount = 450000;
    insuranceBenefit.description = 'Projection benefit';

    UlsCalculatorDto.ProjectionRow projectionRow = new UlsCalculatorDto.ProjectionRow();
    projectionRow.year = 2030;
    projectionRow.policyYear = 4;
    projectionRow.premium = 3000;
    projectionRow.totalPaidPremiums = 36000;
    projectionRow.lowUav = 100000;
    projectionRow.highUav = 125000;
    projectionRow.benefits = 450000;

    UlsCalculatorDto.ProjectionResponse projection = new UlsCalculatorDto.ProjectionResponse();
    projection.personalInfo = personalInfo;
    projection.quotationInfo = quotationInfo;
    projection.premiumsAndAllocations = premiums;
    projection.insuranceBenefits = new List<UlsCalculatorDto.InsuranceBenefit>{
      insuranceBenefit
    };
    projection.projectionRows = new List<UlsCalculatorDto.ProjectionRow>{
      projectionRow
    };

    UlsCalculatorDto.AttachmentOption attachment = new UlsCalculatorDto.AttachmentOption();
    attachment.attachmentId = 'ATT-001';
    attachment.label = 'Client Consent';
    attachment.description = 'Required consent form';
    attachment.mandatory = true;

    UlsCalculatorDto.AttachmentsResponse attachments = new UlsCalculatorDto.AttachmentsResponse();
    attachments.attachments = new List<UlsCalculatorDto.AttachmentOption>{
      attachment
    };

    UlsCalculatorDto.ProjectionPdfRequest projectionPdfRequest = new UlsCalculatorDto.ProjectionPdfRequest();
    projectionPdfRequest.policyNumber = '8000082';
    projectionPdfRequest.projection = projection;

    UlsCalculatorDto.FinalPdfRequest finalPdfRequest = new UlsCalculatorDto.FinalPdfRequest();
    finalPdfRequest.policyNumber = '8000082';
    finalPdfRequest.selectedAttachmentIds = new List<String>{ 'ATT-001' };
    finalPdfRequest.includeProjectionPdf = true;
    finalPdfRequest.includeAlterationForms = true;
    finalPdfRequest.alterationRequest = alteration;

    UlsCalculatorDto.DocumentResponse documentResponse = new UlsCalculatorDto.DocumentResponse();
    documentResponse.documentId = 'DOC-001';
    documentResponse.downloadUrl = 'https://example.invalid/document';
    documentResponse.emailedToClient = true;
    documentResponse.statusMessage = 'Generated';

    System.Assert.areEqual('TEST_ERROR', apiError.errorCode);
    System.Assert.areEqual(true, apiResponse.success);
    System.Assert.areEqual('8000082', policy.policyNumber);
    System.Assert.areEqual(1, policy.benefits.size());
    System.Assert.areEqual(1, policy.investmentFunds.size());
    System.Assert.areEqual('8000082', backendPolicy.policyNumber);
    System.Assert.areEqual(1, backendFunds.funds.size());
    System.Assert.areEqual(2, backendTermOptions.availableExtensions.size());
    System.Assert.areEqual('DOC-001', backendDocument.documentId);
    System.Assert.areEqual(5.0, inflationRate.inflationRate);
    System.Assert.areEqual(100000, inflationRequest.initialUAV);
    System.Assert.areEqual(
      162889.46,
      inflationResponse.inflationAdjustedAmount
    );
    System.Assert.areEqual(250000, suggestedPremiumRequest.targetFinalUAV);
    System.Assert.areEqual(3500, suggestedPremiumResponse.suggestedPremium);
    System.Assert.areEqual(3000, finalUavRequest.requestedPremium);
    System.Assert.areEqual(225000, finalUavResponse.projectedFinalUAV);
    System.Assert.areEqual(1, fundsResponse.funds.size());
    System.Assert.areEqual(3, termOptions.options.size());
    System.Assert.areEqual(true, alteration.fundSwitch.enabled);
    System.Assert.areEqual(true, alteration.asp.enabled);
    System.Assert.areEqual(true, alteration.premiumRedirection.enabled);
    System.Assert.areEqual(true, alteration.premiumChange.enabled);
    System.Assert.areEqual(true, alteration.termExtension.enabled);
    System.Assert.areEqual(
      'Test Customer',
      projection.personalInfo.customerName
    );
    System.Assert.areEqual(1, projection.insuranceBenefits.size());
    System.Assert.areEqual(1, projection.projectionRows.size());
    System.Assert.areEqual(1, attachments.attachments.size());
    System.Assert.areEqual('8000082', projectionPdfRequest.policyNumber);
    System.Assert.areEqual(true, finalPdfRequest.includeProjectionPdf);
    System.Assert.areEqual('DOC-001', documentResponse.documentId);
  }
}
