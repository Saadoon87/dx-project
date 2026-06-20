/**
 * Logger class for the ULS Calculator feature.
 *
 * Purpose:
 * - Create operational support logs in Uls_Calculator_Log__c.
 * - Store enough detail for IT Support to troubleshoot issues.
 * - Generate correlation IDs that can be shown to users and searched by support.
 * - Avoid breaking the main calculator flow if logging fails.
 *
 * Current agreed logging behavior:
 * - IT Support users can view logs through a controlled permission set.
 * - Full policy number is stored in Policy_Number__c.
 * - Business values are not automatically masked.
 * - Secrets are still redacted and should never be stored.
 *
 * Important safety rule:
 * Even for IT Support, we should never store bearer tokens, client secrets,
 * passwords, access tokens, refresh tokens, or signed URLs containing tokens.
 */
public with sharing class UlsCalculatorLogger {

    // Direction value used when browser/LWC calls Apex.
    public static final String DIRECTION_LWC_TO_APEX = 'LWC_TO_APEX';

    // Direction value used when Apex calls the backend.
    public static final String DIRECTION_APEX_TO_BACKEND = 'APEX_TO_BACKEND';

    // Maximum length for Correlation_Id__c.
    private static final Integer MAX_CORRELATION_ID_LENGTH = 80;

    // Maximum length for Operation_Name__c.
    private static final Integer MAX_OPERATION_NAME_LENGTH = 100;

    // Maximum length for Direction__c.
    private static final Integer MAX_DIRECTION_LENGTH = 50;

    // Maximum length for Endpoint__c.
    private static final Integer MAX_ENDPOINT_LENGTH = 255;

    // Maximum length for Http_Method__c.
    private static final Integer MAX_HTTP_METHOD_LENGTH = 10;

    // Maximum length for Error_Code__c.
    private static final Integer MAX_ERROR_CODE_LENGTH = 100;

    // Maximum length for Error_Category__c.
    private static final Integer MAX_ERROR_CATEGORY_LENGTH = 100;

    // Maximum length for Policy_Number__c.
    private static final Integer MAX_POLICY_NUMBER_LENGTH = 80;

    // Conservative max length for Sanitized_Message__c.
    // The field is longer, but this keeps log rows easier to view and query.
    private static final Integer MAX_SANITIZED_MESSAGE_LENGTH = 4000;

    // Conservative max length for Detailed_Log__c.
    // The field is longer, but we do not want huge logs from Apex.
    private static final Integer MAX_DETAILED_LOG_LENGTH = 4000;

    /**
     * Wrapper object used by other Apex classes when writing a log.
     *
     * Why use a wrapper:
     * - Keeps the log method readable.
     * - Avoids passing too many individual parameters.
     * - Allows us to add more fields later without changing every method signature.
     */
    public class LogInput {

        // Correlation ID used to connect user-facing errors to backend/Salesforce logs.
        public String correlationId;

        // Logical operation name, for example retrievePolicy or generateProjection.
        public String operationName;

        // Direction of the operation, for example LWC_TO_APEX or APEX_TO_BACKEND.
        public String direction;

        // Logical endpoint or operation target.
        // This should be a safe path/name, not a full signed URL with tokens.
        public String endpoint;

        // HTTP method if the log is for a backend callout.
        public String httpMethod;

        // HTTP status code if the backend returned one.
        public Integer httpStatusCode;

        // Operation duration in milliseconds.
        public Decimal durationMs;

        // True when the operation succeeded.
        // False when the operation failed.
        public Boolean success;

        // Safe error code, for example POLICY_NOT_FOUND or TIMEOUT.
        public String errorCode;

        // Safe error category, for example Validation, NotFound, Timeout, Unexpected.
        public String errorCategory;

        // Support-safe message.
        // This should not contain tokens, secrets, or raw stack traces.
        public String sanitizedMessage;

        // Full policy number.
        // This is stored because IT Support needs full visibility for troubleshooting.
        public String policyNumber;

        // Timestamp when the operation started.
        public Datetime requestTimestamp;

        // Timestamp when the operation ended.
        public Datetime responseTimestamp;

        // Optional detailed support log.
        // Only stored when detailed logging is enabled by config.
        public String detailedLog;

        // Controls whether success logs should be persisted.
        // This will come from UlsCalculatorConfig__mdt later.
        public Boolean includeSuccessLogs;

        // Controls whether detailedLog should be stored.
        // This will come from UlsCalculatorConfig__mdt later.
        public Boolean enableDetailedLogging;
    }

    /**
     * Generates a support correlation ID.
     *
     * Example:
     * ULS-20260620143015000-12345678
     *
     * The timestamp is GMT so IDs are consistent regardless of user timezone.
     */
    public static String generateCorrelationId() {

        // Get current timestamp in GMT using a compact sortable format.
        String timestampText = Datetime.now().formatGmt('yyyyMMddHHmmssSSS');

        // Generate a random integer to reduce collision risk.
        Integer randomInteger = Crypto.getRandomInteger();

        // Convert the random integer into text.
        String randomText = String.valueOf(randomInteger);

        // Remove the minus sign if Salesforce generated a negative integer.
        randomText = randomText.replace('-', '');

        // Keep only 8 digits to make the correlation ID readable.
        if (randomText.length() > 8) {
            randomText = randomText.substring(0, 8);
        }

        // Build and return the final correlation ID.
        return 'ULS-' + timestampText + '-' + randomText;
    }

    /**
     * Legacy helper method.
     *
     * Active logging no longer uses this method because IT Support requested
     * full policy number visibility.
     *
     * We keep it for backward compatibility and because existing tests may still
     * verify the masking utility behavior.
     */
    public static String maskPolicyNumber(String policyNumber) {

        // Return null when no policy number was provided.
        if (String.isBlank(policyNumber)) {
            return null;
        }

        // Remove leading/trailing spaces.
        String trimmedPolicyNumber = policyNumber.trim();

        // If the value is too short, hide the entire value.
        if (trimmedPolicyNumber.length() <= 4) {
            return '****';
        }

        // Calculate where the last four characters begin.
        Integer startIndex = trimmedPolicyNumber.length() - 4;

        // Extract the last four characters.
        String lastFourCharacters = trimmedPolicyNumber.substring(startIndex, trimmedPolicyNumber.length());

        // Return the masked value.
        return '****' + lastFourCharacters;
    }

    /**
     * Creates a ULS Calculator log record.
     *
     * Returns:
     * - The inserted log Id when a record is created.
     * - Null when the log is skipped or logging fails safely.
     *
     * Important:
     * Logging must never break the actual calculator operation.
     */
    public static Id log(LogInput input) {

        // If no input was provided, there is nothing to log.
        if (input == null) {
            return null;
        }

        // Treat only explicit true as success.
        Boolean operationSucceeded = input.success == true;

        // Treat only explicit true as "log success records".
        Boolean shouldIncludeSuccessLogs = input.includeSuccessLogs == true;

        // Skip successful logs unless enabled by config.
        if (operationSucceeded && !shouldIncludeSuccessLogs) {
            return null;
        }

        // Wrap logging in try/catch so logging failures do not break the user flow.
        try {

            // Create a new log object record.
            Uls_Calculator_Log__c logRecord = new Uls_Calculator_Log__c();

            // Store the correlation ID safely within field length.
            logRecord.Correlation_Id__c = safeTruncate(
                input.correlationId,
                MAX_CORRELATION_ID_LENGTH
            );

            // Store the logical operation name.
            logRecord.Operation_Name__c = safeTruncate(
                input.operationName,
                MAX_OPERATION_NAME_LENGTH
            );

            // Store the operation direction.
            logRecord.Direction__c = safeTruncate(
                input.direction,
                MAX_DIRECTION_LENGTH
            );

            // Store the safe logical endpoint/path.
            logRecord.Endpoint__c = safeTruncate(
                input.endpoint,
                MAX_ENDPOINT_LENGTH
            );

            // Store HTTP method when applicable.
            logRecord.Http_Method__c = safeTruncate(
                input.httpMethod,
                MAX_HTTP_METHOD_LENGTH
            );

            // Store HTTP status code when applicable.
            logRecord.Http_Status_Code__c = input.httpStatusCode;

            // Store duration when provided.
            logRecord.Duration_Ms__c = input.durationMs;

            // Store whether the operation succeeded.
            logRecord.Success__c = operationSucceeded;

            // Store safe error code.
            logRecord.Error_Code__c = safeTruncate(
                input.errorCode,
                MAX_ERROR_CODE_LENGTH
            );

            // Store safe error category.
            logRecord.Error_Category__c = safeTruncate(
                input.errorCategory,
                MAX_ERROR_CATEGORY_LENGTH
            );

            // Store sanitized message.
            // Business values are not masked, but secrets are redacted.
            logRecord.Sanitized_Message__c = safeTruncate(
                sanitizeText(input.sanitizedMessage),
                MAX_SANITIZED_MESSAGE_LENGTH
            );

            // Store the full policy number for IT Support.
            logRecord.Policy_Number__c = safeTruncate(
                input.policyNumber,
                MAX_POLICY_NUMBER_LENGTH
            );

            // Store the Salesforce user who triggered the operation.
            logRecord.Salesforce_User__c = UserInfo.getUserId();

            // Store request timestamp, or current time if not provided.
            logRecord.Request_Timestamp__c =
                input.requestTimestamp == null ? Datetime.now() : input.requestTimestamp;

            // Store response timestamp, or current time if not provided.
            logRecord.Response_Timestamp__c =
                input.responseTimestamp == null ? Datetime.now() : input.responseTimestamp;

            // Store placeholder environment value.
            // We can improve this later if AXA wants explicit DEV/UAT/PROD detection.
            logRecord.Environment__c = 'UNKNOWN';

            // Store detailed log only when enabled.
            if (input.enableDetailedLogging == true) {

                // Detailed logs also go through secret redaction.
                logRecord.Detailed_Log__c = safeTruncate(
                    sanitizeText(input.detailedLog),
                    MAX_DETAILED_LOG_LENGTH
                );
            }

            // Insert the log record.
            insert logRecord;

            // Return the log record Id.
            return logRecord.Id;

        } catch (Exception loggingException) {

            // Never throw logging errors back to the calculator/user.
            // Keep debug output minimal and do not print raw data.
            System.debug(
                LoggingLevel.ERROR,
                'ULS Calculator logging failed safely: ' + loggingException.getTypeName()
            );

            // Return null because no log record was created.
            return null;
        }
    }

    /**
     * Redacts secrets before text is stored in the log object.
     *
     * This method does not mask business data such as policy number or email.
     * It only redacts secrets that should never be persisted.
     */
    private static String sanitizeText(String textValue) {

        // Return null if text is blank.
        if (String.isBlank(textValue)) {
            return null;
        }

        // Start with the original text.
        String sanitizedValue = textValue;

        // Replace new lines with spaces so the log is easier to read in list views.
        sanitizedValue = sanitizedValue.replace('\n', ' ');

        // Replace carriage returns with spaces too.
        sanitizedValue = sanitizedValue.replace('\r', ' ');

        // Redact accidental bearer tokens.
        sanitizedValue = sanitizedValue.replaceAll(
            '(?i)Bearer\\s+[A-Za-z0-9._\\-]+',
            'Bearer ***'
        );

        // Redact common secret key/value patterns.
        sanitizedValue = sanitizedValue.replaceAll(
            '(?i)(client_secret|password|access_token|refresh_token)\\s*[:=]\\s*[^\\s,;]+',
            '$1=***'
        );

        // Return the sanitized text.
        return sanitizedValue;
    }

    /**
     * Safely truncates text so it fits into Salesforce field limits.
     */
    private static String safeTruncate(String textValue, Integer maxLength) {

        // Return null if the text is blank.
        if (String.isBlank(textValue)) {
            return null;
        }

        // If no max length was provided, return the original text.
        if (maxLength == null || maxLength <= 0) {
            return textValue;
        }

        // If the text already fits, return it unchanged.
        if (textValue.length() <= maxLength) {
            return textValue;
        }

        // Otherwise cut the text to the allowed length.
        return textValue.substring(0, maxLength);
    }
}