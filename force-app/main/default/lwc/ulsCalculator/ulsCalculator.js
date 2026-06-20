import { LightningElement } from 'lwc';

/**
 * ulsCalculator
 *
 * Purpose:
 * - Browser-side UI shell for the ULS Calculator.
 * - Manages current step, loading state, and safe error state.
 *
 * Important:
 * - No Apex calls are added in this skeleton step.
 * - Real policy retrieval starts in the next major step.
 */
export default class UlsCalculator extends LightningElement {
    /**
     * Current step number.
     *
     * Step flow:
     * 1 = Policy Retrieval
     * 2 = Define Goal
     * 3 = Apply Alterations
     * 4 = Consolidated Review
     * 5 = Generated Package
     */
    currentStep = 1;

    /**
     * Loading state.
     *
     * Later, this becomes true while Apex calls are running.
     */
    isLoading = false;

    /**
     * Loading message shown near the spinner.
     */
    loadingMessage = 'Loading...';

    /**
     * Safe error state for the UI.
     *
     * This mirrors the Apex ApiResponse error pattern:
     * - errorCode
     * - userMessage
     * - correlationId
     */
    errorState = {
        errorCode: null,
        userMessage: null,
        correlationId: null
    };

    /**
     * Step definitions.
     *
     * The computed steps getter below adds CSS classes and aria-current.
     */
    baseSteps = [
        {
            value: 1,
            label: 'Policy Retrieval'
        },
        {
            value: 2,
            label: 'Define Goal'
        },
        {
            value: 3,
            label: 'Apply Alterations'
        },
        {
            value: 4,
            label: 'Consolidated Review'
        },
        {
            value: 5,
            label: 'Generated Package'
        }
    ];

    /**
     * Builds stepper data for the template.
     *
     * This keeps HTML simple and avoids complex expressions in the template.
     */
    get steps() {
        return this.baseSteps.map((step) => {
            const isActive = step.value === this.currentStep;
            const isCompleted = step.value < this.currentStep;

            return {
                ...step,
                cssClass: this.getStepCssClass(isActive, isCompleted),
                ariaCurrent: isActive ? 'step' : null
            };
        });
    }

    /**
     * Returns the current step label for the header badge.
     */
    get currentStepLabel() {
        const selectedStep = this.baseSteps.find((step) => step.value === this.currentStep);

        return selectedStep ? selectedStep.label : 'ULS Calculator';
    }

    /**
     * True when there is a user-safe error to display.
     */
    get hasError() {
        return Boolean(this.errorState && this.errorState.userMessage);
    }

    /**
     * Step-specific getters.
     *
     * LWC templates do not allow complex expressions like currentStep === 1.
     * So we expose simple getters.
     */
    get isStep1() {
        return this.currentStep === 1;
    }

    get isStep2() {
        return this.currentStep === 2;
    }

    get isStep3() {
        return this.currentStep === 3;
    }

    get isStep4() {
        return this.currentStep === 4;
    }

    get isStep5() {
        return this.currentStep === 5;
    }

    /**
     * Back button is disabled on the first step.
     */
    get isBackDisabled() {
        return this.currentStep === 1 || this.isLoading;
    }

    /**
     * Next button is disabled only while loading in this skeleton.
     */
    get isNextDisabled() {
        return this.isLoading;
    }

    /**
     * Final step uses a clearer button label.
     */
    get nextButtonLabel() {
        return this.currentStep === 5 ? 'Finish' : 'Next';
    }

    /**
     * Handles Back button click.
     */
    handleBack() {
        this.clearError();

        if (this.currentStep > 1) {
            this.currentStep -= 1;
        }
    }

    /**
     * Handles Next button click.
     *
     * In this skeleton:
     * - Steps 1 to 4 move forward.
     * - Step 5 stays in place.
     *
     * Later:
     * - Step movement will be controlled by validation and successful Apex responses.
     */
    handleNext() {
        this.clearError();

        if (this.currentStep < 5) {
            this.currentStep += 1;
        }
    }

    /**
     * Clears the visible error panel.
     */
    clearError() {
        this.errorState = {
            errorCode: null,
            userMessage: null,
            correlationId: null
        };
    }

    /**
     * Returns CSS class for each stepper item.
     */
    getStepCssClass(isActive, isCompleted) {
        let cssClass = 'uls-step';

        if (isActive) {
            cssClass += ' is-active';
        }

        if (isCompleted) {
            cssClass += ' is-completed';
        }

        return cssClass;
    }
}