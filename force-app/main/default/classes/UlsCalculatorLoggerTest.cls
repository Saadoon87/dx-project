/**
 * Unit tests for UlsCalculatorLogger.
 *
 * These tests verify:
 * - Correlation ID generation.
 * - Legacy policy masking helper.
 * - Failure logs are inserted.
 * - Full policy number is stored for IT Support.
 * - Success logs are skipped when disabled.
 * - Success logs are inserted when enabled.
 * - Secrets are redacted.
 * - Business data is not masked based on the updated support requirement.
 */
@IsTest
private class UlsCalculatorLoggerTest {

    /**
     * Verifies that a correlation ID is generated and starts with ULS-.
     */
    @IsTest
    static void generateCorrelationId_ReturnsReadableUlsId() {

        // Generate a correlation ID.
        String correlationId = UlsCalculatorLogger.generateCorrelationId();

        // Confirm the value is not null.
        System.assertNotEquals(
            null,
            correlationId,
            'Correlation ID should not be null.'
        );

        // Confirm the ID starts with our project prefix.
        System.assert(
            correlationId.startsWith('ULS-'),
            'Correlation ID should start with ULS-.'
        );
    }

    /**
     * Verifies the legacy masking helper still works.
     *
     * Active logging does not use this anymore, but we keep the helper available.
     */
    @IsTest
    static void maskPolicyNumber_LegacyHelper_MasksAllButLastFourCharacters() {

        // Mask a sample policy number.
        String maskedPolicyNumber = UlsCalculatorLogger.maskPolicyNumber('POL123456789');

        // Confirm only the last four characters are visible.
        System.assertEquals(
            '****6789',
            maskedPolicyNumber,
            'Legacy helper should mask except the last four characters.'
        );
    }

    /**
     * Verifies the legacy masking helper fully masks short values.
     */
    @IsTest
    static void maskPolicyNumber_LegacyHelper_FullyMasksShortValues() {

        // Mask a short policy number.
        String maskedPolicyNumber = UlsCalculatorLogger.maskPolicyNumber('123');

        // Confirm no original characters are visible.
        System.assertEquals(
            '****',
            maskedPolicyNumber,
            'Legacy helper should fully mask short policy numbers.'
        );
    }

