/**
 * DTO "Data Transfer Object" class for the ULS Calculator feature.
 * This class contains request and response shapes used between:
 * - LWC
 * - Apex Controller
 * - Apex Service
 * - Backend response mapping
 * This class must not contain business logic.
 * This class must not perform HTTP callouts.
 * This class must not perform DML.
 */
public with sharing class UlsCalculatorDto {
  /**
   * Standard response wrapper returned to the LWC.
   *
   * Every controller method should return this shape so the UI can handle
   * success, failure, safe messages, and correlation IDs consistently.
   */
  public class ApiResponse {
    // Tells the LWC whether the operation succeeded.
    @AuraEnabled
    public Boolean success { get; set; }

    // Holds the successful response data.
    // The actual object depends on the operation.
    @AuraEnabled
    public Object data { get; set; }

    // Holds a safe application/backend error code when success is false.
    @AuraEnabled
    public String errorCode { get; set; }

    // Holds a user-safe message that can be displayed in the LWC.
    @AuraEnabled
    public String userMessage { get; set; }

    // Holds the support correlation ID for tracing logs.
    @AuraEnabled
    public String correlationId { get; set; }

    // Holds optional sanitized support details.
    // This must never contain tokens, secrets, raw backend payloads, or PII.
    @AuraEnabled
    public String supportDetails { get; set; }
  }

  /**
   * Standard backend error shape based on the API document.
   */
  public class ApiError {
    // Backend or Salesforce-safe error code.
    @AuraEnabled
    public String errorCode { get; set; }

    // Backend message or sanitized Salesforce message.
    @AuraEnabled
    public String message { get; set; }
  }

  /**
   * Policy retrieval response.
   *
   * Fields here are based on the BRD/prototype/API summary.
   * Exact backend mapping can be adjusted later if backend field names differ.
   */
  public class PolicyResponse {
    // Policy number retrieved from backend.
    @AuraEnabled
    public String policyNumber { get; set; }

    // Product name returned by backend.
    @AuraEnabled
    public String productName { get; set; }

    // Policy issuance date returned by backend.
    @AuraEnabled
    public String issuanceDate { get; set; }

    // Policy maturity date as a string to avoid date-format assumptions.
    @AuraEnabled
    public String maturityDate { get; set; }

    // Payment frequency, for example Monthly/Quarterly/Annual.
    @AuraEnabled
    public String frequency { get; set; }

    // Initial premium returned by backend.
    @AuraEnabled
    public Decimal initialPremium { get; set; }

    // Current premium returned by backend.
    @AuraEnabled
    public Decimal currentPremium { get; set; }

    // Missed premium amount/count as returned by backend.
    @AuraEnabled
    public Decimal missedPremiums { get; set; }

    // Current UAV value returned by backend.
    @AuraEnabled
    public Decimal currentUav { get; set; }

    // Total paid premiums returned by backend.
    @AuraEnabled
    public Decimal totalPaidPremiums { get; set; }

    // Customer name if returned by backend.
    @AuraEnabled
    public String customerName { get; set; }

    // Age/gender display value if returned by backend.
    @AuraEnabled
    public String ageGender { get; set; }

    // Life insured age shown separately in the AXA-aligned Step 2 UI.
    @AuraEnabled
    public Integer lifeInsuredAge { get; set; }

    // Life insured gender shown separately in the AXA-aligned Step 2 UI.
    @AuraEnabled
    public String lifeInsuredGender { get; set; }

    // Life insured DOB shown separately in the AXA-aligned Step 2 UI.
    @AuraEnabled
    public String lifeInsuredDOB { get; set; }

    // Insured DOB as a string to avoid date-format assumptions.
    @AuraEnabled
    public String insuredDob { get; set; }

    // Child DOB if applicable, as a string.
    @AuraEnabled
    public String childDob { get; set; }

    // Investment strategy description if returned by backend.
    @AuraEnabled
    public String investmentStrategy { get; set; }

    // Benefits returned by backend.
    @AuraEnabled
    public List<Benefit> benefits { get; set; }

    // Current investment funds returned by backend.
    @AuraEnabled
    public List<InvestmentFund> investmentFunds { get; set; }
  }

  /**
   * Current policy benefit summary.
   */
  public class Benefit {
    // Benefit name.
    @AuraEnabled
    public String name { get; set; }

    // Benefit amount.
    @AuraEnabled
    public Decimal amount { get; set; }

    // Optional benefit description.
    @AuraEnabled
    public String description { get; set; }
  }

  /**
   * Current investment fund allocation on the policy.
   */
  public class InvestmentFund {
    // Fund identifier from backend.
    @AuraEnabled
    public String fundId { get; set; }

    // Fund display name.
    @AuraEnabled
    public String fundName { get; set; }

    // Allocation percentage.
    @AuraEnabled
    public Decimal allocationPercentage { get; set; }

    // Current fund value if returned by backend.
    @AuraEnabled
    public Decimal currentValue { get; set; }
  }

  // =====================================================================================
  // Backend response DTOs
  // =====================================================================================

  /**
   * Raw backend policy response.
   *
   * Important:
   * - This class represents backend JSON naming.
   * - This class should not be returned directly to the LWC.
   * - UlsCalculatorService maps this into PolicyResponse.
   */
  public class BackendPolicyResponse {
    // Policy number returned by backend.
    public String policyNumber;

    // Product name returned by backend.
    public String productName;

    // Issuance date returned by backend.
    public String issuanceDate;

    // Maturity date returned by backend.
    public String maturityDate;

    // Payment frequency returned by backend.
    public String frequency;

    // Initial premium returned by backend.
    public Decimal initialPremium;

    // Current premium returned by backend.
    public Decimal currentPremium;

    // Missed premiums returned by backend.
    public Decimal missedPremiums;

    // Backend may use currentUAV with capital UAV.
    public Decimal currentUAV;

    // Total paid premiums returned by backend.
    public Decimal totalPaidPremiums;

    // Optional customer name if backend sends it directly.
    public String customerName;

    // Backend may use life insured naming.
    public String lifeInsuredName;

    // Backend may use lifeInsuredDOB.
    public String lifeInsuredDOB;

    // Backend may send life insured age separately.
    public Integer lifeInsuredAge;

    // Backend may send life insured gender separately.
    public String lifeInsuredGender;

    // Backend may send nominated child DOB if applicable.
    public String nominatedChildDOB;

    // Older/alternate child DOB field name if backend sends it.
    public String childDOB;

    // Investment strategy returned by backend.
    public String investmentStrategy;

    // Benefits returned by backend.
    public List<BackendBenefit> benefits;

    // Backend investment fund allocation list.
    public List<BackendInvestmentFund> investmentFunds;
  }

  /**
   * Raw backend benefit item.
   */
  public class BackendBenefit {
    // Benefit name returned by backend.
    public String benefitName;

    // Total sum insured returned by backend.
    public Decimal totalSumInsured;

    // Optional description if backend sends it.
    public String description;
  }

  /**
   * Raw backend investment fund allocation.
   */
  public class BackendInvestmentFund {
    // Backend may send fundCode.
    public String fundCode;

    // Backend may also send fundId.
    public String fundId;

    // Backend may send an already-built fund name.
    public String fundName;

    // English display name.
    public String nameEn;

    // Arabic display name.
    public String nameAr;

    // Allocation percentage returned by retrieve-policy API.
    public Decimal percentage;

    // Alternate allocation percentage field name.
    public Decimal allocationPercentage;

    // Current fund value.
    public Decimal currentValue;
  }

  /**
   * Raw backend funds response.
   */
  public class BackendFundsResponse {
    // Current backend response root for available funds.
    public List<BackendFundOption> investmentFundTypesAndRatesByCurrencyId;

    // Older/sandbox response root kept as a safe fallback.
    public List<BackendFundOption> funds;
  }

  /**
   * Raw backend fund option.
   */
  public class BackendFundOption {
    // Current backend numeric fund identifier.
    public Integer id;

    // Current backend fund display name.
    public String name;

    // Current backend lower return rate.
    public Decimal lowerRate;

    // Current backend central return rate.
    public Decimal centralRate;

    // Current backend upper return rate.
    public Decimal upperRate;

    // Older backend may send fundCode.
    public String fundCode;

    // Older backend may also send fundId.
    public String fundId;

    // Older backend may send an already-built fund name.
    public String fundName;

    // Older English display name.
    public String nameEn;

    // Older Arabic display name.
    public String nameAr;

    // Older low return rate field.
    public Decimal lowReturnRate;

    // Older high return rate field.
    public Decimal highReturnRate;
  }

  /**
   * Raw backend term extension options response.
   */
  public class BackendTermExtensionOptionsResponse {
    // Policy number.
    public String policyNumber;

    // Backend may use availableExtensions.
    public List<Integer> availableExtensions;

    // Some responses may already use options.
    public List<Integer> options;
  }

  /**
   * Raw backend document response.
   */
  public class BackendDocumentResponse {
    // Backend document/package ID if returned.
    public String documentId;

    // Backend may return a file name.
    public String fileName;

    // Download URL if returned.
    // This must not be logged if it contains sensitive tokens.
    public String downloadUrl;

    // Whether backend emailed the package to the client.
    public Boolean emailedToClient;

    // Backend status message if returned.
    public String statusMessage;
  }

  /**
   * Inflation rate response.
   */
  public class InflationRateResponse {
    // Current configured annual inflation rate.
    @AuraEnabled
    public Decimal inflationRate { get; set; }
  }

  /**
   * Request for inflation-adjusted UAV.
   */
  public class InflationAdjustedUavRequest {
    // Policy number entered by advisor.
    @AuraEnabled
    public String policyNumber { get; set; }

    // Initial UAV entered or selected by advisor.
    @AuraEnabled
    public Decimal initialUAV { get; set; }
  }

  /**
   * Response for inflation-adjusted UAV.
   */
  public class InflationAdjustedUavResponse {
    // Policy number.
    @AuraEnabled
    public String policyNumber { get; set; }

    // Initial UAV used for calculation.
    @AuraEnabled
    public Decimal initialUAV { get; set; }

    // Inflation rate used by backend.
    @AuraEnabled
    public Decimal inflationRate { get; set; }

    // Remaining years used by backend.
    @AuraEnabled
    public Integer remainingYears { get; set; }

    // Backend-calculated inflation-adjusted amount.
    @AuraEnabled
    public Decimal inflationAdjustedAmount { get; set; }
  }

  /**
   * Request for suggested premium calculation.
   */
  public class SuggestedPremiumRequest {
    // Policy number.
    @AuraEnabled
    public String policyNumber { get; set; }

    // Advisor-requested target final UAV.
    @AuraEnabled
    public Decimal targetFinalUAV { get; set; }
  }

  /**
   * Response for suggested premium calculation.
   */
  public class SuggestedPremiumResponse {
    // Policy number.
    @AuraEnabled
    public String policyNumber { get; set; }

    // Requested target final UAV.
    @AuraEnabled
    public Decimal targetFinalUAV { get; set; }

    // Backend-calculated suggested premium.
    @AuraEnabled
    public Decimal suggestedPremium { get; set; }

    // Current premium returned by backend.
    @AuraEnabled
    public Decimal currentPremium { get; set; }

    // Difference between suggested and current premium.
    @AuraEnabled
    public Decimal difference { get; set; }
  }

  /**
   * Request for recalculating final UAV after advisor premium override.
   */
  public class FinalUavRequest {
    // Policy number.
    @AuraEnabled
    public String policyNumber { get; set; }

    // Advisor-requested premium.
    @AuraEnabled
    public Decimal requestedPremium { get; set; }
  }

  /**
   * Response for recalculated final UAV.
   */
  public class FinalUavResponse {
    // Policy number.
    @AuraEnabled
    public String policyNumber { get; set; }

    // Advisor-requested premium.
    @AuraEnabled
    public Decimal requestedPremium { get; set; }

    // Current premium returned by backend.
    @AuraEnabled
    public Decimal currentPremium { get; set; }

    // Difference between requested and current premium.
    @AuraEnabled
    public Decimal difference { get; set; }

    // Backend-calculated projected final UAV.
    @AuraEnabled
    public Decimal projectedFinalUAV { get; set; }
  }

  /**
   * Funds response.
   */
  public class FundsResponse {
    // Available fund options returned by backend.
    @AuraEnabled
    public List<FundOption> funds { get; set; }
  }

  /**
   * Single fund option.
   */
  public class FundOption {
    // Fund identifier.
    @AuraEnabled
    public String fundId { get; set; }

    // Fund display name.
    @AuraEnabled
    public String fundName { get; set; }

    // Lower return rate returned by backend.
    @AuraEnabled
    public Decimal lowerRate { get; set; }

    // Central return rate returned by backend.
    @AuraEnabled
    public Decimal centralRate { get; set; }

    // Upper return rate returned by backend.
    @AuraEnabled
    public Decimal upperRate { get; set; }

    // Backward-compatible low return rate field.
    @AuraEnabled
    public Decimal lowReturnRate { get; set; }

    // Backward-compatible high return rate field.
    @AuraEnabled
    public Decimal highReturnRate { get; set; }
  }

  /**
   * Term extension options response.
   */
  public class TermExtensionOptionsResponse {
    // Policy number.
    @AuraEnabled
    public String policyNumber { get; set; }

    // Backend-prefiltered valid term extension options.
    @AuraEnabled
    public List<Integer> options { get; set; }
  }

  /**
   * Full alteration/projection request.
   */
  public class AlterationRequest {
    // Policy number.
    @AuraEnabled
    public String policyNumber { get; set; }

    // Fund switching section.
    @AuraEnabled
    public FundSwitch fundSwitch { get; set; }

    // ASP section.
    @AuraEnabled
    public Asp asp { get; set; }

    // Premium redirection section.
    @AuraEnabled
    public PremiumRedirection premiumRedirection { get; set; }

    // Regular premium change section.
    @AuraEnabled
    public PremiumChange premiumChange { get; set; }

    // Term extension section.
    @AuraEnabled
    public TermExtension termExtension { get; set; }
  }

  /**
   * Fund switching alteration.
   */
  public class FundSwitch {
    // Whether this alteration is enabled.
    @AuraEnabled
    public Boolean enabled { get; set; }

    // New fund allocations.
    @AuraEnabled
    public List<FundAllocation> allocations { get; set; }
  }

  /**
   * Shared fund allocation shape.
   */
  public class FundAllocation {
    // Selected fund ID.
    @AuraEnabled
    public String fundId { get; set; }

    // Selected fund name, useful for display/review.
    @AuraEnabled
    public String fundName { get; set; }

    // Allocation percentage.
    @AuraEnabled
    public Decimal allocationPercentage { get; set; }
  }

  /**
   * Additional Single Premium alteration.
   */
  public class Asp {
    // Whether ASP is enabled.
    @AuraEnabled
    public Boolean enabled { get; set; }

    // ASP amount.
    @AuraEnabled
    public Decimal amount { get; set; }

    // Selected fund ID.
    @AuraEnabled
    public String fundId { get; set; }

    // Selected fund name, useful for display/review.
    @AuraEnabled
    public String fundName { get; set; }
  }

  /**
   * Future premium redirection alteration.
   */
  public class PremiumRedirection {
    // Whether premium redirection is enabled.
    @AuraEnabled
    public Boolean enabled { get; set; }

    // New premium redirection allocations.
    @AuraEnabled
    public List<FundAllocation> allocations { get; set; }
  }

  /**
   * Regular premium change alteration.
   */
  public class PremiumChange {
    // Whether premium change is enabled.
    @AuraEnabled
    public Boolean enabled { get; set; }

    // Requested new premium.
    @AuraEnabled
    public Decimal requestedPremium { get; set; }
  }

  /**
   * Term extension alteration.
   */
  public class TermExtension {
    // Whether term extension is enabled.
    @AuraEnabled
    public Boolean enabled { get; set; }

    // Selected backend-approved extension value.
    @AuraEnabled
    public Integer selectedTerm { get; set; }
  }

  /**
   * Projection response.
   */
  public class ProjectionResponse {
    // Personal information block for review screen.
    @AuraEnabled
    public PersonalInfo personalInfo { get; set; }

    // Quotation information block for review screen.
    @AuraEnabled
    public QuotationInfo quotationInfo { get; set; }

    // Premium/allocation summary.
    @AuraEnabled
    public PremiumsAndAllocations premiumsAndAllocations { get; set; }

    // Insurance benefit summary.
    @AuraEnabled
    public List<InsuranceBenefit> insuranceBenefits { get; set; }

    // Year-by-year projection rows.
    @AuraEnabled
    public List<ProjectionRow> projectionRows { get; set; }
  }

  /**
   * Personal information shown on review.
   */
  public class PersonalInfo {
    // Customer name if returned.
    @AuraEnabled
    public String customerName { get; set; }

    // Policy number.
    @AuraEnabled
    public String policyNumber { get; set; }

    // Age/gender display value if returned.
    @AuraEnabled
    public String ageGender { get; set; }

    // Insured DOB as display string.
    @AuraEnabled
    public String insuredDob { get; set; }

    // Child DOB as display string if applicable.
    @AuraEnabled
    public String childDob { get; set; }
  }

  /**
   * Quotation information shown on review.
   */
  public class QuotationInfo {
    // Maturity date display value.
    @AuraEnabled
    public String maturityDate { get; set; }

    // Frequency display value.
    @AuraEnabled
    public String frequency { get; set; }

    // Projection creation date if returned.
    @AuraEnabled
    public String projectionDate { get; set; }
  }

  /**
   * Premium and allocation review summary.
   */
  public class PremiumsAndAllocations {
    // Initial premium.
    @AuraEnabled
    public Decimal initialPremium { get; set; }

    // Current premium.
    @AuraEnabled
    public Decimal currentPremium { get; set; }

    // Requested premium.
    @AuraEnabled
    public Decimal requestedPremium { get; set; }

    // Total paid premiums.
    @AuraEnabled
    public Decimal totalPaidPremiums { get; set; }

    // Missed premiums.
    @AuraEnabled
    public Decimal missedPremiums { get; set; }
  }

  /**
   * Insurance benefit summary item.
   */
  public class InsuranceBenefit {
    // Benefit name.
    @AuraEnabled
    public String name { get; set; }

    // Benefit amount.
    @AuraEnabled
    public Decimal amount { get; set; }

    // Optional benefit description.
    @AuraEnabled
    public String description { get; set; }
  }

  /**
   * Projection table row.
   */
  public class ProjectionRow {
    // Projection year.
    @AuraEnabled
    public Integer year { get; set; }

    // Policy age or duration if returned.
    @AuraEnabled
    public Integer policyYear { get; set; }

    // Premium amount for the row.
    @AuraEnabled
    public Decimal premium { get; set; }

    // Total paid premiums for the row.
    @AuraEnabled
    public Decimal totalPaidPremiums { get; set; }

    // Low scenario UAV.
    @AuraEnabled
    public Decimal lowUav { get; set; }

    // High scenario UAV.
    @AuraEnabled
    public Decimal highUav { get; set; }

    // Benefits value if returned.
    @AuraEnabled
    public Decimal benefits { get; set; }
  }

  /**
   * Attachments response.
   */
  public class AttachmentsResponse {
    // Optional attachment templates.
    @AuraEnabled
    public List<AttachmentOption> attachments { get; set; }
  }

  /**
   * Optional attachment template.
   */
  public class AttachmentOption {
    // Attachment/template ID.
    @AuraEnabled
    public String attachmentId { get; set; }

    // Display label.
    @AuraEnabled
    public String label { get; set; }

    // Description if returned.
    @AuraEnabled
    public String description { get; set; }

    // Whether attachment is mandatory.
    @AuraEnabled
    public Boolean mandatory { get; set; }
  }

  /**
   * Projection PDF request.
   */
  public class ProjectionPdfRequest {
    // Policy number.
    @AuraEnabled
    public String policyNumber { get; set; }

    // Projection data shown on screen.
    @AuraEnabled
    public ProjectionResponse projection { get; set; }
  }

  /**
   * Final PDF/package request.
   */
  public class FinalPdfRequest {
    // Policy number.
    @AuraEnabled
    public String policyNumber { get; set; }

    // Selected attachment IDs.
    @AuraEnabled
    public List<String> selectedAttachmentIds { get; set; }

    // Whether projection PDF should be included.
    @AuraEnabled
    public Boolean includeProjectionPdf { get; set; }

    // Whether alteration forms should be included.
    @AuraEnabled
    public Boolean includeAlterationForms { get; set; }

    // Alteration request used for package generation if backend requires it.
    @AuraEnabled
    public AlterationRequest alterationRequest { get; set; }
  }

  /**
   * Backend document response.
   */
  public class DocumentResponse {
    // Backend document/package ID if returned.
    @AuraEnabled
    public String documentId { get; set; }

    // Download URL if returned by backend.
    // This must not be logged if it contains sensitive tokens.
    @AuraEnabled
    public String downloadUrl { get; set; }

    // Whether backend emailed the package to the client.
    @AuraEnabled
    public Boolean emailedToClient { get; set; }

    // Safe status message.
    @AuraEnabled
    public String statusMessage { get; set; }
  }
}
