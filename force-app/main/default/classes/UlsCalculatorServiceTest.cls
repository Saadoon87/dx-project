/**
 * UlsCalculatorServiceTest
 *
 * Purpose:
 * - Tests the first service framework.
 * - Tests validation behavior.
 * - Tests calculator kill switch behavior.
 * - Tests document generation kill switch behavior.
 * - Tests basic backend success/error response handling using shared HTTP mock helpers.
 */
@IsTest
private class UlsCalculatorServiceTest {
  @IsTest
  static void retrievePolicy_blankPolicy_returnsValidationError() {
    UlsCalculatorService.resetTestOverrides();

    UlsCalculatorService.testCalculatorEnabledOverride = true;

    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.retrievePolicy(
      '',
      'TEST-CORR-001'
    );

    System.Assert.areEqual(
      false,
      response.success,
      'Blank policy number should fail.'
    );
    System.Assert.areEqual(
      'INVALID_POLICY_FORMAT',
      response.errorCode,
      'Expected validation error code.'
    );
    System.Assert.areEqual(
      'TEST-CORR-001',
      response.correlationId,
      'Correlation ID should be preserved.'
    );

    UlsCalculatorService.resetTestOverrides();
  }

  @IsTest
  static void retrievePolicy_calculatorDisabled_returnsDisabledError() {
    UlsCalculatorService.resetTestOverrides();

    UlsCalculatorService.testCalculatorEnabledOverride = false;

    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.retrievePolicy(
      UlsMockDataFactory.DEFAULT_POLICY_NUMBER,
      'TEST-CORR-002'
    );

    System.Assert.areEqual(
      false,
      response.success,
      'Disabled calculator should fail safely.'
    );
    System.Assert.areEqual(
      'CALCULATOR_DISABLED',
      response.errorCode,
      'Expected calculator disabled error.'
    );
    System.Assert.areEqual(
      'TEST-CORR-002',
      response.correlationId,
      'Correlation ID should be preserved.'
    );

    UlsCalculatorService.resetTestOverrides();
  }

  @IsTest
  static void getInflationRate_success_returnsSuccessResponse() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testIncludeSuccessLogsOverride = false;