    /**
     * Verifies that failure logs are inserted and store full policy number.
     */
    @IsTest
    static void log_Failure_InsertsRecordWithFullPolicyNumber() {

        // Create a test correlation ID.
        String correlationId = 'TEST-FAILURE-001';

        // Create logger input.
        UlsCalculatorLogger.LogInput input = new UlsCalculatorLogger.LogInput();

        // Set correlation ID.
        input.correlationId = correlationId;

        // Set operation name.
        input.operationName = 'retrievePolicy';

        // Set direction.
        input.direction = UlsCalculatorLogger.DIRECTION_APEX_TO_BACKEND;

        // Set logical endpoint.
        input.endpoint = '/api/v1/policies/{policyNumber}';

        // Set HTTP method.
        input.httpMethod = 'GET';

        // Set HTTP status.
        input.httpStatusCode = 404;

        // Set duration.
        input.durationMs = 250;

        // Mark operation as failed.
        input.success = false;

        // Set safe error code.
        input.errorCode = 'POLICY_NOT_FOUND';

        // Set safe error category.
        input.errorCategory = 'NotFound';

        // Set safe support message.
        input.sanitizedMessage = 'Policy not found. Please check the policy number.';

        // Set full policy number.
        input.policyNumber = 'POL123456789';

        // Success logging is disabled, but failures should still log.
        input.includeSuccessLogs = false;

        // Detailed logging disabled for this test.
        input.enableDetailedLogging = false;

        // Start test context.
        Test.startTest();

        // Write the log.
        Id logId = UlsCalculatorLogger.log(input);

        // Stop test context.
        Test.stopTest();

        // Confirm a log was inserted.
        System.assertNotEquals(
            null,
            logId,
            'Failure log should be inserted.'
        );

        // Query the inserted log.
        Uls_Calculator_Log__c logRecord = [
            SELECT
                Correlation_Id__c,
                Operation_Name__c,
                Direction__c,
                Endpoint__c,
                Http_Method__c,
                Http_Status_Code__c,
                Duration_Ms__c,
                Success__c,
                Error_Code__c,
                Error_Category__c,
                Sanitized_Message__c,
                Policy_Number__c,
                Salesforce_User__c
            FROM Uls_Calculator_Log__c
            WHERE Id = :logId
            LIMIT 1
        ];

        // Verify correlation ID.
        System.assertEquals(
            correlationId,
            logRecord.Correlation_Id__c,
            'Correlation ID should match.'
        );

        // Verify operation name.
        System.assertEquals(
            'retrievePolicy',
            logRecord.Operation_Name__c,
            'Operation name should match.'
        );

        // Verify direction.
        System.assertEquals(
            UlsCalculatorLogger.DIRECTION_APEX_TO_BACKEND,
            logRecord.Direction__c,
            'Direction should match.'
        );

        // Verify endpoint.
        System.assertEquals(
            '/api/v1/policies/{policyNumber}',
            logRecord.Endpoint__c,
            'Endpoint should match.'
        );

        // Verify HTTP method.
        System.assertEquals(
            'GET',
            logRecord.Http_Method__c,
            'HTTP method should match.'
        );

        // Verify HTTP status.
        System.assertEquals(
            404,
            logRecord.Http_Status_Code__c,
            'HTTP status should match.'
        );

        // Verify duration.
        System.assertEquals(
            250,
            logRecord.Duration_Ms__c,
            'Duration should match.'
        );

        // Verify success flag.
        System.assertEquals(
            false,
            logRecord.Success__c,
            'Success should be false.'
        );

        // Verify error code.
        System.assertEquals(
            'POLICY_NOT_FOUND',
            logRecord.Error_Code__c,
            'Error code should match.'
        );

        // Verify error category.
        System.assertEquals(
            'NotFound',
            logRecord.Error_Category__c,
            'Error category should match.'
        );

        // Verify message.
        System.assertEquals(
            'Policy not found. Please check the policy number.',
            logRecord.Sanitized_Message__c,
            'Sanitized message should match.'
        );

        // Verify full policy number is stored.
        System.assertEquals(
            'POL123456789',
            logRecord.Policy_Number__c,
            'Full policy number should be stored for IT Support.'
        );

        // Verify Salesforce user is captured.
        System.assertEquals(
            UserInfo.getUserId(),
            logRecord.Salesforce_User__c,
            'User should match.'
        );
    }

    /**
     * Verifies successful operations are skipped when success logging is disabled.
     */
    @IsTest
    static void log_Success_SkippedWhenSuccessLogsDisabled() {

        // Create logger input.
        UlsCalculatorLogger.LogInput input = new UlsCalculatorLogger.LogInput();

        // Set correlation ID.
        input.correlationId = 'TEST-SUCCESS-SKIP-001';

        // Set operation name.
        input.operationName = 'getFunds';

        // Set direction.
        input.direction = UlsCalculatorLogger.DIRECTION_APEX_TO_BACKEND;

        // Set endpoint.
        input.endpoint = '/api/v1/funds';

        // Set method.
        input.httpMethod = 'GET';

        // Set status.
        input.httpStatusCode = 200;

        // Mark operation as successful.
        input.success = true;

        // Disable success logging.
        input.includeSuccessLogs = false;

        // Start test context.
        Test.startTest();

        // Attempt to write success log.
        Id logId = UlsCalculatorLogger.log(input);

        // Stop test context.
        Test.stopTest();

        // Confirm no log record was inserted.
        System.assertEquals(
            null,
            logId,
            'Success log should be skipped when success logging is disabled.'
        );

        // Count any log records with this correlation ID.
        Integer logCount = [
            SELECT COUNT()
            FROM Uls_Calculator_Log__c
            WHERE Correlation_Id__c = 'TEST-SUCCESS-SKIP-001'
        ];

        // Confirm there are no records.
        System.assertEquals(
            0,
            logCount,
            'No success log should exist.'
        );
    }

