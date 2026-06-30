/**
 * UlsCalculatorService
 *
 * Purpose:
 * - Acts as the main Apex service layer for the ULS Calculator.
 * - The future LWC controller will call this class.
 * - This class prepares safe backend requests, handles config, maps backend errors,
 *   logs operational events, and returns safe responses to the LWC.
 *
 * Important:
 * - This class does not contain real ULS calculation formulas.
 * - Backend remains the source of truth for calculations and product validation.
 * - Named Credential "ULS_Backend" is referenced as a placeholder for future config.
 */
public with sharing class UlsCalculatorService {
  /*
   * Named Credential placeholder.
   *
   * We are not creating the Named Credential in this step.
   * The endpoint will compile even if the Named Credential does not exist yet.
   * Runtime callouts will only work after the Named Credential is created/configured.
   */
  private static final String NAMED_CREDENTIAL_PREFIX = 'callout:ULS_Backend';

  /*
   * Default timeout used if Custom Metadata is missing or invalid.
   */
  private static final Integer DEFAULT_TIMEOUT_MS = 10000;

  /*
   * Backend endpoint constants.
   *
   * These are based on the uploaded API definition and confirmed project decisions.
   */
  private static final String GET_POLICY = '/policy-management/policy/summary/{policyNumber}';
  private static final String GET_INFLATION_RATE = '/api/v1/calculator/inflation-rate';
  private static final String POST_INFLATION_ADJUSTED_UAV = '/policy-management/calculator/inflation-adjusted-uav';
  private static final String POST_SUGGESTED_PREMIUM = '/api/v1/calculator/suggested-premium';
  private static final String POST_FINAL_UAV = '/api/v1/calculator/final-uav';
  private static final String GET_FUNDS = '/lookups-svc/lookups/investment-funds-and-rates?currencyId=16';
  private static final String GET_TERM_EXTENSION_OPTIONS = '/policy-management/policy/term-extension-options/{policyNumber}';
  private static final String POST_PROJECTION = '/api/v1/calculator/projection';
  private static final String POST_PROJECTION_PDF = '/api/v1/documents/projection-pdf';
  private static final String GET_ATTACHMENTS = '/api/v1/documents/attachments';
  private static final String POST_FINAL_PDF = '/api/v1/documents/final-pdf';

  /*
   * Test override fields.
   *
   * These make tests deterministic without changing real Custom Metadata records.
   * They are marked @TestVisible so only test classes can control them.
   */
  @TestVisible
  private static Boolean testCalculatorEnabledOverride;
  @TestVisible
  private static Boolean testDocumentGenerationEnabledOverride;
  @TestVisible
  private static Boolean testDetailedLoggingOverride;
  @TestVisible
  private static Boolean testIncludeSuccessLogsOverride;
  @TestVisible
  private static Integer testTimeoutMsOverride;

  /**
   * Internal config wrapper.
   *
   * This keeps Custom Metadata handling clean and avoids passing raw metadata
   * records throughout the service.
   */
  private class ServiceConfig {
    Boolean isCalculatorEnabled;
    Boolean isDocumentGenerationEnabled;
    Boolean enableDetailedLogging;
    Boolean includeSuccessLogs;
    Integer timeoutMs;
  }

  /**
   * Internal backend error wrapper.
   *
   * Backend standard error shape:
   * {
   *   "errorCode": "ERROR_CODE_CONSTANT",
   *   "message": "Human-readable description."
   * }
   */
  private class BackendError {
    String errorCode;
    String message;
  }

  /**
   * Internal mapped error wrapper.
   *
   * This is used to convert backend/HTTP errors into safe LWC-facing errors.
   */
  private class MappedError {
    String errorCode;
    String category;
    String userMessage;

    MappedError(String errorCode, String category, String userMessage) {
      this.errorCode = errorCode;
      this.category = category;
      this.userMessage = userMessage;
    }
  }

  // =====================================================================================
  // Public service methods planned for controller use
  // =====================================================================================

  /**
   * Retrieves policy data from backend by policy number.
   */
  public static UlsCalculatorDto.ApiResponse retrievePolicy(
    String policyNumber,
    String correlationId
  ) {
    correlationId = ensureCorrelationId(correlationId);

    ServiceConfig config = loadConfig();

    if (!config.isCalculatorEnabled) {
      return buildAndLogErrorResponse(
        'retrievePolicy',
        'LWC_TO_APEX',
        GET_POLICY,
        'GET',
        null,
        0,
        'CALCULATOR_DISABLED',
        'ConfigDisabled',
        'ULS Calculator is temporarily unavailable. Please try again later or contact support.',
        correlationId,
        policyNumber,
        'Calculator kill switch is disabled.'
      );
    }

    String validationError = validatePolicyNumber(policyNumber);

    if (validationError != null) {
      return buildAndLogErrorResponse(
        'retrievePolicy',
        'LWC_TO_APEX',
        GET_POLICY,
        'GET',
        null,
        0,
        'INVALID_POLICY_FORMAT',
        'Validation',
        validationError,
        correlationId,
        policyNumber,
        'Policy number validation failed before backend call.'
      );
    }

    String safePolicyNumber = EncodingUtil.urlEncode(policyNumber, 'UTF-8');
    String endpoint = GET_POLICY.replace('{policyNumber}', safePolicyNumber);

    return sendGet(
      endpoint,
      'retrievePolicy',
      UlsCalculatorDto.PolicyResponse.class,
      correlationId,
      policyNumber
    );
  }

  /**
   * Retrieves the current inflation rate from backend.
   */
  public static UlsCalculatorDto.ApiResponse getInflationRate(
    String correlationId
  ) {
    correlationId = ensureCorrelationId(correlationId);

    ServiceConfig config = loadConfig();

    if (!config.isCalculatorEnabled) {
      return buildAndLogErrorResponse(
        'getInflationRate',
        'LWC_TO_APEX',
        GET_INFLATION_RATE,
        'GET',
        null,
        0,
        'CALCULATOR_DISABLED',
        'ConfigDisabled',
        'ULS Calculator is temporarily unavailable. Please try again later or contact support.',
        correlationId,
        null,
        'Calculator kill switch is disabled.'
      );
    }

    return sendGet(
      GET_INFLATION_RATE,
      'getInflationRate',
      UlsCalculatorDto.InflationRateResponse.class,
      correlationId,
      null
    );
  }

  /**
   * Requests backend calculation for inflation-adjusted UAV.
   */
  public static UlsCalculatorDto.ApiResponse calculateInflationAdjustedUav(
    UlsCalculatorDto.InflationAdjustedUavRequest request,
    String correlationId
  ) {
    correlationId = ensureCorrelationId(correlationId);

    ServiceConfig config = loadConfig();

    String policyNumber = extractStringField(request, 'policyNumber');

    if (!config.isCalculatorEnabled) {
      return buildAndLogErrorResponse(
        'calculateInflationAdjustedUav',
        'LWC_TO_APEX',
        POST_INFLATION_ADJUSTED_UAV,
        'POST',
        null,
        0,
        'CALCULATOR_DISABLED',
        'ConfigDisabled',
        'ULS Calculator is temporarily unavailable. Please try again later or contact support.',
        correlationId,
        policyNumber,
        'Calculator kill switch is disabled.'
      );
    }

    String validationError = validatePolicyNumber(policyNumber);

    if (validationError != null) {
      return buildAndLogErrorResponse(
        'calculateInflationAdjustedUav',
        'LWC_TO_APEX',
        POST_INFLATION_ADJUSTED_UAV,
        'POST',
        null,
        0,
        'INVALID_POLICY_FORMAT',
        'Validation',
        validationError,
        correlationId,
        policyNumber,
        'Policy number validation failed before backend call.'
      );
    }

    Decimal initialUav = extractDecimalField(request, 'initialUAV');

    if (initialUav == null || initialUav <= 0) {
      return buildAndLogErrorResponse(
        'calculateInflationAdjustedUav',
        'LWC_TO_APEX',
        POST_INFLATION_ADJUSTED_UAV,
        'POST',
        null,
        0,
        'INVALID_INPUT',
        'Validation',
        'Please enter a valid positive initial UAV amount.',
        correlationId,
        policyNumber,
        'Initial UAV validation failed before backend call.'
      );
    }

    return sendPost(
      POST_INFLATION_ADJUSTED_UAV,
      'calculateInflationAdjustedUav',
      request,
      UlsCalculatorDto.InflationAdjustedUavResponse.class,
      correlationId,
      policyNumber
    );
  }

  /**
   * Requests backend calculation for suggested premium.
   */
  public static UlsCalculatorDto.ApiResponse calculateSuggestedPremium(
    UlsCalculatorDto.SuggestedPremiumRequest request,
    String correlationId
  ) {
    correlationId = ensureCorrelationId(correlationId);

    ServiceConfig config = loadConfig();

    String policyNumber = extractStringField(request, 'policyNumber');

    if (!config.isCalculatorEnabled) {
      return buildAndLogErrorResponse(
        'calculateSuggestedPremium',
        'LWC_TO_APEX',
        POST_SUGGESTED_PREMIUM,
        'POST',
        null,
        0,
        'CALCULATOR_DISABLED',
        'ConfigDisabled',
        'ULS Calculator is temporarily unavailable. Please try again later or contact support.',
        correlationId,
        policyNumber,
        'Calculator kill switch is disabled.'
      );
    }

    String validationError = validatePolicyNumber(policyNumber);

    if (validationError != null) {
      return buildAndLogErrorResponse(
        'calculateSuggestedPremium',
        'LWC_TO_APEX',
        POST_SUGGESTED_PREMIUM,
        'POST',
        null,
        0,
        'INVALID_POLICY_FORMAT',
        'Validation',
        validationError,
        correlationId,
        policyNumber,
        'Policy number validation failed before backend call.'
      );
    }

    Decimal targetFinalUav = extractDecimalField(request, 'targetFinalUAV');

    if (targetFinalUav == null || targetFinalUav <= 0) {
      return buildAndLogErrorResponse(
        'calculateSuggestedPremium',
        'LWC_TO_APEX',
        POST_SUGGESTED_PREMIUM,
        'POST',
        null,
        0,
        'INVALID_INPUT',
        'Validation',
        'Please enter a valid positive target final UAV amount.',
        correlationId,
        policyNumber,
        'Target final UAV validation failed before backend call.'
      );
    }

    return sendPost(
      POST_SUGGESTED_PREMIUM,
      'calculateSuggestedPremium',
      request,
      UlsCalculatorDto.SuggestedPremiumResponse.class,
      correlationId,
      policyNumber
    );
  }

  /**
   * Requests backend calculation for final UAV based on requested premium.
   */
  public static UlsCalculatorDto.ApiResponse calculateFinalUav(
    UlsCalculatorDto.FinalUavRequest request,
    String correlationId
  ) {
    correlationId = ensureCorrelationId(correlationId);

    ServiceConfig config = loadConfig();

    String policyNumber = extractStringField(request, 'policyNumber');

    if (!config.isCalculatorEnabled) {
      return buildAndLogErrorResponse(
        'calculateFinalUav',
        'LWC_TO_APEX',
        POST_FINAL_UAV,
        'POST',
        null,
        0,
        'CALCULATOR_DISABLED',
        'ConfigDisabled',
        'ULS Calculator is temporarily unavailable. Please try again later or contact support.',
        correlationId,
        policyNumber,
        'Calculator kill switch is disabled.'
      );
    }

    String validationError = validatePolicyNumber(policyNumber);

    if (validationError != null) {
      return buildAndLogErrorResponse(
        'calculateFinalUav',
        'LWC_TO_APEX',
        POST_FINAL_UAV,
        'POST',
        null,
        0,
        'INVALID_POLICY_FORMAT',
        'Validation',
        validationError,
        correlationId,
        policyNumber,
        'Policy number validation failed before backend call.'
      );
    }

    Decimal requestedPremium = extractDecimalField(request, 'requestedPremium');

    if (requestedPremium == null || requestedPremium <= 0) {
      return buildAndLogErrorResponse(
        'calculateFinalUav',
        'LWC_TO_APEX',
        POST_FINAL_UAV,
        'POST',
        null,
        0,
        'INVALID_INPUT',
        'Validation',
        'Please enter a valid positive requested premium amount.',
        correlationId,
        policyNumber,
        'Requested premium validation failed before backend call.'
      );
    }

    return sendPost(
      POST_FINAL_UAV,
      'calculateFinalUav',
      request,
      UlsCalculatorDto.FinalUavResponse.class,
      correlationId,
      policyNumber
    );
  }

  /**
   * Retrieves fund options from backend.
   */
  public static UlsCalculatorDto.ApiResponse getFunds(String correlationId) {
    correlationId = ensureCorrelationId(correlationId);

    ServiceConfig config = loadConfig();

    if (!config.isCalculatorEnabled) {
      return buildAndLogErrorResponse(
        'getFunds',
        'LWC_TO_APEX',
        GET_FUNDS,
        'GET',
        null,
        0,
        'CALCULATOR_DISABLED',
        'ConfigDisabled',
        'ULS Calculator is temporarily unavailable. Please try again later or contact support.',
        correlationId,
        null,
        'Calculator kill switch is disabled.'
      );
    }

    return sendGet(
      GET_FUNDS,
      'getFunds',
      UlsCalculatorDto.FundsResponse.class,
      correlationId,
      null
    );
  }

  /**
   * Retrieves valid term extension options for a policy.
   */
  public static UlsCalculatorDto.ApiResponse getTermExtensionOptions(
    String policyNumber,
    String correlationId
  ) {
    correlationId = ensureCorrelationId(correlationId);

    ServiceConfig config = loadConfig();

    if (!config.isCalculatorEnabled) {
      return buildAndLogErrorResponse(
        'getTermExtensionOptions',
        'LWC_TO_APEX',
        GET_TERM_EXTENSION_OPTIONS,
        'GET',
        null,
        0,
        'CALCULATOR_DISABLED',
        'ConfigDisabled',
        'ULS Calculator is temporarily unavailable. Please try again later or contact support.',
        correlationId,
        policyNumber,
        'Calculator kill switch is disabled.'
      );
    }

    String validationError = validatePolicyNumber(policyNumber);

    if (validationError != null) {
      return buildAndLogErrorResponse(
        'getTermExtensionOptions',
        'LWC_TO_APEX',
        GET_TERM_EXTENSION_OPTIONS,
        'GET',
        null,
        0,
        'INVALID_POLICY_FORMAT',
        'Validation',
        validationError,
        correlationId,
        policyNumber,
        'Policy number validation failed before backend call.'
      );
    }

    String safePolicyNumber = EncodingUtil.urlEncode(policyNumber, 'UTF-8');
    String endpoint = GET_TERM_EXTENSION_OPTIONS.replace(
      '{policyNumber}',
      safePolicyNumber
    );

    return sendGet(
      endpoint,
      'getTermExtensionOptions',
      UlsCalculatorDto.TermExtensionOptionsResponse.class,
      correlationId,
      policyNumber
    );
  }

  /**
   * Requests backend projection calculation.
   */
  public static UlsCalculatorDto.ApiResponse generateProjection(
    UlsCalculatorDto.AlterationRequest request,
    String correlationId
  ) {
    correlationId = ensureCorrelationId(correlationId);

    ServiceConfig config = loadConfig();

    String policyNumber = extractStringField(request, 'policyNumber');

    if (!config.isCalculatorEnabled) {
      return buildAndLogErrorResponse(
        'generateProjection',
        'LWC_TO_APEX',
        POST_PROJECTION,
        'POST',
        null,
        0,
        'CALCULATOR_DISABLED',
        'ConfigDisabled',
        'ULS Calculator is temporarily unavailable. Please try again later or contact support.',
        correlationId,
        policyNumber,
        'Calculator kill switch is disabled.'
      );
    }

    String validationError = validateAlterationRequest(request);

    if (validationError != null) {
      return buildAndLogErrorResponse(
        'generateProjection',
        'LWC_TO_APEX',
        POST_PROJECTION,
        'POST',
        null,
        0,
        'INVALID_INPUT',
        'Validation',
        validationError,
        correlationId,
        policyNumber,
        'Alteration request validation failed before backend call.'
      );
    }

    return sendPost(
      POST_PROJECTION,
      'generateProjection',
      request,
      UlsCalculatorDto.ProjectionResponse.class,
      correlationId,
      policyNumber
    );
  }

  /**
   * Requests backend projection PDF generation.
   */
  public static UlsCalculatorDto.ApiResponse generateProjectionPdf(
    UlsCalculatorDto.ProjectionPdfRequest request,
    String correlationId
  ) {
    correlationId = ensureCorrelationId(correlationId);

    ServiceConfig config = loadConfig();

    String policyNumber = extractStringField(request, 'policyNumber');

    if (!config.isCalculatorEnabled) {
      return buildAndLogErrorResponse(
        'generateProjectionPdf',
        'LWC_TO_APEX',
        POST_PROJECTION_PDF,
        'POST',
        null,
        0,
        'CALCULATOR_DISABLED',
        'ConfigDisabled',
        'ULS Calculator is temporarily unavailable. Please try again later or contact support.',
        correlationId,
        policyNumber,
        'Calculator kill switch is disabled.'
      );
    }

    if (!config.isDocumentGenerationEnabled) {
      return buildAndLogErrorResponse(
        'generateProjectionPdf',
        'LWC_TO_APEX',
        POST_PROJECTION_PDF,
        'POST',
        null,
        0,
        'DOCUMENT_GENERATION_DISABLED',
        'ConfigDisabled',
        'Document generation is not available yet.',
        correlationId,
        policyNumber,
        'Document generation kill switch is disabled.'
      );
    }

    return sendPost(
      POST_PROJECTION_PDF,
      'generateProjectionPdf',
      request,
      UlsCalculatorDto.DocumentResponse.class,
      correlationId,
      policyNumber
    );
  }

  /**
   * Retrieves optional attachment templates from backend.
   */
  public static UlsCalculatorDto.ApiResponse getAttachments(
    String correlationId
  ) {
    correlationId = ensureCorrelationId(correlationId);

    ServiceConfig config = loadConfig();

    if (!config.isCalculatorEnabled) {
      return buildAndLogErrorResponse(
        'getAttachments',
        'LWC_TO_APEX',
        GET_ATTACHMENTS,
        'GET',
        null,
        0,
        'CALCULATOR_DISABLED',
        'ConfigDisabled',
        'ULS Calculator is temporarily unavailable. Please try again later or contact support.',
        correlationId,
        null,
        'Calculator kill switch is disabled.'
      );
    }

    if (!config.isDocumentGenerationEnabled) {
      return buildAndLogErrorResponse(
        'getAttachments',
        'LWC_TO_APEX',
        GET_ATTACHMENTS,
        'GET',
        null,
        0,
        'DOCUMENT_GENERATION_DISABLED',
        'ConfigDisabled',
        'Document generation is not available yet.',
        correlationId,
        null,
        'Document generation kill switch is disabled.'
      );
    }

    return sendGet(
      GET_ATTACHMENTS,
      'getAttachments',
      UlsCalculatorDto.AttachmentsResponse.class,
      correlationId,
      null
    );
  }

  /**
   * Requests backend final PDF/package generation.
   */
  public static UlsCalculatorDto.ApiResponse generateFinalPdf(
    UlsCalculatorDto.FinalPdfRequest request,
    String correlationId
  ) {
    correlationId = ensureCorrelationId(correlationId);

    ServiceConfig config = loadConfig();

    String policyNumber = extractStringField(request, 'policyNumber');

    if (!config.isCalculatorEnabled) {
      return buildAndLogErrorResponse(
        'generateFinalPdf',
        'LWC_TO_APEX',
        POST_FINAL_PDF,
        'POST',
        null,
        0,
        'CALCULATOR_DISABLED',
        'ConfigDisabled',
        'ULS Calculator is temporarily unavailable. Please try again later or contact support.',
        correlationId,
        policyNumber,
        'Calculator kill switch is disabled.'
      );
    }

    if (!config.isDocumentGenerationEnabled) {
      return buildAndLogErrorResponse(
        'generateFinalPdf',
        'LWC_TO_APEX',
        POST_FINAL_PDF,
        'POST',
        null,
        0,
        'DOCUMENT_GENERATION_DISABLED',
        'ConfigDisabled',
        'Document generation is not available yet.',
        correlationId,
        policyNumber,
        'Document generation kill switch is disabled.'
      );
    }

    return sendPost(
      POST_FINAL_PDF,
      'generateFinalPdf',
      request,
      UlsCalculatorDto.DocumentResponse.class,
      correlationId,
      policyNumber
    );
  }

  // =====================================================================================
  // HTTP helper methods
  // =====================================================================================

  /**
   * Sends a GET request to backend through the Named Credential.
   */
  private static UlsCalculatorDto.ApiResponse sendGet(
    String endpointPath,
    String operationName,
    Type responseType,
    String correlationId,
    String policyNumber
  ) {
    return sendRequest(
      'GET',
      endpointPath,
      operationName,
      null,
      responseType,
      correlationId,
      policyNumber
    );
  }

  /**
   * Sends a POST request to backend through the Named Credential.
   */
  private static UlsCalculatorDto.ApiResponse sendPost(
    String endpointPath,
    String operationName,
    Object requestBody,
    Type responseType,
    String correlationId,
    String policyNumber
  ) {
    return sendRequest(
      'POST',
      endpointPath,
      operationName,
      requestBody,
      responseType,
      correlationId,
      policyNumber
    );
  }

  /**
   * Shared GET/POST callout logic.
   */
  private static UlsCalculatorDto.ApiResponse sendRequest(
    String httpMethod,
    String endpointPath,
    String operationName,
    Object requestBody,
    Type responseType,
    String correlationId,
    String policyNumber
  ) {
    ServiceConfig config = loadConfig();

    Long startMs = DateTime.now().getTime();

    HttpRequest request = new HttpRequest();

    request.setEndpoint(NAMED_CREDENTIAL_PREFIX + endpointPath);
    request.setMethod(httpMethod);
    request.setTimeout(config.timeoutMs);
    request.setHeader('Accept', 'application/json');

    if (httpMethod == 'POST') {
      request.setHeader('Content-Type', 'application/json');
      request.setBody(JSON.serialize(requestBody));
    }

    try {
      Http http = new Http();
      HttpResponse response = http.send(request);

      Long durationMs = DateTime.now().getTime() - startMs;

      return handleHttpResponse(
        operationName,
        endpointPath,
        httpMethod,
        response,
        responseType,
        correlationId,
        policyNumber,
        durationMs
      );
    } catch (System.CalloutException ex) {
      Long durationMs = DateTime.now().getTime() - startMs;

      String exceptionMessage = ex.getMessage();

      String errorCode = isTimeoutMessage(exceptionMessage)
        ? 'BACKEND_TIMEOUT'
        : 'BACKEND_CALLOUT_FAILED';

      String category = isTimeoutMessage(exceptionMessage)
        ? 'Timeout'
        : 'BackendUnavailable';

      String userMessage = isTimeoutMessage(exceptionMessage)
        ? 'The backend service is taking too long to respond. Please try again later.'
        : 'The calculator cannot connect to the backend service. Please try again later or contact support.';

      return buildAndLogErrorResponse(
        operationName,
        'APEX_TO_BACKEND',
        endpointPath,
        httpMethod,
        null,
        durationMs,
        errorCode,
        category,
        userMessage,
        correlationId,
        policyNumber,
        sanitizeForSupport(exceptionMessage)
      );
    } catch (Exception ex) {
      Long durationMs = DateTime.now().getTime() - startMs;

      return buildAndLogErrorResponse(
        operationName,
        'APEX_TO_BACKEND',
        endpointPath,
        httpMethod,
        null,
        durationMs,
        'UNEXPECTED_SERVER_ERROR',
        'Unexpected',
        'Something went wrong while processing your request. Please try again or contact support.',
        correlationId,
        policyNumber,
        sanitizeForSupport(ex.getMessage())
      );
    }
  }

  /**
   * Handles backend HTTP response and converts it into a safe ApiResponse.
   */
  private static UlsCalculatorDto.ApiResponse handleHttpResponse(
    String operationName,
    String endpointPath,
    String httpMethod,
    HttpResponse httpResponse,
    Type responseType,
    String correlationId,
    String policyNumber,
    Long durationMs
  ) {
    Integer statusCode = httpResponse.getStatusCode();
    String responseBody = httpResponse.getBody();

    if (statusCode >= 200 && statusCode <= 299) {
      Object parsedData;

      if (!String.isBlank(responseBody)) {
        // Deserialize and normalize backend JSON into the UI-safe DTO shape.
        // This keeps backend field names away from the LWC.
        parsedData = parseSuccessfulResponseBody(
          operationName,
          responseBody,
          responseType
        );
      }

      UlsCalculatorDto.ApiResponse successResponse = buildSuccessResponse(
        parsedData,
        correlationId
      );

      writeOperationLog(
        operationName,
        'APEX_TO_BACKEND',
        endpointPath,
        httpMethod,
        statusCode,
        durationMs,
        true,
        null,
        null,
        'Backend request completed successfully.',
        correlationId,
        policyNumber,
        null
      );

      return successResponse;
    }

    BackendError backendError = parseBackendError(responseBody);

    String backendErrorCode = backendError != null &&
      !String.isBlank(backendError.errorCode)
      ? backendError.errorCode
      : 'HTTP_' + String.valueOf(statusCode);

    String backendMessage = backendError != null
      ? backendError.message
      : 'Backend returned HTTP status ' + String.valueOf(statusCode);

    MappedError mappedError = mapBackendError(backendErrorCode, statusCode);

    return buildAndLogErrorResponse(
      operationName,
      'APEX_TO_BACKEND',
      endpointPath,
      httpMethod,
      statusCode,
      durationMs,
      mappedError.errorCode,
      mappedError.category,
      mappedError.userMessage,
      correlationId,
      policyNumber,
      sanitizeForSupport(backendMessage)
    );
  }

  // =====================================================================================
  // Backend-to-UI mapping helpers
  // =====================================================================================

  /**
   * Parses a successful backend response and maps it into the UI-safe DTO shape.
   *
   * Why:
   * - Backend JSON may use names like currentUAV, lifeInsuredName, fundCode,
   *   availableExtensions, fileName, nameEn, or nameAr.
   * - The LWC should receive stable UI-friendly fields like currentUav,
   *   customerName, fundId, fundName, options, and statusMessage.
   */
  private static Object parseSuccessfulResponseBody(
    String operationName,
    String responseBody,
    Type responseType
  ) {
    if (operationName == 'retrievePolicy') {
      UlsCalculatorDto.BackendPolicyResponse backendPolicy = (UlsCalculatorDto.BackendPolicyResponse) JSON.deserialize(
        responseBody,
        UlsCalculatorDto.BackendPolicyResponse.class
      );

      return mapBackendPolicyToUi(backendPolicy);
    }

    if (operationName == 'getFunds') {
      UlsCalculatorDto.BackendFundsResponse backendFunds = (UlsCalculatorDto.BackendFundsResponse) JSON.deserialize(
        responseBody,
        UlsCalculatorDto.BackendFundsResponse.class
      );

      return mapBackendFundsToUi(backendFunds);
    }

    if (operationName == 'getTermExtensionOptions') {
      UlsCalculatorDto.BackendTermExtensionOptionsResponse backendOptions = (UlsCalculatorDto.BackendTermExtensionOptionsResponse) JSON.deserialize(
        responseBody,
        UlsCalculatorDto.BackendTermExtensionOptionsResponse.class
      );

      return mapBackendTermExtensionOptionsToUi(backendOptions);
    }

    if (
      operationName == 'generateProjectionPdf' ||
      operationName == 'generateFinalPdf'
    ) {
      UlsCalculatorDto.BackendDocumentResponse backendDocument = (UlsCalculatorDto.BackendDocumentResponse) JSON.deserialize(
        responseBody,
        UlsCalculatorDto.BackendDocumentResponse.class
      );

      return mapBackendDocumentToUi(backendDocument);
    }

    // For calculation responses whose field names already match the DTO,
    // keep the existing typed deserialization behavior.
    return JSON.deserialize(responseBody, responseType);
  }

  /**
   * Maps backend policy response fields into the UI-safe PolicyResponse DTO.
   */
  private static UlsCalculatorDto.PolicyResponse mapBackendPolicyToUi(
    UlsCalculatorDto.BackendPolicyResponse backendPolicy
  ) {
    if (backendPolicy == null) {
      return null;
    }

    UlsCalculatorDto.PolicyResponse uiPolicy = new UlsCalculatorDto.PolicyResponse();

    uiPolicy.policyNumber = backendPolicy.policyNumber;
    uiPolicy.productName = backendPolicy.productName;
    uiPolicy.issuanceDate = backendPolicy.issuanceDate;
    uiPolicy.maturityDate = backendPolicy.maturityDate;
    uiPolicy.frequency = backendPolicy.frequency;
    uiPolicy.initialPremium = backendPolicy.initialPremium;
    uiPolicy.currentPremium = backendPolicy.currentPremium;
    uiPolicy.missedPremiums = backendPolicy.missedPremiums;

    // Backend may use currentUAV, while the UI DTO uses currentUav.
    uiPolicy.currentUav = backendPolicy.currentUAV;

    uiPolicy.totalPaidPremiums = backendPolicy.totalPaidPremiums;

    // Prefer customerName if the backend sends it.
    // Otherwise use lifeInsuredName as a safe display fallback.
    uiPolicy.customerName = firstNonBlank(
      new List<String>{
        backendPolicy.customerName,
        backendPolicy.lifeInsuredName
      }
    );

    // Build a simple age/gender display value if age/gender are provided separately.
    uiPolicy.ageGender = buildAgeGenderDisplay(
      backendPolicy.lifeInsuredAge,
      backendPolicy.lifeInsuredGender
    );

    // Also expose age and gender separately because the AXA-aligned Step 2 UI
    // displays them in separate rows.
    uiPolicy.lifeInsuredAge = backendPolicy.lifeInsuredAge;
    uiPolicy.lifeInsuredGender = backendPolicy.lifeInsuredGender;

    // Keep existing normalized DOB fields.
    uiPolicy.insuredDob = backendPolicy.lifeInsuredDOB;
    uiPolicy.childDob = firstNonBlank(
      new List<String>{
        backendPolicy.nominatedChildDOB,
        backendPolicy.childDOB
      }
    );

    // Also expose backend-style life insured DOB because the AXA-aligned Step 2 UI
    // reads this property directly.
    uiPolicy.lifeInsuredDOB = backendPolicy.lifeInsuredDOB;
    uiPolicy.investmentStrategy = backendPolicy.investmentStrategy;
    uiPolicy.benefits = mapBackendBenefitsToUi(backendPolicy.benefits);
    uiPolicy.investmentFunds = mapBackendInvestmentFundsToUi(
      backendPolicy.investmentFunds
    );

    return uiPolicy;
  }

  /**
   * Maps backend benefits into UI-safe benefit DTOs.
   */
  private static List<UlsCalculatorDto.Benefit> mapBackendBenefitsToUi(
    List<UlsCalculatorDto.BackendBenefit> backendBenefits
  ) {
    List<UlsCalculatorDto.Benefit> uiBenefits = new List<UlsCalculatorDto.Benefit>();

    if (backendBenefits == null) {
      return uiBenefits;
    }

    for (UlsCalculatorDto.BackendBenefit backendBenefit : backendBenefits) {
      if (backendBenefit == null) {
        continue;
      }

      UlsCalculatorDto.Benefit uiBenefit = new UlsCalculatorDto.Benefit();

      uiBenefit.name = backendBenefit.benefitName;
      uiBenefit.amount = backendBenefit.totalSumInsured;
      uiBenefit.description = backendBenefit.description;

      uiBenefits.add(uiBenefit);
    }

    return uiBenefits;
  }

  /**
   * Maps backend investment funds into UI-safe investment fund DTOs.
   */
  private static List<UlsCalculatorDto.InvestmentFund> mapBackendInvestmentFundsToUi(
    List<UlsCalculatorDto.BackendInvestmentFund> backendFunds
  ) {
    List<UlsCalculatorDto.InvestmentFund> uiFunds = new List<UlsCalculatorDto.InvestmentFund>();

    if (backendFunds == null) {
      return uiFunds;
    }

    for (UlsCalculatorDto.BackendInvestmentFund backendFund : backendFunds) {
      if (backendFund == null) {
        continue;
      }

      UlsCalculatorDto.InvestmentFund uiFund = new UlsCalculatorDto.InvestmentFund();

      // Prefer fundId if sent, otherwise use fundCode.
      uiFund.fundId = firstNonBlank(
        new List<String>{ backendFund.fundId, backendFund.fundCode }
      );

      // Prefer explicit fundName, then English name, then Arabic name.
      uiFund.fundName = firstNonBlank(
        new List<String>{
          backendFund.fundName,
          backendFund.nameEn,
          backendFund.nameAr
        }
      );

      uiFund.allocationPercentage = backendFund.allocationPercentage != null
        ? backendFund.allocationPercentage
        : backendFund.percentage;
      uiFund.currentValue = backendFund.currentValue;

      uiFunds.add(uiFund);
    }

    return uiFunds;
  }

  /**
   * Maps backend funds response into UI-safe fund options.
   */
  private static UlsCalculatorDto.FundsResponse mapBackendFundsToUi(
    UlsCalculatorDto.BackendFundsResponse backendFunds
  ) {
    UlsCalculatorDto.FundsResponse uiResponse = new UlsCalculatorDto.FundsResponse();

    uiResponse.funds = new List<UlsCalculatorDto.FundOption>();

    if (backendFunds == null) {
      return uiResponse;
    }

    // Current backend response uses investmentFundTypesAndRatesByCurrencyId.
    // Keep the old funds fallback so older mocks/sandboxes do not break.
    List<UlsCalculatorDto.BackendFundOption> backendFundOptions = backendFunds.investmentFundTypesAndRatesByCurrencyId !=
      null
      ? backendFunds.investmentFundTypesAndRatesByCurrencyId
      : backendFunds.funds;

    if (backendFundOptions == null) {
      return uiResponse;
    }

    for (UlsCalculatorDto.BackendFundOption backendFund : backendFundOptions) {
      if (backendFund == null) {
        continue;
      }

      UlsCalculatorDto.FundOption uiFund = new UlsCalculatorDto.FundOption();

      // Current backend sends numeric id.
      // Older shapes may send fundId or fundCode, so keep those as safe fallbacks.
      uiFund.fundId = backendFund.id != null
        ? String.valueOf(backendFund.id)
        : firstNonBlank(
            new List<String>{ backendFund.fundId, backendFund.fundCode }
          );

      // Current backend sends name.
      // Older shapes may send fundName, nameEn, or nameAr.
      uiFund.fundName = firstNonBlank(
        new List<String>{
          backendFund.name,
          backendFund.fundName,
          backendFund.nameEn,
          backendFund.nameAr
        }
      );

      // Current backend sends lowerRate, centralRate, and upperRate.
      uiFund.lowerRate = backendFund.lowerRate;
      uiFund.centralRate = backendFund.centralRate;
      uiFund.upperRate = backendFund.upperRate;

      // Keep existing UI-safe fields populated for backward compatibility.
      uiFund.lowReturnRate = backendFund.lowerRate != null
        ? backendFund.lowerRate
        : backendFund.lowReturnRate;

      uiFund.highReturnRate = backendFund.upperRate != null
        ? backendFund.upperRate
        : backendFund.highReturnRate;

      uiResponse.funds.add(uiFund);
    }

    return uiResponse;
  }

  /**
   * Maps backend term extension response into UI-safe options.
   */
  private static UlsCalculatorDto.TermExtensionOptionsResponse mapBackendTermExtensionOptionsToUi(
    UlsCalculatorDto.BackendTermExtensionOptionsResponse backendOptions
  ) {
    UlsCalculatorDto.TermExtensionOptionsResponse uiResponse = new UlsCalculatorDto.TermExtensionOptionsResponse();

    if (backendOptions == null) {
      uiResponse.options = new List<Integer>();
      return uiResponse;
    }

    uiResponse.policyNumber = backendOptions.policyNumber;

    // Backend may use availableExtensions, while the UI DTO uses options.
    uiResponse.options = backendOptions.availableExtensions != null
      ? backendOptions.availableExtensions
      : backendOptions.options;

    if (uiResponse.options == null) {
      uiResponse.options = new List<Integer>();
    }

    return uiResponse;
  }

  /**
   * Maps backend document response into UI-safe document DTO.
   */
  private static UlsCalculatorDto.DocumentResponse mapBackendDocumentToUi(
    UlsCalculatorDto.BackendDocumentResponse backendDocument
  ) {
    if (backendDocument == null) {
      return null;
    }

    UlsCalculatorDto.DocumentResponse uiDocument = new UlsCalculatorDto.DocumentResponse();

    uiDocument.documentId = backendDocument.documentId;
    uiDocument.downloadUrl = backendDocument.downloadUrl;
    uiDocument.emailedToClient = backendDocument.emailedToClient;

    // Prefer backend statusMessage, otherwise use fileName as a harmless display fallback.
    uiDocument.statusMessage = firstNonBlank(
      new List<String>{
        backendDocument.statusMessage,
        backendDocument.fileName
      }
    );

    return uiDocument;
  }

  /**
   * Returns the first non-blank value from a list.
   */
  private static String firstNonBlank(List<String> values) {
    if (values == null) {
      return null;
    }

    for (String value : values) {
      if (!String.isBlank(value)) {
        return value;
      }
    }

    return null;
  }

  /**
   * Builds a simple age/gender display value without adding business logic.
   */
  private static String buildAgeGenderDisplay(Integer age, String gender) {
    List<String> displayParts = new List<String>();

    if (age != null) {
      displayParts.add(String.valueOf(age));
    }

    if (!String.isBlank(gender)) {
      displayParts.add(gender);
    }

    if (displayParts.isEmpty()) {
      return null;
    }

    return String.join(displayParts, ' / ');
  }

  // =====================================================================================
  // Response builders
  // =====================================================================================

  /**
   * Builds a safe success response for LWC.
   */
  private static UlsCalculatorDto.ApiResponse buildSuccessResponse(
    Object data,
    String correlationId
  ) {
    UlsCalculatorDto.ApiResponse response = new UlsCalculatorDto.ApiResponse();

    response.success = true;
    response.data = data;
    response.errorCode = null;
    response.userMessage = null;
    response.correlationId = correlationId;
    response.supportDetails = null;

    return response;
  }

  /**
   * Builds a safe error response and writes an operational log.
   */
  private static UlsCalculatorDto.ApiResponse buildAndLogErrorResponse(
    String operationName,
    String direction,
    String endpoint,
    String httpMethod,
    Integer httpStatusCode,
    Long durationMs,
    String errorCode,
    String errorCategory,
    String userMessage,
    String correlationId,
    String policyNumber,
    String supportDetails
  ) {
    ServiceConfig config = loadConfig();

    UlsCalculatorDto.ApiResponse response = new UlsCalculatorDto.ApiResponse();

    response.success = false;
    response.data = null;
    response.errorCode = errorCode;
    response.userMessage = userMessage;
    response.correlationId = correlationId;

    response.supportDetails = config.enableDetailedLogging
      ? sanitizeForSupport(supportDetails)
      : null;

    writeOperationLog(
      operationName,
      direction,
      endpoint,
      httpMethod,
      httpStatusCode,
      durationMs,
      false,
      errorCode,
      errorCategory,
      userMessage,
      correlationId,
      policyNumber,
      supportDetails
    );

    return response;
  }

  // =====================================================================================
  // Config helpers
  // =====================================================================================

  /**
   * Loads service config from UlsCalculatorConfig__mdt.
   */
  private static ServiceConfig loadConfig() {
    ServiceConfig config = new ServiceConfig();

    config.isCalculatorEnabled = true;
    config.isDocumentGenerationEnabled = false;
    config.enableDetailedLogging = false;
    config.includeSuccessLogs = false;
    config.timeoutMs = DEFAULT_TIMEOUT_MS;

    UlsCalculatorConfig__mdt metadataRecord = UlsCalculatorConfig__mdt.getInstance(
      'Default'
    );

    if (metadataRecord != null) {
      config.isCalculatorEnabled = metadataRecord.IsCalculatorEnabled__c;
      config.isDocumentGenerationEnabled = metadataRecord.IsDocumentGenerationEnabled__c;
      config.enableDetailedLogging = metadataRecord.EnableDetailedLogging__c;
      config.includeSuccessLogs = metadataRecord.IncludeSuccessLogs__c;

      if (
        metadataRecord.CalloutTimeoutMs__c != null &&
        metadataRecord.CalloutTimeoutMs__c > 0
      ) {
        config.timeoutMs = Integer.valueOf(metadataRecord.CalloutTimeoutMs__c);
      }
    }

    if (testCalculatorEnabledOverride != null) {
      config.isCalculatorEnabled = testCalculatorEnabledOverride;
    }

    if (testDocumentGenerationEnabledOverride != null) {
      config.isDocumentGenerationEnabled = testDocumentGenerationEnabledOverride;
    }

    if (testDetailedLoggingOverride != null) {
      config.enableDetailedLogging = testDetailedLoggingOverride;
    }

    if (testIncludeSuccessLogsOverride != null) {
      config.includeSuccessLogs = testIncludeSuccessLogsOverride;
    }

    if (testTimeoutMsOverride != null && testTimeoutMsOverride > 0) {
      config.timeoutMs = testTimeoutMsOverride;
    }

    return config;
  }

  /**
   * Resets test-only overrides.
   */
  @TestVisible
  private static void resetTestOverrides() {
    testCalculatorEnabledOverride = null;
    testDocumentGenerationEnabledOverride = null;
    testDetailedLoggingOverride = null;
    testIncludeSuccessLogsOverride = null;
    testTimeoutMsOverride = null;
  }

  // =====================================================================================
  // Error mapping helpers
  // =====================================================================================

  /**
   * Maps backend error codes and HTTP statuses into user-safe messages.
   */
  private static MappedError mapBackendError(
    String backendErrorCode,
    Integer httpStatusCode
  ) {
    if (backendErrorCode == 'INVALID_POLICY_FORMAT') {
      return new MappedError(
        'INVALID_POLICY_FORMAT',
        'Validation',
        'Please enter a valid policy number.'
      );
    }

    if (backendErrorCode == 'POLICY_NOT_FOUND') {
      return new MappedError(
        'POLICY_NOT_FOUND',
        'NotFound',
        'Policy not found. Please check the policy number and try again.'
      );
    }

    if (backendErrorCode == 'INVALID_PRODUCT_TYPE') {
      return new MappedError(
        'INVALID_PRODUCT_TYPE',
        'UnsupportedProduct',
        'Policy does not belong to a ULS product.'
      );
    }

    if (backendErrorCode == 'UNAUTHORIZED' || httpStatusCode == 401) {
      return new MappedError(
        'BACKEND_UNAUTHORIZED',
        'Unauthorized',
        'The calculator cannot connect to the backend service. Please contact support.'
      );
    }

    if (httpStatusCode == 403) {
      return new MappedError(
        'BACKEND_FORBIDDEN',
        'Forbidden',
        'The backend service rejected the request. Please contact support.'
      );
    }

    if (backendErrorCode == 'INFLATION_RATE_UNAVAILABLE') {
      return new MappedError(
        'INFLATION_RATE_UNAVAILABLE',
        'BackendUnavailable',
        'Inflation rate could not be retrieved. Please try again or contact support.'
      );
    }

    if (backendErrorCode == 'INVALID_INPUT') {
      return new MappedError(
        'INVALID_INPUT',
        'Validation',
        'Please verify the entered values and try again.'
      );
    }

    if (backendErrorCode == 'PREMIUM_OUT_OF_RANGE') {
      return new MappedError(
        'PREMIUM_OUT_OF_RANGE',
        'Validation',
        'The requested premium is outside the allowed range.'
      );
    }

    if (backendErrorCode == 'INVALID_FUND_ALLOCATION') {
      return new MappedError(
        'INVALID_FUND_ALLOCATION',
        'Validation',
        'Fund allocation must equal 100%.'
      );
    }

    if (backendErrorCode == 'NO_ALTERATIONS_PROVIDED') {
      return new MappedError(
        'NO_ALTERATIONS_PROVIDED',
        'Validation',
        'Please select at least one alteration before generating the review.'
      );
    }

    if (backendErrorCode == 'INVALID_ASP_AMOUNT') {
      return new MappedError(
        'INVALID_ASP_AMOUNT',
        'Validation',
        'Please enter a valid positive ASP amount.'
      );
    }

    if (backendErrorCode == 'NO_FUND_SELECTED') {
      return new MappedError(
        'NO_FUND_SELECTED',
        'Validation',
        'Please select at least one fund for the enabled alteration.'
      );
    }

    if (backendErrorCode == 'INVALID_TERM_EXTENSION') {
      return new MappedError(
        'INVALID_TERM_EXTENSION',
        'Validation',
        'The selected term extension is not valid for this policy.'
      );
    }

    if (backendErrorCode == 'CALCULATION_FAILURE') {
      return new MappedError(
        'CALCULATION_FAILURE',
        'CalculationFailure',
        'Unable to complete the calculation. Please verify inputs and try again.'
      );
    }

    if (backendErrorCode == 'FUNDS_UNAVAILABLE') {
      return new MappedError(
        'FUNDS_UNAVAILABLE',
        'BackendUnavailable',
        'Funds could not be retrieved. Please try again or contact support.'
      );
    }

    if (backendErrorCode == 'NO_VALID_EXTENSIONS') {
      return new MappedError(
        'NO_VALID_EXTENSIONS',
        'Validation',
        'No valid term extension options are available for this policy.'
      );
    }

    if (backendErrorCode == 'PDF_SERVICE_UNAVAILABLE') {
      return new MappedError(
        'PDF_SERVICE_UNAVAILABLE',
        'DocumentFailure',
        'Document generation is temporarily unavailable.'
      );
    }

    if (backendErrorCode == 'ATTACHMENTS_UNAVAILABLE') {
      return new MappedError(
        'ATTACHMENTS_UNAVAILABLE',
        'DocumentFailure',
        'Optional attachments could not be retrieved. Please try again or contact support.'
      );
    }

    if (backendErrorCode == 'NO_DOCUMENTS_SELECTED') {
      return new MappedError(
        'NO_DOCUMENTS_SELECTED',
        'Validation',
        'Please select at least one document to generate.'
      );
    }

    if (backendErrorCode == 'INVALID_ATTACHMENT_IDS') {
      return new MappedError(
        'INVALID_ATTACHMENT_IDS',
        'Validation',
        'One or more selected attachments are invalid. Please refresh and try again.'
      );
    }

    if (backendErrorCode == 'MISSING_OWNER_DATA') {
      return new MappedError(
        'MISSING_OWNER_DATA',
        'Validation',
        'Required policy owner data is missing. Please contact support.'
      );
    }

    if (
      backendErrorCode == 'EMAIN_NOT_SENT' ||
      backendErrorCode == 'EMAIL_NOT_SENT'
    ) {
      return new MappedError(
        'EMAIL_NOT_SENT',
        'DocumentFailure',
        'Package was generated, but email could not be sent to the client. Please contact support.'
      );
    }

    if (httpStatusCode == 429) {
      return new MappedError(
        'BACKEND_RATE_LIMITED',
        'BackendUnavailable',
        'The backend service is busy. Please try again later.'
      );
    }

    if (httpStatusCode == 503) {
      return new MappedError(
        'BACKEND_UNAVAILABLE',
        'BackendUnavailable',
        'The backend service is temporarily unavailable. Please try again later.'
      );
    }

    if (httpStatusCode != null && httpStatusCode >= 500) {
      return new MappedError(
        'BACKEND_SERVER_ERROR',
        'BackendUnavailable',
        'The backend service returned an error. Please try again later or contact support.'
      );
    }

    return new MappedError(
      'UNEXPECTED_SERVER_ERROR',
      'Unexpected',
      'Something went wrong while processing your request. Please try again or contact support.'
    );
  }

  /**
   * Parses backend standard error response safely.
   */
  private static BackendError parseBackendError(String responseBody) {
    if (String.isBlank(responseBody)) {
      return null;
    }

    try {
      return (BackendError) JSON.deserialize(responseBody, BackendError.class);
    } catch (Exception ex) {
      return null;
    }
  }

  // =====================================================================================
  // Validation helpers
  // =====================================================================================

  /**
   * Basic policy number validation.
   *
   * We only validate obvious issues here.
   * Backend remains the final authority for real format/business validation.
   */
  private static String validatePolicyNumber(String policyNumber) {
    if (String.isBlank(policyNumber)) {
      return 'Please enter a policy number.';
    }

    Pattern numericPolicyPattern = Pattern.compile('^[0-9]{1,10}$');
    if (!numericPolicyPattern.matcher(policyNumber).matches()) {
      return 'Please check Policy number format';
    }

    return null;
  }

  /**
   * Basic alteration request validation.
   *
   * This is intentionally light in Step 10.
   * More detailed validation can be added after we confirm exact DTO field names and UI behavior.
   */
  private static String validateAlterationRequest(Object request) {
    if (request == null) {
      return 'Please select at least one alteration before generating the review.';
    }

    String policyNumber = extractStringField(request, 'policyNumber');
    String policyValidation = validatePolicyNumber(policyNumber);

    if (policyValidation != null) {
      return policyValidation;
    }

    Map<String, Object> requestMap = toMap(request);

    Boolean hasAnyAlteration =
      hasNonNullField(requestMap, 'fundSwitch') ||
      hasNonNullField(requestMap, 'asp') ||
      hasNonNullField(requestMap, 'premiumRedirection') ||
      hasNonNullField(requestMap, 'premiumChange') ||
      hasNonNullField(requestMap, 'termExtension');

    if (!hasAnyAlteration) {
      return 'Please select at least one alteration before generating the review.';
    }

    return null;
  }

  // =====================================================================================
  // DTO extraction helpers
  // =====================================================================================

  /**
   * Converts any DTO into a map so we can safely inspect fields.
   */
  private static Map<String, Object> toMap(Object value) {
    if (value == null) {
      return new Map<String, Object>();
    }

    Object rawValue = JSON.deserializeUntyped(JSON.serialize(value));

    if (rawValue instanceof Map<String, Object>) {
      return (Map<String, Object>) rawValue;
    }

    return new Map<String, Object>();
  }

  /**
   * Extracts a string field from a DTO by field name.
   */
  private static String extractStringField(Object value, String fieldName) {
    Map<String, Object> valueMap = toMap(value);

    if (!valueMap.containsKey(fieldName) || valueMap.get(fieldName) == null) {
      return null;
    }

    return String.valueOf(valueMap.get(fieldName));
  }

  /**
   * Extracts a decimal field from a DTO by field name.
   */
  private static Decimal extractDecimalField(Object value, String fieldName) {
    Map<String, Object> valueMap = toMap(value);

    if (!valueMap.containsKey(fieldName) || valueMap.get(fieldName) == null) {
      return null;
    }

    try {
      return Decimal.valueOf(String.valueOf(valueMap.get(fieldName)));
    } catch (Exception ex) {
      return null;
    }
  }

  /**
   * Checks whether a map has a non-null field.
   */
  private static Boolean hasNonNullField(
    Map<String, Object> valueMap,
    String fieldName
  ) {
    return valueMap != null &&
      valueMap.containsKey(fieldName) &&
      valueMap.get(fieldName) != null;
  }

  // =====================================================================================
  // Logging helpers
  // =====================================================================================

  /**
   * Writes a production-safe operational log.
   *
   * Assumption:
   * Your existing logger has:
   * - UlsCalculatorLogger.LogInput
   * - UlsCalculatorLogger.log(LogInput)
   *
   * If deployment fails because the logger method/field names are different,
   * only this method should need adjustment.
   */
  private static void writeOperationLog(
    String operationName,
    String direction,
    String endpoint,
    String httpMethod,
    Integer httpStatusCode,
    Long durationMs,
    Boolean success,
    String errorCode,
    String errorCategory,
    String sanitizedMessage,
    String correlationId,
    String policyNumber,
    String detailedLog
  ) {
    try {
      // Load the same service configuration used by the calculator flow.
      // This is where IncludeSuccessLogs__c and EnableDetailedLogging__c are read.
      ServiceConfig config = loadConfig();

      // Create the logger input wrapper.
      UlsCalculatorLogger.LogInput input = new UlsCalculatorLogger.LogInput();

      // Store the support correlation ID.
      input.correlationId = correlationId;

      // Store the logical operation name.
      input.operationName = operationName;

      // Store the operation direction, for example LWC_TO_APEX or APEX_TO_BACKEND.
      input.direction = direction;

      // Store the logical endpoint path.
      input.endpoint = endpoint;

      // Store the HTTP method when applicable.
      input.httpMethod = httpMethod;

      // Store the backend HTTP status code when applicable.
      input.httpStatusCode = httpStatusCode;

      // Store the measured duration.
      input.durationMs = durationMs;

      // Store whether the operation succeeded.
      input.success = success;

      // Store the safe application/backend error code.
      input.errorCode = errorCode;

      // Store the safe error category.
      input.errorCategory = errorCategory;

      // Store the user-safe or support-safe message after secret redaction.
      input.sanitizedMessage = sanitizeForSupport(sanitizedMessage);

      // Store the full policy number for IT Support troubleshooting.
      input.policyNumber = policyNumber;

      // Pass IncludeSuccessLogs__c into the logger.
      // The logger uses this to skip success logs unless explicitly enabled.
      input.includeSuccessLogs = config.includeSuccessLogs;

      // Pass EnableDetailedLogging__c into the logger.
      // The logger uses this to decide whether Detailed_Log__c should be populated.
      input.enableDetailedLogging = config.enableDetailedLogging;

      // Only pass detailed text when detailed logging is enabled.
      // This reduces accidental storage of unnecessary details.
      input.detailedLog = config.enableDetailedLogging
        ? sanitizeForSupport(detailedLog)
        : null;

      // Write the log record.
      // The logger itself also protects the calculator flow from logging failures.
      UlsCalculatorLogger.log(input);
    } catch (Exception ex) {
      /*
       * Logging must never break the calculator flow.
       * This intentionally swallows logging errors.
       */
    }
  }

  // =====================================================================================
  // Safety helpers
  // =====================================================================================

  /**
   * Ensures every operation has a correlation ID.
   */
  private static String ensureCorrelationId(String correlationId) {
    if (!String.isBlank(correlationId)) {
      return correlationId;
    }

    return UlsCalculatorLogger.generateCorrelationId();
  }

  /**
   * Basic timeout message detector.
   */
  private static Boolean isTimeoutMessage(String message) {
    if (String.isBlank(message)) {
      return false;
    }

    String lowerMessage = message.toLowerCase();

    return lowerMessage.contains('timeout') ||
      lowerMessage.contains('timed out') ||
      lowerMessage.contains('read timed out');
  }

  /**
   * Extra secret redaction before support details/log details are passed around.
   *
   * The logger also redacts secrets, but this adds defense-in-depth.
   */
  private static String sanitizeForSupport(String value) {
    if (String.isBlank(value)) {
      return value;
    }

    String sanitizedValue = value;

    sanitizedValue = sanitizedValue.replaceAll(
      '(?i)Bearer\\s+[A-Za-z0-9._\\-]+',
      'Bearer [REDACTED]'
    );
    sanitizedValue = sanitizedValue.replaceAll(
      '(?i)(client_secret\\s*[=:]\\s*)[^\\s,}]+',
      '$1[REDACTED]'
    );
    sanitizedValue = sanitizedValue.replaceAll(
      '(?i)(access_token\\s*[=:]\\s*)[^\\s,}]+',
      '$1[REDACTED]'
    );
    sanitizedValue = sanitizedValue.replaceAll(
      '(?i)(refresh_token\\s*[=:]\\s*)[^\\s,}]+',
      '$1[REDACTED]'
    );
    sanitizedValue = sanitizedValue.replaceAll(
      '(?i)(password\\s*[=:]\\s*)[^\\s,}]+',
      '$1[REDACTED]'
    );

    return sanitizedValue;
  }
}
