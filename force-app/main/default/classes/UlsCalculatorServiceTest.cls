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

        System.Assert.areEqual(false, response.success, 'Blank policy number should fail.');
        System.Assert.areEqual('INVALID_POLICY_FORMAT', response.errorCode, 'Expected validation error code.');
        System.Assert.areEqual('TEST-CORR-001', response.correlationId, 'Correlation ID should be preserved.');

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

        System.Assert.areEqual(false, response.success, 'Disabled calculator should fail safely.');
        System.Assert.areEqual('CALCULATOR_DISABLED', response.errorCode, 'Expected calculator disabled error.');
        System.Assert.areEqual('TEST-CORR-002', response.correlationId, 'Correlation ID should be preserved.');

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
            new UlsHttpCalloutMock(
                200,
                UlsMockDataFactory.inflationRateSuccessJson()
            )
        );

        Test.startTest();
        UlsCalculatorDto.ApiResponse response = UlsCalculatorService.getInflationRate('TEST-CORR-003');
        Test.stopTest();

        System.Assert.areEqual(true, response.success, 'Successful backend response should return success=true.');
        System.Assert.areEqual(null, response.errorCode, 'Successful response should not have an error code.');
        System.Assert.areEqual('TEST-CORR-003', response.correlationId, 'Correlation ID should be preserved.');
        System.Assert.areNotEqual(null, response.data, 'Response data should be populated.');

        HttpRequest lastRequest = UlsHttpCalloutMock.getLastRequest();

        System.Assert.areNotEqual(null, lastRequest, 'The mock should capture the backend request.');
        System.Assert.areEqual('GET', lastRequest.getMethod(), 'Inflation rate should use GET.');
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
        UlsCalculatorDto.ApiResponse response = UlsCalculatorService.getInflationRate('TEST-CORR-004');
        Test.stopTest();

        System.Assert.areEqual(false, response.success, 'Backend error should return success=false.');
        System.Assert.areEqual('INFLATION_RATE_UNAVAILABLE', response.errorCode, 'Backend error should map to safe error code.');
        System.Assert.areEqual('TEST-CORR-004', response.correlationId, 'Correlation ID should be preserved.');

        HttpRequest lastRequest = UlsHttpCalloutMock.getLastRequest();

        System.Assert.areNotEqual(null, lastRequest, 'The mock should capture the backend request.');
        System.Assert.areEqual('GET', lastRequest.getMethod(), 'Inflation rate should use GET.');

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

        System.Assert.areEqual(false, response.success, 'Disabled document generation should fail safely.');
        System.Assert.areEqual('DOCUMENT_GENERATION_DISABLED', response.errorCode, 'Expected document disabled error.');
        System.Assert.areEqual('TEST-CORR-005', response.correlationId, 'Correlation ID should be preserved.');

        UlsCalculatorService.resetTestOverrides();
    }
}