    /**
     * Verifies successful operations are logged when success logging is enabled.
     */
    @IsTest
    static void log_Success_InsertsWhenSuccessLogsEnabled() {

        // Create logger input.
        UlsCalculatorLogger.LogInput input = new UlsCalculatorLogger.LogInput();

        // Set correlation ID.
        input.correlationId = 'TEST-SUCCESS-INSERT-001';

        // Set operation name.
        input.operationName = 'getFunds';

        // Set direction.
        input.direction = UlsCalculatorLogger.DIRECTION_APEX_TO_BACKEND;

        // Set endpoint.
        input.endpoint = '/api/v1/funds';

        // Set method.
        input.httpMethod = 'GET';

        // Set status.
        input.httpStatusCode = 200;

        // Set duration.
        input.durationMs = 100;

        // Mark operation as successful.
        input.success = true;

        // Enable success logging.
        input.includeSuccessLogs = true;

        // Start test context.
        Test.startTest();

        // Write the success log.
        Id logId = UlsCalculatorLogger.log(input);

        // Stop test context.
        Test.stopTest();

        // Confirm the success log was inserted.
        System.assertNotEquals(
            null,
            logId,
            'Success log should be inserted when success logging is enabled.'
        );
    }

    /**
     * Verifies that secrets are redacted while business data remains visible.
     */
    @IsTest
    static void log_DetailedLog_RedactsSecretsButDoesNotMaskBusinessData() {

        // Create logger input.
        UlsCalculatorLogger.LogInput input = new UlsCalculatorLogger.LogInput();

        // Set correlation ID.
        input.correlationId = 'TEST-SANITIZE-001';

        // Set operation name.
        input.operationName = 'generateProjection';

        // Set direction.
        input.direction = UlsCalculatorLogger.DIRECTION_APEX_TO_BACKEND;

        // Set endpoint.
        input.endpoint = '/api/v1/calculator/projection';

        // Set method.
        input.httpMethod = 'POST';

        // Set status.
        input.httpStatusCode = 500;

        // Mark operation as failed.
        input.success = false;

        // Set error code.
        input.errorCode = 'CALCULATION_FAILURE';

        // Set category.
        input.errorCategory = 'CalculationFailure';

        // Include a bearer token, email, and policy number.
        // Token should be redacted.
        // Email and policy number should remain visible based on updated requirement.
        input.sanitizedMessage =
            'Authorization: Bearer abc123XYZ user test@example.com failed for policy POL123456789.';

        // Include a bearer token, client secret, email, and policy number.
        // Bearer token and client secret should be redacted.
        // Email and policy number should remain visible.
        input.detailedLog =
            'Backend said Bearer secretToken123 client_secret=abc123 for customer user@example.com policy POL123456789';

        // Store full policy number.
        input.policyNumber = 'POL123456789';

        // Enable detailed logging.
        input.enableDetailedLogging = true;

        // Start test context.
        Test.startTest();

        // Write the log.
        Id logId = UlsCalculatorLogger.log(input);

        // Stop test context.
        Test.stopTest();

        // Query inserted log.
        Uls_Calculator_Log__c logRecord = [
            SELECT
                Sanitized_Message__c,
                Detailed_Log__c,
                Policy_Number__c
            FROM Uls_Calculator_Log__c
            WHERE Id = :logId
            LIMIT 1
        ];

        // Verify bearer token was redacted in message.
        System.assert(
            logRecord.Sanitized_Message__c.contains('Bearer ***'),
            'Bearer token should be redacted in sanitized message.'
        );

        // Verify email remains visible.
        System.assert(
            logRecord.Sanitized_Message__c.contains('test@example.com'),
            'Email should not be masked based on updated support visibility requirement.'
        );

        // Verify policy number remains visible.
        System.assert(
            logRecord.Sanitized_Message__c.contains('POL123456789'),
            'Policy number should not be masked in sanitized message.'
        );

        // Verify bearer token was redacted in detailed log.
        System.assert(
            logRecord.Detailed_Log__c.contains('Bearer ***'),
            'Bearer token should be redacted in detailed log.'
        );

        // Verify client secret was redacted.
        System.assert(
            logRecord.Detailed_Log__c.contains('client_secret=***'),
            'Client secret should be redacted in detailed log.'
        );

        // Verify email remains visible in detailed log.
        System.assert(
            logRecord.Detailed_Log__c.contains('user@example.com'),
            'Email should not be masked in detailed log.'
        );

        // Verify full policy number field.
        System.assertEquals(
            'POL123456789',
            logRecord.Policy_Number__c,
            'Full policy number should be stored.'
        );
    }
}