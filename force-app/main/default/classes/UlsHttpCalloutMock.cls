/**
 * UlsHttpCalloutMock
 *
 * Purpose:
 * - Shared HTTP callout mock for ULS Calculator Apex tests.
 * - Apex tests cannot call the real backend.
 * - This class lets tests simulate backend HTTP responses.
 *
 * Why @IsTest:
 * - This class is only used by test classes.
 * - It does not count against production Apex code limits.
 */
@IsTest
public class UlsHttpCalloutMock implements HttpCalloutMock {

    /**
     * HTTP status code that the mock backend should return.
     * Example: 200, 400, 404, 500, 503.
     */
    private Integer statusCode;

    /**
     * Response body that the mock backend should return.
     * Usually JSON.
     */
    private String responseBody;

    /**
     * Optional response headers.
     * Example: Content-Type = application/json.
     */
    private Map<String, String> responseHeaders;

    /**
     * Captured requests.
     *
     * This is useful when a test wants to verify:
     * - Which endpoint was called
     * - Which HTTP method was used
     * - Which headers were sent
     */
    public static List<HttpRequest> capturedRequests = new List<HttpRequest>();

    /**
     * Constructor with status code and response body.
     */
    public UlsHttpCalloutMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
        this.responseHeaders = new Map<String, String>();
        this.responseHeaders.put('Content-Type', 'application/json');
    }

    /**
     * Adds or overrides a response header.
     *
     * Returns the same mock instance so tests can chain setup if needed.
     */
    public UlsHttpCalloutMock withHeader(String headerName, String headerValue) {
        this.responseHeaders.put(headerName, headerValue);
        return this;
    }

    /**
     * Salesforce calls this method when Apex code sends an HTTP callout during a test.
     */
    public HttpResponse respond(HttpRequest request) {
        capturedRequests.add(request);

        HttpResponse response = new HttpResponse();

        response.setStatusCode(statusCode);
        response.setBody(responseBody);

        for (String headerName : responseHeaders.keySet()) {
            response.setHeader(headerName, responseHeaders.get(headerName));
        }

        return response;
    }

    /**
     * Returns the most recent captured request.
     */
    public static HttpRequest getLastRequest() {
        if (capturedRequests.isEmpty()) {
            return null;
        }

        return capturedRequests[capturedRequests.size() - 1];
    }

    /**
     * Clears captured requests.
     *
     * Call this at the beginning of each test that verifies request details.
     */
    public static void reset() {
        capturedRequests.clear();
    }
}