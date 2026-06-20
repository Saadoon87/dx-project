// Import the base Lightning Web Component class.
import { LightningElement } from 'lwc';

// Import the Apex controller method used to retrieve policy data.
import retrievePolicy from '@salesforce/apex/UlsCalculatorController.retrievePolicy';

// Import the Apex controller method used to fetch the current inflation rate.
import getInflationRate from '@salesforce/apex/UlsCalculatorController.getInflationRate';

// Import the Apex controller method used to calculate inflation-adjusted UAV.
import calculateInflationAdjustedUav from '@salesforce/apex/UlsCalculatorController.calculateInflationAdjustedUav';

// Import the Apex controller method used to calculate suggested premium.
import calculateSuggestedPremium from '@salesforce/apex/UlsCalculatorController.calculateSuggestedPremium';

// Import the Apex controller method used to calculate projected final UAV.
import calculateFinalUav from '@salesforce/apex/UlsCalculatorController.calculateFinalUav';

// Main ULS Calculator component.
export default class UlsCalculator extends LightningElement {

    // Tracks the active step in the guided workflow.
    currentStep = 1;

    // Stores the policy number entered by the user.
    policyNumber = '';

    // Stores policy data returned by Apex/backend after successful retrieval.
    policyData = null;

    // Tracks whether the user is viewing temporary fake preview data.
    // This must remain false for real backend-driven flows.
    isPreviewMode = false;

    // Stores the current inflation rate returned by the backend.
    inflationRateData = null;

    // Stores all Step 2 input values and calculation responses.
    goalData = {
        initialTargetUav: null,
        requestedFinalUav: null,
        requestedMonthlyPremium: null,
        inflationAdjustedUavResult: null,
        suggestedPremiumResult: null,
        finalUavResult: null,
        isInflationAdjustedUavStale: false,
        isSuggestedPremiumStale: false,
        isFinalUavStale: false
    };

    // Tracks whether the component is currently waiting for an Apex/backend response.
    isLoading = false;

    // Stores the loading message shown to the user.
    loadingMessage = '';

    // Stores the current safe error state shown in the UI.
    errorState = null;

    // Defines the guided workflow steps.
    baseSteps = [
        { number: 1, label: 'Policy Retrieval' },
        { number: 2, label: 'Define Goal' },
        { number: 3, label: 'Apply Alterations' },
        { number: 4, label: 'Consolidated Review' },
        { number: 5, label: 'Generated Package' }
    ];

    // Builds the stepper data used by the HTML template.
    get steps() {
        return this.baseSteps.map((step) => {
            return {
                ...step,
                cssClass: this.getStepCssClass(step.number)
            };
        });
    }

    // Returns true when Step 1 should be displayed.
    get isStep1() {
        return this.currentStep === 1;
    }

    // Returns true when Step 2 should be displayed.
    get isStep2() {
        return this.currentStep === 2;
    }

    // Returns true when Step 3 should be displayed.
    get isStep3() {
        return this.currentStep === 3;
    }

    // Returns true when Step 4 should be displayed.
    get isStep4() {
        return this.currentStep === 4;
    }

    // Returns true when Step 5 should be displayed.
    get isStep5() {
        return this.currentStep === 5;
    }

    // Returns true when an error should be shown.
    get hasError() {
        return this.errorState !== null;
    }

    // Returns true when policy data has been successfully retrieved.
    get hasPolicyData() {
        return this.policyData !== null;
    }

    // Disables Retrieve while loading or when policy number is blank.
    get isRetrieveDisabled() {
        return this.isLoading || !this.policyNumber || this.policyNumber.trim().length === 0;
    }

    // Disables inflation-adjusted calculation until the required input is entered.
    get isCalculateInflationAdjustedDisabled() {
        return this.isLoading || !this.isPositiveNumber(this.goalData.initialTargetUav);
    }

    // Disables suggested premium calculation until the required input is entered.
    get isCalculateSuggestedPremiumDisabled() {
        return this.isLoading || !this.isPositiveNumber(this.goalData.requestedFinalUav);
    }

    // Disables final UAV recalculation until the required input is entered.
    get isCalculateFinalUavDisabled() {
        return this.isLoading || !this.isPositiveNumber(this.goalData.requestedMonthlyPremium);
    }

    // Disables Next while loading or when Step 2 has stale calculated results.
    get isNextDisabled() {
        return this.isLoading || this.hasStaleGoalResults;
    }

