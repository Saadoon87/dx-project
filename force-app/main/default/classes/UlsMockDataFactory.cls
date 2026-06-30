/**
 * UlsMockDataFactory
 *
 * Purpose:
 * - Central place for reusable test data.
 * - Keeps test classes cleaner.
 * - Avoids repeating JSON strings and sample values in every test.
 *
 * Important:
 * - This is test-only data.
 * - These values are not business rules.
 * - Backend remains the real source of truth.
 */
@IsTest
public class UlsMockDataFactory {
  /**
   * Default sample policy number used in Apex tests.
   */
  public static final String DEFAULT_POLICY_NUMBER = '8000082';

  /**
   * Default test correlation ID.
   */
  public static final String DEFAULT_CORRELATION_ID = 'TEST-CORR-ULS-001';

  /**
   * Creates a standard backend error JSON response.
   *
   * Backend standard format:
   * {
   *   "errorCode": "ERROR_CODE_CONSTANT",
   *   "message": "Human-readable description."
   * }
   */
  public static String backendErrorJson(String errorCode, String message) {
    Map<String, Object> errorBody = new Map<String, Object>();

    errorBody.put('errorCode', errorCode);
    errorBody.put('message', message);

    return JSON.serialize(errorBody);
  }

  /**
   * Mock response for GET /api/v1/calculator/inflation-rate.
   */
  public static String inflationRateSuccessJson() {
    Map<String, Object> responseBody = new Map<String, Object>();

    responseBody.put('inflationRate', 5.0);

    return JSON.serialize(responseBody);
  }

  /**
   * Mock response for GET /api/v1/policies/{policyNumber}.
   *
   * This is intentionally simple.
   * We will expand it later when implementing Step 1 LWC policy retrieval.
   */
  public static String policySuccessJson() {
    Map<String, Object> responseBody = new Map<String, Object>();

    responseBody.put('policyNumber', DEFAULT_POLICY_NUMBER);
    responseBody.put('customerName', 'Test Customer');
    responseBody.put('status', 'In Force');
    responseBody.put('currentPremium', 1000);
    responseBody.put('currentUAV', 50000);

    return JSON.serialize(responseBody);
  }

  /**
   * Mock response for POST /api/v1/calculator/inflation-adjusted-uav.
   */
  public static String inflationAdjustedUavSuccessJson() {
    Map<String, Object> responseBody = new Map<String, Object>();

    responseBody.put('policyNumber', DEFAULT_POLICY_NUMBER);
    responseBody.put('initialUAV', 100000);
    responseBody.put('inflationRate', 5.0);
    responseBody.put('remainingYears', 10);
    responseBody.put('inflationAdjustedAmount', 162889.46);

    return JSON.serialize(responseBody);
  }

  /**
   * Mock response for POST /api/v1/calculator/suggested-premium.
   */
  public static String suggestedPremiumSuccessJson() {
    Map<String, Object> responseBody = new Map<String, Object>();

    responseBody.put('policyNumber', DEFAULT_POLICY_NUMBER);
    responseBody.put('targetFinalUAV', 250000);
    responseBody.put('suggestedPremium', 3500);
    responseBody.put('currentPremium', 1000);
    responseBody.put('difference', 2500);

    return JSON.serialize(responseBody);
  }

  /**
   * Mock response for POST /api/v1/calculator/final-uav.
   */
  public static String finalUavSuccessJson() {
    Map<String, Object> responseBody = new Map<String, Object>();

    responseBody.put('policyNumber', DEFAULT_POLICY_NUMBER);
    responseBody.put('requestedPremium', 3000);
    responseBody.put('currentPremium', 1000);
    responseBody.put('difference', 2000);
    responseBody.put('projectedFinalUAV', 225000);

    return JSON.serialize(responseBody);
  }

  /**
   * Creates a request DTO for inflation-adjusted UAV tests.
   *
   * JSON.deserialize is used so this factory stays flexible if DTO construction changes later.
   */
  public static UlsCalculatorDto.InflationAdjustedUavRequest inflationAdjustedUavRequest() {
    Map<String, Object> requestBody = new Map<String, Object>();

    requestBody.put('policyNumber', DEFAULT_POLICY_NUMBER);
    requestBody.put('initialUAV', 100000);

    return (UlsCalculatorDto.InflationAdjustedUavRequest) JSON.deserialize(
      JSON.serialize(requestBody),
      UlsCalculatorDto.InflationAdjustedUavRequest.class
    );
  }

  /**
   * Creates a request DTO for suggested premium tests.
   */
  public static UlsCalculatorDto.SuggestedPremiumRequest suggestedPremiumRequest() {
    Map<String, Object> requestBody = new Map<String, Object>();

    requestBody.put('policyNumber', DEFAULT_POLICY_NUMBER);
    requestBody.put('targetFinalUAV', 250000);

    return (UlsCalculatorDto.SuggestedPremiumRequest) JSON.deserialize(
      JSON.serialize(requestBody),
      UlsCalculatorDto.SuggestedPremiumRequest.class
    );
  }

  /**
   * Creates a request DTO for final UAV tests.
   */
  public static UlsCalculatorDto.FinalUavRequest finalUavRequest() {
    Map<String, Object> requestBody = new Map<String, Object>();

    requestBody.put('policyNumber', DEFAULT_POLICY_NUMBER);
    requestBody.put('requestedPremium', 3000);

    return (UlsCalculatorDto.FinalUavRequest) JSON.deserialize(
      JSON.serialize(requestBody),
      UlsCalculatorDto.FinalUavRequest.class
    );
  }

  /**
   * Creates a simple final PDF request.
   *
   * Document flow is not finalized yet, so this remains intentionally minimal.
   */
  public static UlsCalculatorDto.FinalPdfRequest finalPdfRequest() {
    Map<String, Object> requestBody = new Map<String, Object>();

    requestBody.put('policyNumber', DEFAULT_POLICY_NUMBER);

    return (UlsCalculatorDto.FinalPdfRequest) JSON.deserialize(
      JSON.serialize(requestBody),
      UlsCalculatorDto.FinalPdfRequest.class
    );
  }
  /**
   * Mock response for GET funds/options.
   */
  public static String fundsSuccessJson() {
    Map<String, Object> fundOne = new Map<String, Object>();
    fundOne.put('fundId', 'FUND-ACTIVE');
    fundOne.put('fundCode', 'ACTIVE');
    fundOne.put('fundName', 'Active Fund');
    fundOne.put('lowReturnRate', 3.5);
    fundOne.put('highReturnRate', 7.5);

    Map<String, Object> fundTwo = new Map<String, Object>();
    fundTwo.put('fundCode', 'BALANCED');
    fundTwo.put('nameEn', 'Balanced Fund');
    fundTwo.put('lowReturnRate', 2.5);
    fundTwo.put('highReturnRate', 6.0);

    Map<String, Object> responseBody = new Map<String, Object>();
    responseBody.put('funds', new List<Object>{ fundOne, fundTwo });

    return JSON.serialize(responseBody);
  }

  /**
   * Mock response for GET valid term extension options.
   */
  public static String termExtensionOptionsSuccessJson() {
    Map<String, Object> responseBody = new Map<String, Object>();

    responseBody.put('policyNumber', DEFAULT_POLICY_NUMBER);
    responseBody.put('availableExtensions', new List<Integer>{ 5, 10, 15 });

    return JSON.serialize(responseBody);
  }
}
