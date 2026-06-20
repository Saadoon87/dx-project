/**
 * UlsCalculatorController
 *
 * Purpose:
 * - This is the LWC-facing Apex controller for the ULS Calculator.
 * - The Lightning Web Component will call this class.
 * - This class should stay thin and simple.
 *
 * Responsibilities:
 * - Generate a correlation ID for each LWC request.
 * - Delegate work to UlsCalculatorService.
 * - Return safe UlsCalculatorDto.ApiResponse objects to the LWC.
 *
 * Important:
 * - Do not place backend callout logic here.
 * - Do not place ULS calculation logic here.
 * - Do not expose raw backend errors to the browser.
 */
public with sharing class UlsCalculatorController {

    /**
     * Retrieves policy/client data by policy number.
     *
     * Called by:
     * - Step 1: Policy Retrieval
     */
    @AuraEnabled
    public static UlsCalculatorDto.ApiResponse retrievePolicy(String policyNumber) {
        String correlationId = UlsCalculatorLogger.generateCorrelationId();

        try {
            return UlsCalculatorService.retrievePolicy(policyNumber, correlationId);
        } catch (Exception ex) {
            return buildUnexpectedControllerError('retrievePolicy', correlationId, policyNumber, ex);
        }
    }

    /**
     * Retrieves the configured inflation rate from backend.
     *
     * Called by:
     * - Step 2: Define Goal
     */
    @AuraEnabled
    public static UlsCalculatorDto.ApiResponse getInflationRate() {
        String correlationId = UlsCalculatorLogger.generateCorrelationId();

        try {
            return UlsCalculatorService.getInflationRate(correlationId);
        } catch (Exception ex) {
            return buildUnexpectedControllerError('getInflationRate', correlationId, null, ex);
        }
    }

    /**
     * Calculates inflation-adjusted UAV through backend.
     *
     * Called by:
     * - Step 2: Calculate Inflation-Adjusted UAV button
     */
    @AuraEnabled
    public static UlsCalculatorDto.ApiResponse calculateInflationAdjustedUav(
        UlsCalculatorDto.InflationAdjustedUavRequest request
    ) {
        String correlationId = UlsCalculatorLogger.generateCorrelationId();
        String policyNumber = extractPolicyNumber(request);

        try {
            return UlsCalculatorService.calculateInflationAdjustedUav(request, correlationId);
        } catch (Exception ex) {
            return buildUnexpectedControllerError('calculateInflationAdjustedUav', correlationId, policyNumber, ex);
        }
    }

    /**
     * Calculates suggested premium through backend.
     *
     * Called by:
     * - Step 2: Calculate Suggested Premium button
     */
    @AuraEnabled
    public static UlsCalculatorDto.ApiResponse calculateSuggestedPremium(
        UlsCalculatorDto.SuggestedPremiumRequest request
    ) {
        String correlationId = UlsCalculatorLogger.generateCorrelationId();
        String policyNumber = extractPolicyNumber(request);

        try {
            return UlsCalculatorService.calculateSuggestedPremium(request, correlationId);
        } catch (Exception ex) {
            return buildUnexpectedControllerError('calculateSuggestedPremium', correlationId, policyNumber, ex);
        }
    }

    /**
     * Calculates final UAV based on requested premium through backend.
     *
     * Called by:
     * - Step 2: Recalculate Final UAV button
     */
    @AuraEnabled
    public static UlsCalculatorDto.ApiResponse calculateFinalUav(
        UlsCalculatorDto.FinalUavRequest request
    ) {
        String correlationId = UlsCalculatorLogger.generateCorrelationId();
        String policyNumber = extractPolicyNumber(request);

        try {
            return UlsCalculatorService.calculateFinalUav(request, correlationId);
        } catch (Exception ex) {
            return buildUnexpectedControllerError('calculateFinalUav', correlationId, policyNumber, ex);
        }
    }

    /**
     * Retrieves available investment funds from backend.
     *
     * Called by:
     * - Step 3: Apply Alterations
     */
    @AuraEnabled
    public static UlsCalculatorDto.ApiResponse getFunds() {
        String correlationId = UlsCalculatorLogger.generateCorrelationId();

        try {
            return UlsCalculatorService.getFunds(correlationId);
        } catch (Exception ex) {
            return buildUnexpectedControllerError('getFunds', correlationId, null, ex);
        }
    }

    /**
     * Retrieves valid term extension options for a policy.
     *
     * Called by:
     * - Step 3: Apply Alterations
     */
    @AuraEnabled
    public static UlsCalculatorDto.ApiResponse getTermExtensionOptions(String policyNumber) {
        String correlationId = UlsCalculatorLogger.generateCorrelationId();

        try {
            return UlsCalculatorService.getTermExtensionOptions(policyNumber, correlationId);
        } catch (Exception ex) {
            return buildUnexpectedControllerError('getTermExtensionOptions', correlationId, policyNumber, ex);
        }
    }

    /**
     * Generates the consolidated projection/review through backend.
     *
     * Called by:
     * - Step 4: Consolidated Review
     */
    @AuraEnabled
    public static UlsCalculatorDto.ApiResponse generateProjection(
        UlsCalculatorDto.AlterationRequest request
    ) {
        String correlationId = UlsCalculatorLogger.generateCorrelationId();
        String policyNumber = extractPolicyNumber(request);

        try {
            return UlsCalculatorService.generateProjection(request, correlationId);
        } catch (Exception ex) {
            return buildUnexpectedControllerError('generateProjection', correlationId, policyNumber, ex);
        }
    }

    /**
     * Generates projection PDF through backend.
     *
     * Called by:
     * - Step 5: Generated Package
     *
     * Controlled by:
     * - IsDocumentGenerationEnabled__c
     */
    @AuraEnabled
    public static UlsCalculatorDto.ApiResponse generateProjectionPdf(
        UlsCalculatorDto.ProjectionPdfRequest request
    ) {
        String correlationId = UlsCalculatorLogger.generateCorrelationId();
        String policyNumber = extractPolicyNumber(request);

        try {
            return UlsCalculatorService.generateProjectionPdf(request, correlationId);
        } catch (Exception ex) {
            return buildUnexpectedControllerError('generateProjectionPdf', correlationId, policyNumber, ex);
        }
    }

    /**
     * Retrieves optional attachment templates from backend.
     *
     * Called by:
     * - Step 5: Generated Package
     *
     * Controlled by:
     * - IsDocumentGenerationEnabled__c
     */
    @AuraEnabled
    public static UlsCalculatorDto.ApiResponse getAttachments() {
        String correlationId = UlsCalculatorLogger.generateCorrelationId();

        try {
            return UlsCalculatorService.getAttachments(correlationId);
        } catch (Exception ex) {
            return buildUnexpectedControllerError('getAttachments', correlationId, null, ex);
        }
    }

    /**
     * Generates final PDF/package through backend.
     *
     * Called by:
     * - Step 5: Generated Package
     *
     * Controlled by:
     * - IsDocumentGenerationEnabled__c
     */
    @AuraEnabled
    public static UlsCalculatorDto.ApiResponse generateFinalPdf(
        UlsCalculatorDto.FinalPdfRequest request
    ) {
        String correlationId = UlsCalculatorLogger.generateCorrelationId();
        String policyNumber = extractPolicyNumber(request);

        try {
            return UlsCalculatorService.generateFinalPdf(request, correlationId);
        } catch (Exception ex) {
            return buildUnexpectedControllerError('generateFinalPdf', correlationId, policyNumber, ex);
        }
    }

    /**
     * Builds a safe unexpected error response for controller-level failures.
     *
     * This should be rare because the service already catches most expected errors.
     * Still, this protects the LWC from raw Apex exception details.
     */
    private static UlsCalculatorDto.ApiResponse buildUnexpectedControllerError(
        String operationName,
        String correlationId,
        String policyNumber,
        Exception ex
    ) {
        UlsCalculatorDto.ApiResponse response = new UlsCalculatorDto.ApiResponse();

        response.success = false;
        response.data = null;
        response.errorCode = 'UNEXPECTED_SERVER_ERROR';
        response.userMessage = 'Something went wrong while processing your request. Please try again or contact support.';
        response.correlationId = correlationId;
        response.supportDetails = null;

        writeControllerErrorLog(operationName, correlationId, policyNumber, ex);

        return response;
    }

    /**
     * Logs unexpected controller-level errors.
     *
     * Logging must never break the user flow, so this method catches its own errors.
     */
    private static void writeControllerErrorLog(
        String operationName,
        String correlationId,
        String policyNumber,
        Exception ex
    ) {
        try {
            UlsCalculatorLogger.LogInput input = new UlsCalculatorLogger.LogInput();

            input.correlationId = correlationId;
            input.operationName = operationName;
            input.direction = 'LWC_TO_APEX';
            input.endpoint = 'UlsCalculatorController';
            input.httpMethod = null;
            input.httpStatusCode = null;
            input.durationMs = 0;
            input.success = false;
            input.errorCode = 'UNEXPECTED_SERVER_ERROR';
            input.errorCategory = 'Unexpected';
            input.sanitizedMessage = 'Unexpected controller error.';
            input.policyNumber = policyNumber;
            input.detailedLog = ex == null ? null : ex.getMessage();

            UlsCalculatorLogger.log(input);
        } catch (Exception loggingException) {
            /*
             * Do nothing.
             * Logging failures should never affect the calculator.
             */
        }
    }

    /**
     * Extracts policyNumber from any request DTO.
     *
     * This avoids duplicating policyNumber extraction logic for each request type.
     */
    private static String extractPolicyNumber(Object request) {
        if (request == null) {
            return null;
        }

        try {
            Map<String, Object> requestMap =
                (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(request));

            if (requestMap.containsKey('policyNumber') && requestMap.get('policyNumber') != null) {
                return String.valueOf(requestMap.get('policyNumber'));
            }
        } catch (Exception ex) {
            return null;
        }

        return null;
    }
}