    // Returns true when one or more Step 2 calculated results are stale.
    get hasStaleGoalResults() {
        return this.goalData.isInflationAdjustedUavStale
            || this.goalData.isSuggestedPremiumStale
            || this.goalData.isFinalUavStale;
    }

    // Safely displays policy number from backend data or the entered value.
    get displayPolicyNumber() {
        return this.getSafeValue(this.policyData?.policyNumber, this.policyNumber);
    }

    // Safely displays customer name if returned by backend.
    get displayCustomerName() {
        return this.getSafeValue(this.policyData?.customerName, 'Not available');
    }

    // Safely displays maturity date if returned by backend.
    get displayMaturityDate() {
        return this.getSafeValue(this.policyData?.maturityDate, 'Not available');
    }

    // Safely displays current premium if returned by backend.
    get displayCurrentPremium() {
        return this.getSafeValue(this.policyData?.currentPremium, 'Not available');
    }

    // Safely displays current UAV if returned by backend.
    get displayCurrentUav() {
        return this.getSafeValue(this.policyData?.currentUav, 'Not available');
    }

    // Safely displays missed premiums if returned by backend.
    get displayMissedPremiums() {
        return this.getSafeValue(this.policyData?.missedPremiums, 'Not available');
    }

    // Safely displays the inflation rate returned from getInflationRate.
    get displayInflationRate() {
        return this.getSafeValue(this.inflationRateData?.inflationRate, 'Not loaded');
    }

    // Displays initial UAV from the inflation-adjusted calculation response.
    get displayInitialUavResult() {
        return this.getSafeValue(this.goalData.inflationAdjustedUavResult?.initialUAV, 'Not calculated');
    }

    // Displays inflation rate from the inflation-adjusted calculation response.
    get displayInflationAdjustedRate() {
        return this.getSafeValue(this.goalData.inflationAdjustedUavResult?.inflationRate, 'Not calculated');
    }

    // Displays remaining years from the inflation-adjusted calculation response.
    get displayRemainingYears() {
        return this.getSafeValue(this.goalData.inflationAdjustedUavResult?.remainingYears, 'Not calculated');
    }

    // Displays inflation-adjusted amount from the backend response.
    get displayInflationAdjustedAmount() {
        return this.getSafeValue(this.goalData.inflationAdjustedUavResult?.inflationAdjustedAmount, 'Not calculated');
    }

    // Displays target final UAV from the suggested premium response.
    get displaySuggestedTargetFinalUav() {
        return this.getSafeValue(this.goalData.suggestedPremiumResult?.targetFinalUAV, 'Not calculated');
    }

    // Displays suggested premium from the backend response.
    get displaySuggestedPremium() {
        return this.getSafeValue(this.goalData.suggestedPremiumResult?.suggestedPremium, 'Not calculated');
    }

    // Displays current premium from the suggested premium response.
    get displaySuggestedCurrentPremium() {
        return this.getSafeValue(this.goalData.suggestedPremiumResult?.currentPremium, 'Not calculated');
    }

    // Displays difference from the suggested premium response.
    get displaySuggestedDifference() {
        return this.getSafeValue(this.goalData.suggestedPremiumResult?.difference, 'Not calculated');
    }

    // Displays requested premium from the final UAV response.
    get displayRequestedPremiumResult() {
        return this.getSafeValue(this.goalData.finalUavResult?.requestedPremium, 'Not calculated');
    }

    // Displays current premium from the final UAV response.
    get displayFinalUavCurrentPremium() {
        return this.getSafeValue(this.goalData.finalUavResult?.currentPremium, 'Not calculated');
    }

    // Displays difference from the final UAV response.
    get displayFinalUavDifference() {
        return this.getSafeValue(this.goalData.finalUavResult?.difference, 'Not calculated');
    }

    // Displays projected final UAV from the backend response.
    get displayProjectedFinalUav() {
        return this.getSafeValue(this.goalData.finalUavResult?.projectedFinalUAV, 'Not calculated');
    }

    // Handles typing in the Policy Number input.
    handlePolicyNumberChange(event) {
        // Store the latest user-entered value.
        this.policyNumber = event.target.value;

        // Clear old errors when the user starts editing again.
        this.clearError();

        // If the user changes the policy number, old policy data should not remain trusted.
        this.policyData = null;

        // If the user starts typing a real policy number, leave preview mode.
        this.isPreviewMode = false;

        // Reset Step 2 data because it belongs to the previously retrieved policy.
        this.resetGoalData();
    }