    Test.setMock(
      HttpCalloutMock.class,
      new UlsHttpCalloutMock(200, UlsMockDataFactory.inflationRateSuccessJson())
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.getInflationRate(
      'TEST-CORR-003'
    );
    Test.stopTest();

    System.Assert.areEqual(
      true,
      response.success,
      'Successful backend response should return success=true.'
    );
    System.Assert.areEqual(
      null,
      response.errorCode,
      'Successful response should not have an error code.'
    );
    System.Assert.areEqual(
      'TEST-CORR-003',
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areNotEqual(
      null,
      response.data,
      'Response data should be populated.'
    );

    HttpRequest lastRequest = UlsHttpCalloutMock.getLastRequest();

    System.Assert.areNotEqual(
      null,
      lastRequest,
      'The mock should capture the backend request.'
    );
    System.Assert.areEqual(
      'GET',
      lastRequest.getMethod(),
      'Inflation rate should use GET.'
    );
    System.Assert.isTrue(
      lastRequest.getEndpoint().contains('/api/v1/calculator/inflation-rate'),
      'Service should call the inflation rate endpoint.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void getInflationRate_backendError_mapsSafely() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    UlsCalculatorService.testCalculatorEnabledOverride = true;

    Test.setMock(
      HttpCalloutMock.class,
      new UlsHttpCalloutMock(
        503,
        UlsMockDataFactory.backendErrorJson(
          'INFLATION_RATE_UNAVAILABLE',
          'Inflation source is down.'
        )
      )
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.getInflationRate(
      'TEST-CORR-004'
    );
    Test.stopTest();

    System.Assert.areEqual(
      false,
      response.success,
      'Backend error should return success=false.'
    );
    System.Assert.areEqual(
      'INFLATION_RATE_UNAVAILABLE',
      response.errorCode,
      'Backend error should map to safe error code.'
    );
    System.Assert.areEqual(
      'TEST-CORR-004',
      response.correlationId,
      'Correlation ID should be preserved.'
    );

    HttpRequest lastRequest = UlsHttpCalloutMock.getLastRequest();

    System.Assert.areNotEqual(
      null,
      lastRequest,
      'The mock should capture the backend request.'
    );
    System.Assert.areEqual(
      'GET',
      lastRequest.getMethod(),
      'Inflation rate should use GET.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void generateFinalPdf_documentDisabled_returnsDisabledError() {
    UlsCalculatorService.resetTestOverrides();

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testDocumentGenerationEnabledOverride = false;

    UlsCalculatorDto.FinalPdfRequest request = UlsMockDataFactory.finalPdfRequest();

    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.generateFinalPdf(
      request,
      'TEST-CORR-005'
    );

    System.Assert.areEqual(
      false,
      response.success,
      'Disabled document generation should fail safely.'
    );
    System.Assert.areEqual(
      'DOCUMENT_GENERATION_DISABLED',
      response.errorCode,
      'Expected document disabled error.'
    );
    System.Assert.areEqual(
      'TEST-CORR-005',
      response.correlationId,
      'Correlation ID should be preserved.'
    );

    UlsCalculatorService.resetTestOverrides();
  }

  @IsTest
  static void retrievePolicy_backendContractFields_mapsToUiDto() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testIncludeSuccessLogsOverride = false;

    Test.setMock(
      HttpCalloutMock.class,
      new UlsHttpCalloutMock(200, UlsMockDataFactory.policySuccessJson())
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.retrievePolicy(
      UlsMockDataFactory.DEFAULT_POLICY_NUMBER,
      'TEST-CORR-MAP-001'
    );
    Test.stopTest();

    System.Assert.areEqual(
      true,
      response.success,
      'Policy retrieval should succeed.'
    );
    System.Assert.areNotEqual(
      null,
      response.data,
      'Mapped policy data should be returned.'
    );

    UlsCalculatorDto.PolicyResponse policy = (UlsCalculatorDto.PolicyResponse) response.data;

    System.Assert.areEqual(
      UlsMockDataFactory.DEFAULT_POLICY_NUMBER,
      policy.policyNumber,
      'Policy number should be mapped.'
    );

    System.Assert.areEqual(
      50000,
      policy.currentUav,
      'Backend currentUAV should map into UI currentUav.'
    );

    System.Assert.areEqual(
      'Test Customer',
      policy.customerName,
      'Customer name should be mapped.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void successLog_isSkippedWhenIncludeSuccessLogsFalse() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-LOG-SKIP-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testIncludeSuccessLogsOverride = false;
    UlsCalculatorService.testDetailedLoggingOverride = true;

    Test.setMock(
      HttpCalloutMock.class,
      new UlsHttpCalloutMock(200, UlsMockDataFactory.inflationRateSuccessJson())
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.getInflationRate(
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      true,
      response.success,
      'Backend call should succeed.'
    );

    Integer logCount = [
      SELECT COUNT()
      FROM Uls_Calculator_Log__c
      WHERE Correlation_Id__c = :correlationId
    ];

    System.Assert.areEqual(
      0,
      logCount,
      'Success log should be skipped when IncludeSuccessLogs__c is false.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void successLog_isInsertedWhenIncludeSuccessLogsTrue() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-LOG-SUCCESS-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testIncludeSuccessLogsOverride = true;
    UlsCalculatorService.testDetailedLoggingOverride = false;

    Test.setMock(
      HttpCalloutMock.class,
      new UlsHttpCalloutMock(200, UlsMockDataFactory.inflationRateSuccessJson())
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.getInflationRate(
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      true,
      response.success,
      'Backend call should succeed.'
    );

    List<Uls_Calculator_Log__c> logs = [
      SELECT Id, Success__c, Detailed_Log__c
      FROM Uls_Calculator_Log__c
      WHERE Correlation_Id__c = :correlationId
    ];

    System.Assert.areEqual(
      1,
      logs.size(),
      'Success log should be inserted when IncludeSuccessLogs__c is true.'
    );

    System.Assert.areEqual(
      true,
      logs[0].Success__c,
      'Inserted log should be marked as success.'
    );

    System.Assert.areEqual(
      null,
      logs[0].Detailed_Log__c,
      'Detailed log should not be stored when EnableDetailedLogging__c is false.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void failureLog_isInsertedEvenWhenIncludeSuccessLogsFalse() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-LOG-FAIL-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testIncludeSuccessLogsOverride = false;
    UlsCalculatorService.testDetailedLoggingOverride = true;

    Test.setMock(
      HttpCalloutMock.class,
      new UlsHttpCalloutMock(
        503,
        UlsMockDataFactory.backendErrorJson(
          'INFLATION_RATE_UNAVAILABLE',
          'Inflation source is down.'
        )
      )
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.getInflationRate(
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      false,
      response.success,
      'Backend error should fail safely.'
    );

    List<Uls_Calculator_Log__c> logs = [
      SELECT Id, Success__c, Error_Code__c, Detailed_Log__c
      FROM Uls_Calculator_Log__c
      WHERE Correlation_Id__c = :correlationId
    ];

    System.Assert.areEqual(
      1,
      logs.size(),
      'Failure log should be inserted even when IncludeSuccessLogs__c is false.'
    );

    System.Assert.areEqual(
      false,
      logs[0].Success__c,
      'Inserted log should be marked as failure.'
    );

    System.Assert.areEqual(
      'INFLATION_RATE_UNAVAILABLE',
      logs[0].Error_Code__c,
      'Failure log should store the safe mapped error code.'
    );

    System.Assert.areNotEqual(
      null,
      logs[0].Detailed_Log__c,
      'Detailed log should be stored when EnableDetailedLogging__c is true.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }
  @IsTest
  static void calculateInflationAdjustedUav_success_postsAndReturnsData() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-CALC-INFLATION-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testIncludeSuccessLogsOverride = false;

    Test.setMock(
      HttpCalloutMock.class,
      new UlsHttpCalloutMock(
        200,
        UlsMockDataFactory.inflationAdjustedUavSuccessJson()
      )
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.calculateInflationAdjustedUav(
      UlsMockDataFactory.inflationAdjustedUavRequest(),
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      true,
      response.success,
      'Inflation-adjusted UAV calculation should succeed.'
    );
    System.Assert.areEqual(
      null,
      response.errorCode,
      'Successful calculation should not return an error code.'
    );
    System.Assert.areEqual(
      correlationId,
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areNotEqual(
      null,
      response.data,
      'Successful calculation should return response data.'
    );

    HttpRequest lastRequest = UlsHttpCalloutMock.getLastRequest();

    System.Assert.areNotEqual(
      null,
      lastRequest,
      'The HTTP mock should capture the backend request.'
    );
    System.Assert.areEqual(
      'POST',
      lastRequest.getMethod(),
      'Inflation-adjusted UAV calculation should use POST.'
    );
    System.Assert.isTrue(
      lastRequest.getEndpoint().contains('inflation-adjusted-uav'),
      'Service should call the inflation-adjusted UAV endpoint.'
    );
    System.Assert.isTrue(
      lastRequest.getBody().contains(UlsMockDataFactory.DEFAULT_POLICY_NUMBER),
      'Request body should include the policy number.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void calculateSuggestedPremium_success_postsAndReturnsData() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-CALC-PREMIUM-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testIncludeSuccessLogsOverride = false;

    Test.setMock(
      HttpCalloutMock.class,
      new UlsHttpCalloutMock(
        200,
        UlsMockDataFactory.suggestedPremiumSuccessJson()
      )
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.calculateSuggestedPremium(
      UlsMockDataFactory.suggestedPremiumRequest(),
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      true,
      response.success,
      'Suggested premium calculation should succeed.'
    );
    System.Assert.areEqual(
      null,
      response.errorCode,
      'Successful calculation should not return an error code.'
    );
    System.Assert.areEqual(
      correlationId,
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areNotEqual(
      null,
      response.data,
      'Successful calculation should return response data.'
    );

    HttpRequest lastRequest = UlsHttpCalloutMock.getLastRequest();

    System.Assert.areNotEqual(
      null,
      lastRequest,
      'The HTTP mock should capture the backend request.'
    );
    System.Assert.areEqual(
      'POST',
      lastRequest.getMethod(),
      'Suggested premium calculation should use POST.'
    );
    System.Assert.isTrue(
      lastRequest.getEndpoint().contains('suggested-premium'),
      'Service should call the suggested premium endpoint.'
    );
    System.Assert.isTrue(
      lastRequest.getBody().contains(UlsMockDataFactory.DEFAULT_POLICY_NUMBER),
      'Request body should include the policy number.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void calculateFinalUav_success_postsAndReturnsData() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-CALC-FINAL-UAV-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testIncludeSuccessLogsOverride = false;

    Test.setMock(
      HttpCalloutMock.class,
      new UlsHttpCalloutMock(200, UlsMockDataFactory.finalUavSuccessJson())
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.calculateFinalUav(
      UlsMockDataFactory.finalUavRequest(),
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      true,
      response.success,
      'Final UAV calculation should succeed.'
    );
    System.Assert.areEqual(
      null,
      response.errorCode,
      'Successful calculation should not return an error code.'
    );
    System.Assert.areEqual(
      correlationId,
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areNotEqual(
      null,
      response.data,
      'Successful calculation should return response data.'
    );

    HttpRequest lastRequest = UlsHttpCalloutMock.getLastRequest();

    System.Assert.areNotEqual(
      null,
      lastRequest,
      'The HTTP mock should capture the backend request.'
    );
    System.Assert.areEqual(
      'POST',
      lastRequest.getMethod(),
      'Final UAV calculation should use POST.'
    );
    System.Assert.isTrue(
      lastRequest.getEndpoint().contains('final-uav'),
      'Service should call the final UAV endpoint.'
    );
    System.Assert.isTrue(
      lastRequest.getBody().contains(UlsMockDataFactory.DEFAULT_POLICY_NUMBER),
      'Request body should include the policy number.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void calculateInflationAdjustedUav_invalidInitialUav_returnsValidationError() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-CALC-INFLATION-INVALID-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;

    Map<String, Object> requestBody = new Map<String, Object>();
    requestBody.put('policyNumber', UlsMockDataFactory.DEFAULT_POLICY_NUMBER);
    requestBody.put('initialUAV', 0);

    UlsCalculatorDto.InflationAdjustedUavRequest request = (UlsCalculatorDto.InflationAdjustedUavRequest) JSON.deserialize(
      JSON.serialize(requestBody),
      UlsCalculatorDto.InflationAdjustedUavRequest.class
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.calculateInflationAdjustedUav(
      request,
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      false,
      response.success,
      'Invalid initial UAV should fail validation.'
    );
    System.Assert.areEqual(
      'INVALID_INPUT',
      response.errorCode,
      'Invalid initial UAV should return INVALID_INPUT.'
    );
    System.Assert.areEqual(
      correlationId,
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areEqual(
      null,
      UlsHttpCalloutMock.getLastRequest(),
      'Validation failure should happen before backend callout.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void calculateSuggestedPremium_invalidTargetFinalUav_returnsValidationError() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-CALC-PREMIUM-INVALID-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;

    Map<String, Object> requestBody = new Map<String, Object>();
    requestBody.put('policyNumber', UlsMockDataFactory.DEFAULT_POLICY_NUMBER);
    requestBody.put('targetFinalUAV', 0);

    UlsCalculatorDto.SuggestedPremiumRequest request = (UlsCalculatorDto.SuggestedPremiumRequest) JSON.deserialize(
      JSON.serialize(requestBody),
      UlsCalculatorDto.SuggestedPremiumRequest.class
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.calculateSuggestedPremium(
      request,
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      false,
      response.success,
      'Invalid target final UAV should fail validation.'
    );
    System.Assert.areEqual(
      'INVALID_INPUT',
      response.errorCode,
      'Invalid target final UAV should return INVALID_INPUT.'
    );
    System.Assert.areEqual(
      correlationId,
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areEqual(
      null,
      UlsHttpCalloutMock.getLastRequest(),
      'Validation failure should happen before backend callout.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void calculateFinalUav_invalidRequestedPremium_returnsValidationError() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-CALC-FINAL-UAV-INVALID-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;

    Map<String, Object> requestBody = new Map<String, Object>();
    requestBody.put('policyNumber', UlsMockDataFactory.DEFAULT_POLICY_NUMBER);
    requestBody.put('requestedPremium', 0);

    UlsCalculatorDto.FinalUavRequest request = (UlsCalculatorDto.FinalUavRequest) JSON.deserialize(
      JSON.serialize(requestBody),
      UlsCalculatorDto.FinalUavRequest.class
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.calculateFinalUav(
      request,
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      false,
      response.success,
      'Invalid requested premium should fail validation.'
    );
    System.Assert.areEqual(
      'INVALID_INPUT',
      response.errorCode,
      'Invalid requested premium should return INVALID_INPUT.'
    );
    System.Assert.areEqual(
      correlationId,
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areEqual(
      null,
      UlsHttpCalloutMock.getLastRequest(),
      'Validation failure should happen before backend callout.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void getFunds_success_mapsFundOptions() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-FUNDS-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testIncludeSuccessLogsOverride = false;

    Test.setMock(
      HttpCalloutMock.class,
      new UlsHttpCalloutMock(200, UlsMockDataFactory.fundsSuccessJson())
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.getFunds(
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      true,
      response.success,
      'Funds retrieval should succeed.'
    );
    System.Assert.areEqual(
      null,
      response.errorCode,
      'Successful funds retrieval should not return an error code.'
    );
    System.Assert.areEqual(
      correlationId,
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areNotEqual(
      null,
      response.data,
      'Funds response data should be populated.'
    );

    UlsCalculatorDto.FundsResponse fundsResponse = (UlsCalculatorDto.FundsResponse) response.data;

    System.Assert.areEqual(
      3,
      fundsResponse.funds.size(),
      'Three fund options should be mapped from investmentFundTypesAndRatesByCurrencyId.'
    );
    System.Assert.areEqual(
      '18',
      fundsResponse.funds[0].fundId,
      'Numeric backend id should be converted to string fundId.'
    );
    System.Assert.areEqual(
      'Money Market',
      fundsResponse.funds[0].fundName,
      'Backend name should be mapped to fundName.'
    );
    System.Assert.areEqual(
      10,
      fundsResponse.funds[0].lowerRate,
      'lowerRate should be mapped.'
    );
    System.Assert.areEqual(
      0,
      fundsResponse.funds[0].centralRate,
      'centralRate should be mapped.'
    );
    System.Assert.areEqual(
      18,
      fundsResponse.funds[0].upperRate,
      'upperRate should be mapped.'
    );
    System.Assert.areEqual(
      null,
      fundsResponse.funds[2].lowerRate,
      'Null lowerRate should stay null when backend sends null.'
    );

    HttpRequest lastRequest = UlsHttpCalloutMock.getLastRequest();

    System.Assert.areNotEqual(
      null,
      lastRequest,
      'The HTTP mock should capture the backend request.'
    );
    System.Assert.areEqual(
      'GET',
      lastRequest.getMethod(),
      'Funds retrieval should use GET.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void getTermExtensionOptions_success_mapsAvailableExtensions() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-TERM-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testIncludeSuccessLogsOverride = false;

    Test.setMock(
      HttpCalloutMock.class,
      new UlsHttpCalloutMock(
        200,
        UlsMockDataFactory.termExtensionOptionsSuccessJson()
      )
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.getTermExtensionOptions(
      UlsMockDataFactory.DEFAULT_POLICY_NUMBER,
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      true,
      response.success,
      'Term extension options retrieval should succeed.'
    );
    System.Assert.areEqual(
      null,
      response.errorCode,
      'Successful term extension retrieval should not return an error code.'
    );
    System.Assert.areEqual(
      correlationId,
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areNotEqual(
      null,
      response.data,
      'Term extension response data should be populated.'
    );

    UlsCalculatorDto.TermExtensionOptionsResponse optionsResponse = (UlsCalculatorDto.TermExtensionOptionsResponse) response.data;

    System.Assert.areEqual(
      UlsMockDataFactory.DEFAULT_POLICY_NUMBER,
      optionsResponse.policyNumber,
      'Policy number should be mapped.'
    );
    System.Assert.areEqual(
      3,
      optionsResponse.options.size(),
      'Three extension options should be mapped.'
    );
    System.Assert.areEqual(
      10,
      optionsResponse.options[1],
      'Available extension options should be preserved.'
    );

    HttpRequest lastRequest = UlsHttpCalloutMock.getLastRequest();

    System.Assert.areNotEqual(
      null,
      lastRequest,
      'The HTTP mock should capture the backend request.'
    );
    System.Assert.areEqual(
      'GET',
      lastRequest.getMethod(),
      'Term extension options retrieval should use GET.'
    );
    System.Assert.isTrue(
      lastRequest.getEndpoint()
        .contains(UlsMockDataFactory.DEFAULT_POLICY_NUMBER),
      'Endpoint should include the policy number.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void generateProjectionPdf_documentDisabled_returnsDisabledError() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-PROJECTION-PDF-DISABLED-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testDocumentGenerationEnabledOverride = false;

    Map<String, Object> requestBody = new Map<String, Object>();
    requestBody.put('policyNumber', UlsMockDataFactory.DEFAULT_POLICY_NUMBER);

    UlsCalculatorDto.ProjectionPdfRequest request = (UlsCalculatorDto.ProjectionPdfRequest) JSON.deserialize(
      JSON.serialize(requestBody),
      UlsCalculatorDto.ProjectionPdfRequest.class
    );

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.generateProjectionPdf(
      request,
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      false,
      response.success,
      'Projection PDF generation should fail when document generation is disabled.'
    );
    System.Assert.areEqual(
      'DOCUMENT_GENERATION_DISABLED',
      response.errorCode,
      'Expected document generation disabled error.'
    );
    System.Assert.areEqual(
      correlationId,
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areEqual(
      null,
      UlsHttpCalloutMock.getLastRequest(),
      'Disabled document generation should prevent backend callout.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void getAttachments_documentDisabled_returnsDisabledError() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-ATTACHMENTS-DISABLED-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;
    UlsCalculatorService.testDocumentGenerationEnabledOverride = false;

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.getAttachments(
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      false,
      response.success,
      'Attachments retrieval should fail when document generation is disabled.'
    );
    System.Assert.areEqual(
      'DOCUMENT_GENERATION_DISABLED',
      response.errorCode,
      'Expected document generation disabled error.'
    );
    System.Assert.areEqual(
      correlationId,
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areEqual(
      null,
      UlsHttpCalloutMock.getLastRequest(),
      'Disabled document generation should prevent backend callout.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void getTermExtensionOptions_invalidPolicy_returnsValidationError() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-TERM-INVALID-001';

    UlsCalculatorService.testCalculatorEnabledOverride = true;

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.getTermExtensionOptions(
      'POL-INVALID',
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      false,
      response.success,
      'Invalid policy number should fail validation.'
    );
    System.Assert.areEqual(
      'INVALID_POLICY_FORMAT',
      response.errorCode,
      'Expected invalid policy format error.'
    );
    System.Assert.areEqual(
      correlationId,
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areEqual(
      null,
      UlsHttpCalloutMock.getLastRequest(),
      'Validation failure should prevent backend callout.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }

  @IsTest
  static void getFunds_calculatorDisabled_returnsDisabledError() {
    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();

    String correlationId = 'TEST-CORR-FUNDS-DISABLED-001';

    UlsCalculatorService.testCalculatorEnabledOverride = false;

    Test.startTest();
    UlsCalculatorDto.ApiResponse response = UlsCalculatorService.getFunds(
      correlationId
    );
    Test.stopTest();

    System.Assert.areEqual(
      false,
      response.success,
      'Funds retrieval should fail when calculator is disabled.'
    );
    System.Assert.areEqual(
      'CALCULATOR_DISABLED',
      response.errorCode,
      'Expected calculator disabled error.'
    );
    System.Assert.areEqual(
      correlationId,
      response.correlationId,
      'Correlation ID should be preserved.'
    );
    System.Assert.areEqual(
      null,
      UlsHttpCalloutMock.getLastRequest(),
      'Disabled calculator should prevent backend callout.'
    );

    UlsCalculatorService.resetTestOverrides();
    UlsHttpCalloutMock.reset();
  }
}
