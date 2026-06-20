/**
 * UlsCalculatorControllerTest
 *
 * Purpose:
 * - Tests the thin LWC-facing controller.
 * - Confirms the controller delegates safely to UlsCalculatorService.
 * - Confirms safe ApiResponse objects are returned.
 */
@IsTest
private class UlsCalculatorControllerTest {

    /**
     * Simple HTTP mock used by controller tests.
     *
     * We are keeping it inside this test class for now.
     * Later, we can move shared mocks into UlsHttpCalloutMock.cls.
     */
    private class SimpleHttpMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        SimpleHttpMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();

            response.setStatusCode(statusCode);
            response.setHeader('Content-Type', 'application/json');
            response.setBody(responseBody);

            return response;
        }
    }

    /**
     * Test:
     * Blank policy number should return a safe validation error.
     */
    @IsTest
    static void retrievePolicy_blankPolicy_returnsValidationError() {
        UlsCalculatorService.resetTestOverrides();

        UlsCalculatorService.testCalculatorEnabledOverride = true;

        UlsCalculatorDto.ApiResponse response = UlsCalculatorController.retrievePolicy('');

        System.Assert.areEqual(false, response.success, 'Blank policy number should fail.');
        System.Assert.areEqual('INVALID_POLICY_FORMAT', response.errorCode, 'Expected policy validation error.');
        System.Assert.areNotEqual(null, response.correlationId, 'Controller should generate a correlation ID.');

        UlsCalculatorService.resetTestOverrides();
    }

    /**
     * Test:
     * Calculator kill switch should return a safe disabled error.
     */
    @IsTest
    static void retrievePolicy_calculatorDisabled_returnsDisabledError() {
        UlsCalculatorService.resetTestOverrides();

        UlsCalculatorService.testCalculatorEnabledOverride = false;

        UlsCalculatorDto.ApiResponse response = UlsCalculatorController.retrievePolicy('POL12345');

        System.Assert.areEqual(false, response.success, 'Disabled calculator should fail safely.');
        System.Assert.areEqual('CALCULATOR_DISABLED', response.errorCode, 'Expected calculator disabled error.');
        System.Assert.areNotEqual(null, response.correlationId, 'Controller should generate a correlation ID.');

        UlsCalculatorService.resetTestOverrides();
    }

    /**
     * Test:
     * Successful backend response should return success=true.
     */
    @IsTest
    static void getInflationRate_success_returnsSuccessResponse() {
        UlsCalculatorService.resetTestOverrides();

        UlsCalculatorService.testCalculatorEnabledOverride = true;
        UlsCalculatorService.testIncludeSuccessLogsOverride = false;

        Test.setMock(
            HttpCalloutMock.class,
            new SimpleHttpMock(
                200,
                '{"inflationRate":5.0}'
            )
        );

        Test.startTest();
        UlsCalculatorDto.ApiResponse response = UlsCalculatorController.getInflationRate();
        Test.stopTest();

        System.Assert.areEqual(true, response.success, 'Successful backend response should return success=true.');
        System.Assert.areEqual(null, response.errorCode, 'Successful response should not have an error code.');
        System.Assert.areNotEqual(null, response.correlationId, 'Controller should generate a correlation ID.');
        System.Assert.areNotEqual(null, response.data, 'Successful response should include data.');

        UlsCalculatorService.resetTestOverrides();
    }

    /**
     * Test:
     * Backend error response should be mapped to a safe error.
     */
    @IsTest
    static void getInflationRate_backendError_returnsSafeError() {
        UlsCalculatorService.resetTestOverrides();

        UlsCalculatorService.testCalculatorEnabledOverride = true;

        Test.setMock(
            HttpCalloutMock.class,
            new SimpleHttpMock(
                503,
                '{"errorCode":"INFLATION_RATE_UNAVAILABLE","message":"Inflation source unavailable."}'
            )
        );

        Test.startTest();
        UlsCalculatorDto.ApiResponse response = UlsCalculatorController.getInflationRate();
        Test.stopTest();

        System.Assert.areEqual(false, response.success, 'Backend error should return success=false.');
        System.Assert.areEqual('INFLATION_RATE_UNAVAILABLE', response.errorCode, 'Expected mapped backend error.');
        System.Assert.areNotEqual(null, response.correlationId, 'Controller should generate a correlation ID.');

        UlsCalculatorService.resetTestOverrides();
    }

    /**
     * Test:
     * Document generation kill switch should block document operations.
     */
    @IsTest
    static void generateFinalPdf_documentDisabled_returnsDisabledError() {
        UlsCalculatorService.resetTestOverrides();

        UlsCalculatorService.testCalculatorEnabledOverride = true;
        UlsCalculatorService.testDocumentGenerationEnabledOverride = false;

        UlsCalculatorDto.FinalPdfRequest request = new UlsCalculatorDto.FinalPdfRequest();

        UlsCalculatorDto.ApiResponse response = UlsCalculatorController.generateFinalPdf(request);

        System.Assert.areEqual(false, response.success, 'Disabled document generation should fail safely.');
        System.Assert.areEqual('DOCUMENT_GENERATION_DISABLED', response.errorCode, 'Expected document generation disabled error.');
        System.Assert.areNotEqual(null, response.correlationId, 'Controller should generate a correlation ID.');

        UlsCalculatorService.resetTestOverrides();
    }
}