    // Handles the Retrieve Policy button click.
    async handleRetrievePolicy() {
        // Clear any previous error before starting a new action.
        this.clearError();

        // Clean up extra spaces from the entered policy number.
        const cleanedPolicyNumber = this.policyNumber ? this.policyNumber.trim() : '';

        // Validate that policy number is not blank before calling Apex.
        if (!cleanedPolicyNumber) {
            this.errorState = {
                userMessage: 'Please enter a policy number before retrieving policy data.',
                errorCode: 'VALIDATION_ERROR',
                correlationId: null
            };
            return;
        }

        // Prevent duplicate submits while an existing request is running.
        if (this.isLoading) {
            return;
        }

        // Store the cleaned value back into component state.
        this.policyNumber = cleanedPolicyNumber;

        // Start loading state.
        this.startLoading('Retrieving policy data...');

        try {
            // Call Apex controller. Apex will call the service/backend layer.
            const response = await retrievePolicy({
                policyNumber: cleanedPolicyNumber
            });

            // If Apex returned success, store the policy data and move to Step 2.
            if (this.handleApiSuccess(response)) {
                // Real backend success means this is no longer preview mode.
                this.isPreviewMode = false;

                // Store real policy data returned by Apex/backend.
                this.policyData = response.data;

                // Move the user to Step 2.
                this.currentStep = 2;

                // Reset Step 2 goal/calculation state for the retrieved policy.
                this.resetGoalData();

                return;
            }

            // If Apex returned a safe business/backend error, show it to the user.
            this.setApiError(response, 'Unable to retrieve policy data. Please try again or contact support.');

        } catch (error) {
            // Catch unexpected browser/Apex transport errors safely.
            this.setUnexpectedError(error);

        } finally {
            // Always stop loading after the action completes.
            this.stopLoading();
        }
    }

    // TEMPORARY SANDBOX-ONLY METHOD.
    // This method lets us preview Step 2 while backend authentication is not ready.
    // It must be removed or disabled before production release.
    handlePreviewStep2() {
        // Clear any previous backend or validation error.
        this.clearError();

        // Do not allow preview action while another action is loading.
        if (this.isLoading) {
            return;
        }

        // Mark the component as being in temporary preview mode.
        this.isPreviewMode = true;

        // Use an obviously fake policy number so nobody confuses this with real data.
        this.policyNumber = 'POL-PREVIEW-001';

        // Load clearly fake sample policy data for UI preview only.
        // These values are not business rules and must not be used for real customer work.
        this.policyData = {
            policyNumber: 'POL-PREVIEW-001',
            customerName: 'Sample Customer - Preview Only',
            maturityDate: '2036-12-31',
            currentPremium: 1000,
            currentUav: 250000,
            missedPremiums: 0
        };

        // Reset Step 2 calculation fields so preview starts clean.
        this.resetGoalData();

        // Move directly to Step 2 so we can visually test the layout.
        this.currentStep = 2;
    }

    // Handles typing in the Initial Target UAV field.
    handleInitialTargetUavChange(event) {
        // Ask lightning-input to show inline validation if the value is invalid.
        event.target.reportValidity();

        // Store the entered value.
        this.goalData = {
            ...this.goalData,
            initialTargetUav: event.target.value,
            isInflationAdjustedUavStale: this.goalData.inflationAdjustedUavResult !== null
        };

        // Clear old page-level errors when the user updates input.
        this.clearError();
    }

    // Handles typing in the Requested Final UAV field.
    handleRequestedFinalUavChange(event) {
        // Ask lightning-input to show inline validation if the value is invalid.
        event.target.reportValidity();

        // Store the entered value.
        this.goalData = {
            ...this.goalData,
            requestedFinalUav: event.target.value,
            isSuggestedPremiumStale: this.goalData.suggestedPremiumResult !== null
        };

        // Clear old page-level errors when the user updates input.
        this.clearError();
    }

    // Handles typing in the Requested Monthly Premium field.
    handleRequestedMonthlyPremiumChange(event) {
        // Ask lightning-input to show inline validation if the value is invalid.
        event.target.reportValidity();

        // Store the entered value.
        this.goalData = {
            ...this.goalData,
            requestedMonthlyPremium: event.target.value,
            isFinalUavStale: this.goalData.finalUavResult !== null
        };

        // Clear old page-level errors when the user updates input.
        this.clearError();
    }

