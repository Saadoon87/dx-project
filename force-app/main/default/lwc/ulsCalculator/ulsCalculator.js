// Import the base Lightning Web Component class.
import { LightningElement } from 'lwc';

// Import the Apex controller method used to retrieve policy data.
import retrievePolicy from '@salesforce/apex/UlsCalculatorController.retrievePolicy';

// Main ULS Calculator component.
export default class UlsCalculator extends LightningElement {

    // Tracks the active step in the guided workflow.
    currentStep = 1;

    // Stores the policy number entered by the user.
    policyNumber = '';

    // Stores policy data returned by Apex/backend after successful retrieval.
    policyData = null;

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

    // Handles typing in the Policy Number input.
    handlePolicyNumberChange(event) {
        // Store the latest user-entered value.
        this.policyNumber = event.target.value;

        // Clear old errors when the user starts editing again.
        this.clearError();

        // If the user changes the policy number, old policy data should not remain trusted.
        this.policyData = null;
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
        this.isLoading = true;
        this.loadingMessage = 'Retrieving policy data...';

        try {
            // Call Apex controller. Apex will call the service/backend layer.
            const response = await retrievePolicy({
                policyNumber: cleanedPolicyNumber
            });

            // Handle a missing or unexpected Apex response safely.
            if (!response) {
                this.errorState = {
                    userMessage: 'No response was received. Please try again or contact support.',
                    errorCode: 'EMPTY_RESPONSE',
                    correlationId: null
                };
                return;
            }

            // If Apex returned success, store the policy data and move to Step 2.
            if (response.success === true) {
                this.policyData = response.data;
                this.currentStep = 2;
                this.clearError();
                return;
            }

            // If Apex returned a safe business/backend error, show it to the user.
            this.errorState = {
                userMessage: response.userMessage || 'Unable to retrieve policy data. Please try again or contact support.',
                errorCode: response.errorCode || 'UNKNOWN_ERROR',
                correlationId: response.correlationId || null
            };

        } catch (error) {
            // Catch unexpected browser/Apex transport errors safely.
            this.errorState = {
                userMessage: this.reduceError(error),
                errorCode: 'LWC_APEX_CALL_FAILED',
                correlationId: null
            };

        } finally {
            // Always stop loading after the action completes.
            this.isLoading = false;
            this.loadingMessage = '';
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