    // Loads the current inflation rate from the backend through Apex.
    async handleLoadInflationRate() {
        // Prevent duplicate actions while loading.
        if (this.isLoading) {
            return;
        }

        // Clear existing errors before starting.
        this.clearError();

        // Start loading state.
        this.startLoading('Loading inflation rate...');

        try {
            // Call Apex method.
            const response = await getInflationRate();

            // If successful, store the inflation rate response.
            if (this.handleApiSuccess(response)) {
                this.inflationRateData = response.data;
                return;
            }

            // If failed, show safe error details.
            this.setApiError(response, 'Unable to load inflation rate. Please try again or contact support.');

        } catch (error) {
            // Catch unexpected browser/Apex transport errors safely.
            this.setUnexpectedError(error);

        } finally {
            // Always stop loading.
            this.stopLoading();
        }
    }

    // Calculates inflation-adjusted UAV using Apex/backend.
    async handleCalculateInflationAdjustedUav() {
        // Clear existing errors before starting.
        this.clearError();

        // Validate the required field before calling Apex.
        if (!this.isPositiveNumber(this.goalData.initialTargetUav)) {
            this.errorState = {
                userMessage: 'Please enter a positive Initial Target UAV before calculating.',
                errorCode: 'VALIDATION_ERROR',
                correlationId: null
            };
            return;
        }

        // Prevent duplicate actions while loading.
        if (this.isLoading) {
            return;
        }

        // Start loading state.
        this.startLoading('Calculating inflation-adjusted UAV...');

        try {
            // Build request using DTO field names expected by Apex.
            const request = {
                policyNumber: this.policyNumber,
                initialUAV: Number(this.goalData.initialTargetUav)
            };

            // Call Apex method.
            const response = await calculateInflationAdjustedUav({
                request: request
            });

            // If successful, store the calculation result.
            if (this.handleApiSuccess(response)) {
                this.goalData = {
                    ...this.goalData,
                    inflationAdjustedUavResult: response.data,
                    isInflationAdjustedUavStale: false
                };
                return;
            }

            // If failed, show safe error details.
            this.setApiError(response, 'Unable to calculate inflation-adjusted UAV. Please try again or contact support.');

        } catch (error) {
            // Catch unexpected browser/Apex transport errors safely.
            this.setUnexpectedError(error);

        } finally {
            // Always stop loading.
            this.stopLoading();
        }
    }

    // Calculates suggested premium using Apex/backend.
    async handleCalculateSuggestedPremium() {
        // Clear existing errors before starting.
        this.clearError();

        // Validate the required field before calling Apex.
        if (!this.isPositiveNumber(this.goalData.requestedFinalUav)) {
            this.errorState = {
                userMessage: 'Please enter a positive Requested Final UAV before calculating.',
                errorCode: 'VALIDATION_ERROR',
                correlationId: null
            };
            return;
        }

        // Prevent duplicate actions while loading.
        if (this.isLoading) {
            return;
        }

        // Start loading state.
        this.startLoading('Calculating suggested premium...');

        try {
            // Build request using DTO field names expected by Apex.
            const request = {
                policyNumber: this.policyNumber,
                targetFinalUAV: Number(this.goalData.requestedFinalUav)
            };

            // Call Apex method.
            const response = await calculateSuggestedPremium({
                request: request
            });

            // If successful, store the calculation result.
            if (this.handleApiSuccess(response)) {
                this.goalData = {
                    ...this.goalData,
                    suggestedPremiumResult: response.data,
                    isSuggestedPremiumStale: false
                };

                // Helpful UX: copy suggested premium into Requested Monthly Premium only if user has not typed one.
                if (!this.goalData.requestedMonthlyPremium && response.data?.suggestedPremium !== undefined) {
                    this.goalData = {
                        ...this.goalData,
                        requestedMonthlyPremium: response.data.suggestedPremium
                    };
                }

                return;
            }

            // If failed, show safe error details.
            this.setApiError(response, 'Unable to calculate suggested premium. Please try again or contact support.');

        } catch (error) {
            // Catch unexpected browser/Apex transport errors safely.
            this.setUnexpectedError(error);

        } finally {
            // Always stop loading.
            this.stopLoading();
        }
    }

    // Calculates final UAV using Apex/backend.
    async handleCalculateFinalUav() {
        // Clear existing errors before starting.
        this.clearError();

        // Validate the required field before calling Apex.
        if (!this.isPositiveNumber(this.goalData.requestedMonthlyPremium)) {
            this.errorState = {
                userMessage: 'Please enter a positive Requested Monthly Premium before recalculating final UAV.',
                errorCode: 'VALIDATION_ERROR',
                correlationId: null
            };
            return;
        }

        // Prevent duplicate actions while loading.
        if (this.isLoading) {
            return;
        }

        // Start loading state.
        this.startLoading('Recalculating final UAV...');

        try {
            // Build request using DTO field names expected by Apex.
            const request = {
                policyNumber: this.policyNumber,
                requestedPremium: Number(this.goalData.requestedMonthlyPremium)
            };

            // Call Apex method.
            const response = await calculateFinalUav({
                request: request
            });

            // If successful, store the calculation result.
            if (this.handleApiSuccess(response)) {
                this.goalData = {
                    ...this.goalData,
                    finalUavResult: response.data,
                    isFinalUavStale: false
                };
                return;
            }

            // If failed, show safe error details.
            this.setApiError(response, 'Unable to recalculate final UAV. Please try again or contact support.');

        } catch (error) {
            // Catch unexpected browser/Apex transport errors safely.
            this.setUnexpectedError(error);

        } finally {
            // Always stop loading.
            this.stopLoading();
        }
    }

    // Moves to the previous step.
    handleBack() {
        if (this.currentStep > 1) {
            this.currentStep -= 1;
        }
    }

    // Moves to the next step.
    handleNext() {
        if (this.currentStep < 5) {
            this.currentStep += 1;
        }
    }

    // Clears the current error from the screen.
    clearError() {
        this.errorState = null;
    }

    // Starts loading state with a user-friendly message.
    startLoading(message) {
        this.isLoading = true;
        this.loadingMessage = message;
    }

    // Stops loading state and clears the loading message.
    stopLoading() {
        this.isLoading = false;
        this.loadingMessage = '';
    }

    // Resets Step 2 data when a new policy is entered/retrieved.
    resetGoalData() {
        this.inflationRateData = null;

        this.goalData = {
            initialTargetUav: null,
            requestedFinalUav: null,
            requestedMonthlyPremium: null,
            inflationAdjustedUavResult: null,
            suggestedPremiumResult: null,
            finalUavResult: null,
            isInflationAdjustedUavStale: false,
            isSuggestedPremiumStale: false,
            isFinalUavStale: false
        };
    }

    // Returns true if a value is a valid positive number.
    isPositiveNumber(value) {
        const numericValue = Number(value);
        return !Number.isNaN(numericValue) && numericValue > 0;
    }

    // Returns true if the Apex response is a successful ApiResponse.
    handleApiSuccess(response) {
        return response && response.success === true;
    }

    // Converts a failed ApiResponse into the shared error UI state.
    setApiError(response, fallbackMessage) {
        if (!response) {
            this.errorState = {
                userMessage: 'No response was received. Please try again or contact support.',
                errorCode: 'EMPTY_RESPONSE',
                correlationId: null
            };
            return;
        }

        this.errorState = {
            userMessage: response.userMessage || fallbackMessage,
            errorCode: response.errorCode || 'UNKNOWN_ERROR',
            correlationId: response.correlationId || null
        };
    }

    // Converts unexpected JavaScript/Apex transport errors into the shared error UI state.
    setUnexpectedError(error) {
        this.errorState = {
            userMessage: this.reduceError(error),
            errorCode: 'LWC_APEX_CALL_FAILED',
            correlationId: null
        };
    }

    // Returns the CSS class for each step in the visual stepper.
    getStepCssClass(stepNumber) {
        if (stepNumber === this.currentStep) {
            return 'uls-step uls-step-active';
        }

        if (stepNumber < this.currentStep) {
            return 'uls-step uls-step-complete';
        }

        return 'uls-step';
    }

    // Safely returns a display value without showing undefined/null in the UI.
    getSafeValue(value, fallbackValue) {
        if (value === null || value === undefined || value === '') {
            return fallbackValue;
        }

        return value;
    }

    // Converts unexpected JavaScript/Apex errors into a safe readable message.
    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ');
        }

        if (typeof error?.body?.message === 'string') {
            return error.body.message;
        }

        if (typeof error?.message === 'string') {
            return error.message;
        }

        return 'Unexpected error occurred. Please try again or contact support.';
    }
}