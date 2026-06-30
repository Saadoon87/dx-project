// Import the base Lightning Web Component class.
import { LightningElement } from "lwc";

// Import the Apex controller method used to retrieve policy data.
import retrievePolicy from "@salesforce/apex/UlsCalculatorController.retrievePolicy";

// Import the Apex controller method used to fetch the current inflation rate.
import getInflationRate from "@salesforce/apex/UlsCalculatorController.getInflationRate";

// Import the Apex controller method used to calculate inflation-adjusted UAV.
import calculateInflationAdjustedUav from "@salesforce/apex/UlsCalculatorController.calculateInflationAdjustedUav";

// Import the Apex controller method used to calculate suggested premium.
import calculateSuggestedPremium from "@salesforce/apex/UlsCalculatorController.calculateSuggestedPremium";

// Import the Apex controller method used to calculate projected final UAV.
import calculateFinalUav from "@salesforce/apex/UlsCalculatorController.calculateFinalUav";

// Import the Apex controller method used to retrieve available funds for Step 3.
import getFunds from "@salesforce/apex/UlsCalculatorController.getFunds";

// Import the Apex controller method used to retrieve term extension options for Step 3.
import getTermExtensionOptions from "@salesforce/apex/UlsCalculatorController.getTermExtensionOptions";

// Main ULS Calculator component.
export default class UlsCalculator extends LightningElement {
  // Tracks the active step in the guided workflow.
  currentStep = 1;

  // Stores the policy number entered by the user.
  policyNumber = "";

  // Stores policy data returned by Apex/backend after successful retrieval.
  policyData = null;

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

  // Stores available fund options returned from Apex/backend for Step 3.
  availableFunds = [];

  // Stores term extension options returned from Apex/backend for Step 3.
  termExtensionOptions = [];

  // Stores the full term extension response if needed for future display.
  termExtensionOptionsData = null;

  // Generates unique row keys for dynamic fund allocation rows.
  nextAlterationRowKey = 1;

  // Stores Step 3 alteration input state.
  alterationData = {
    regularPremiumEnabled: true,
    requestedMonthlyPremium: null,
    fundSwitchEnabled: false,
    fundSwitchRows: [],
    aspEnabled: false,
    aspAmount: null,
    aspFundId: "",
    redirectionEnabled: false,
    redirectionRows: [],
    termExtensionEnabled: false,
    termExtensionYears: ""
  };

  // Tracks whether the component is currently waiting for an Apex/backend response.
  isLoading = false;

  // Stores the loading message shown to the user.
  loadingMessage = "";

  // Stores the current safe error state shown in the UI.
  errorState = null;

  // Defines the guided workflow steps.
  baseSteps = [
    { number: 1, label: "Policy Retrieval" },
    { number: 2, label: "Define Goal" },
    { number: 3, label: "Apply Alterations" },
    { number: 4, label: "Consolidated Review" },
    { number: 5, label: "Generated Package" }
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

  get displayInvestmentFunds() {
    const funds = this.policyData?.investmentFunds;

    if (!Array.isArray(funds)) {
      return [];
    }

    return funds.map((fund, index) => {
      const allocation =
        fund.allocationPercentage !== null &&
        fund.allocationPercentage !== undefined
          ? `${fund.allocationPercentage}%`
          : "--";

      return {
        key: `${fund.fundId || fund.fundName || "fund"}-${index}`,
        fundName: this.getSafeValue(fund.fundName, "Fund not available"),
        allocationPercentage: allocation
      };
    });
  }

  get hasInvestmentFunds() {
    return this.displayInvestmentFunds.length > 0;
  }

  get displayBenefits() {
    const benefits = this.policyData?.benefits;

    if (!Array.isArray(benefits)) {
      return [];
    }

    return benefits.map((benefit, index) => {
      return {
        key: `${benefit.name || "benefit"}-${index}`,
        name: this.getSafeValue(benefit.name, "Benefit"),
        amount: this.formatCurrency(benefit.amount)
      };
    });
  }

  get hasBenefits() {
    return this.displayBenefits.length > 0;
  }

  // Disables Retrieve while loading, when policy number is blank,
  // or when policy number is not 1 to 10 digits.
  get isRetrieveDisabled() {
    // Trim spaces before checking the value.
    const value = this.policyNumber ? this.policyNumber.trim() : "";

    // Disable while loading.
    if (this.isLoading) {
      return true;
    }

    // Disable if blank.
    if (value.length === 0) {
      return true;
    }

    // Disable if not numbers only from 1 to 10 digits.
    return !/^[0-9]{1,10}$/.test(value);
  }

  // Disables inflation-adjusted calculation until the required input is entered.
  get isCalculateInflationAdjustedDisabled() {
    return (
      this.isLoading || !this.isPositiveNumber(this.goalData.initialTargetUav)
    );
  }

  // Disables Apply Alterations only while an Apex/backend request is running.
  // Step 3 is now activated, so this button should not depend on the old Next button guard.
  get isApplyAlterationsDisabled() {
    return this.isLoading;
  }

  // Disables suggested premium calculation until the required input is entered.
  get isCalculateSuggestedPremiumDisabled() {
    return (
      this.isLoading || !this.isPositiveNumber(this.goalData.requestedFinalUav)
    );
  }

  // Disables final UAV recalculation until the required input is entered.
  get isCalculateFinalUavDisabled() {
    return (
      this.isLoading ||
      !this.isPositiveNumber(this.goalData.requestedMonthlyPremium)
    );
  }

  // Disables Next while loading or when the current step is not ready to continue.
  get isNextDisabled() {
    // Step 4 and Step 5 are still intentionally blocked until they are implemented.
    // Step 3 is now allowed because Apply Alterations is the next approved step.
    if (this.currentStep >= 3) {
      return true;
    }

    // Do not allow navigation while an Apex/backend request is running.
    return this.isLoading;
  }

  // Returns true when one or more Step 2 calculated results are stale.
  get hasStaleGoalResults() {
    return (
      this.goalData.isInflationAdjustedUavStale ||
      this.goalData.isSuggestedPremiumStale ||
      this.goalData.isFinalUavStale
    );
  }

  // Safely displays policy number from backend data or the entered value.
  get displayPolicyNumber() {
    return this.getSafeValue(this.policyData?.policyNumber, this.policyNumber);
  }

  // Safely displays customer name if returned by backend.
  get displayCustomerName() {
    return (
      this.policyData?.customerName ||
      this.policyData?.lifeInsuredName ||
      "Not available"
    );
  }

  // Safely displays maturity date if returned by backend.
  get displayMaturityDate() {
    return this.getSafeValue(this.policyData?.maturityDate, "Not available");
  }

  // Safely displays current premium if returned by backend.
  get displayCurrentPremium() {
    return this.getSafeValue(this.policyData?.currentPremium, "Not available");
  }

  // Safely displays current UAV if returned by backend.
  get displayCurrentUav() {
    return this.formatCurrency(
      this.policyData?.currentUav || this.policyData?.currentUAV
    );
  }

  // Safely displays missed premiums if returned by backend.
  get displayMissedPremiums() {
    return this.getSafeValue(this.policyData?.missedPremiums, "Not available");
  }

  // Safely displays the inflation rate returned from getInflationRate.
  get displayInflationRate() {
    return this.getSafeValue(
      this.inflationRateData?.inflationRate,
      "Not loaded"
    );
  }

  // Displays initial UAV from the inflation-adjusted calculation response.
  get displayInitialUavResult() {
    return this.getSafeValue(
      this.goalData.inflationAdjustedUavResult?.initialUAV,
      "Not calculated"
    );
  }

  // Displays inflation rate from the inflation-adjusted calculation response.
  get displayInflationAdjustedRate() {
    return this.getSafeValue(
      this.goalData.inflationAdjustedUavResult?.inflationRate,
      "Not calculated"
    );
  }

  // Displays remaining years from the inflation-adjusted calculation response.
  get displayRemainingYears() {
    return this.getSafeValue(
      this.goalData.inflationAdjustedUavResult?.remainingYears,
      "Not calculated"
    );
  }

  // Displays inflation-adjusted amount from the backend response.
  get displayInflationAdjustedAmount() {
    return this.getSafeValue(
      this.goalData.inflationAdjustedUavResult?.inflationAdjustedAmount,
      "Not calculated"
    );
  }

  // Displays target final UAV from the suggested premium response.
  get displaySuggestedTargetFinalUav() {
    return this.getSafeValue(
      this.goalData.suggestedPremiumResult?.targetFinalUAV,
      "Not calculated"
    );
  }

  // Displays suggested premium from the backend response.
  get displaySuggestedPremium() {
    return this.getSafeValue(
      this.goalData.suggestedPremiumResult?.suggestedPremium,
      "Not calculated"
    );
  }

  // Displays current premium from the suggested premium response.
  get displaySuggestedCurrentPremium() {
    return this.getSafeValue(
      this.goalData.suggestedPremiumResult?.currentPremium,
      "Not calculated"
    );
  }

  // Displays difference from the suggested premium response.
  get displaySuggestedDifference() {
    return this.getSafeValue(
      this.goalData.suggestedPremiumResult?.difference,
      "Not calculated"
    );
  }

  // Displays requested premium from the final UAV response.
  get displayRequestedPremiumResult() {
    return this.getSafeValue(
      this.goalData.finalUavResult?.requestedPremium,
      "Not calculated"
    );
  }

  // Displays current premium from the final UAV response.
  get displayFinalUavCurrentPremium() {
    return this.getSafeValue(
      this.goalData.finalUavResult?.currentPremium,
      "Not calculated"
    );
  }

  // Displays difference from the final UAV response.
  get displayFinalUavDifference() {
    return this.getSafeValue(
      this.goalData.finalUavResult?.difference,
      "Not calculated"
    );
  }

  // Displays projected final UAV from the backend response.
  get displayProjectedFinalUav() {
    return this.getSafeValue(
      this.goalData.finalUavResult?.projectedFinalUAV,
      "Not calculated"
    );
  }

  // Returns available funds in a safe display shape for Step 3 dropdowns.
  get displayAvailableFunds() {
    if (!Array.isArray(this.availableFunds)) {
      return [];
    }

    return this.availableFunds.map((fund, index) => {
      const rateParts = [];

      if (fund.lowerRate !== null && fund.lowerRate !== undefined) {
        rateParts.push(`Low ${fund.lowerRate}%`);
      }

      if (fund.centralRate !== null && fund.centralRate !== undefined) {
        rateParts.push(`Central ${fund.centralRate}%`);
      }

      if (fund.upperRate !== null && fund.upperRate !== undefined) {
        rateParts.push(`High ${fund.upperRate}%`);
      }

      const rateLabel =
        rateParts.length > 0 ? ` (${rateParts.join(" / ")})` : "";

      return {
        key: `${fund.fundId || fund.fundName || "fund"}-${index}`,
        value: fund.fundId,
        label: `${this.getSafeValue(fund.fundName, "Unnamed Fund")}${rateLabel}`
      };
    });
  }

  // Returns true when at least one available fund option exists.
  get hasAvailableFunds() {
    return this.displayAvailableFunds.length > 0;
  }

  // Calculates total allocation percentage for Fund Switching rows.
  get fundSwitchTotal() {
    return this.calculateAllocationTotal(this.alterationData.fundSwitchRows);
  }

  // Calculates total allocation percentage for Future Premium Redirection rows.
  get redirectionTotal() {
    return this.calculateAllocationTotal(this.alterationData.redirectionRows);
  }

  // Shows whether Fund Switching allocation totals exactly 100%.
  get isFundSwitchTotalValid() {
    return this.fundSwitchTotal === 100;
  }

  // Shows whether Future Premium Redirection allocation totals exactly 100%.
  get isRedirectionTotalValid() {
    return this.redirectionTotal === 100;
  }

  // CSS class for Fund Switching total validation display.
  get fundSwitchTotalClass() {
    return this.isFundSwitchTotalValid ? "uls-positive" : "uls-error-message";
  }

  // CSS class for Redirection total validation display.
  get redirectionTotalClass() {
    return this.isRedirectionTotalValid ? "uls-positive" : "uls-error-message";
  }

  // Displays the requested monthly premium used by Step 3.
  get displayAlterationRequestedPremium() {
    return this.formatCurrency(this.alterationData.requestedMonthlyPremium);
  }

  // Returns term extension options in a safe dropdown shape.
  get displayTermExtensionOptions() {
    if (!Array.isArray(this.termExtensionOptions)) {
      return [];
    }

    return this.termExtensionOptions.map((option) => {
      return {
        key: `term-${option}`,
        value: String(option),
        label: `${option} Years`
      };
    });
  }

  // Returns true when term extension options are available.
  get hasTermExtensionOptions() {
    return this.displayTermExtensionOptions.length > 0;
  }

  // Displays the selected term option safely.
  get displaySelectedTermExtension() {
    return this.alterationData.termExtensionYears
      ? `${this.alterationData.termExtensionYears} Years`
      : "Not selected";
  }

  // Handles changes in the Policy Number input.
  handlePolicyNumberChange(event) {
    // For lightning-input, event.detail.value is the safest value source.
    this.policyNumber = event.detail.value || "";

    // Trim spaces before validation.
    const value = this.policyNumber.trim();

    // Check if the field is blank.
    const isBlank = value.length === 0;

    // Check whether the value is numbers only from 1 to 10 digits.
    const isDigitsOnly = /^[0-9]{1,10}$/.test(value);

    // Show a validation message only when the user entered an invalid value.
    if (!isBlank && !isDigitsOnly) {
      event.target.setCustomValidity(
        "Policy Number must contain numbers only, maximum 10 digits."
      );
    } else {
      event.target.setCustomValidity("");
    }

    // Display or clear the validation message under the input.
    event.target.reportValidity();

    // Clear old Apex/backend errors when the user edits the policy number.
    this.clearError();

    // Clear old policy data because the policy number changed.
    this.policyData = null;

    // Reset Step 2 data because it belongs to the previously retrieved policy.
    this.resetGoalData();
  }

  // Handles the Retrieve Policy button click.
  async handleRetrievePolicy() {
    // Clear any previous error before starting a new action.
    this.clearError();

    // Clean up extra spaces from the entered policy number.
    const cleanedPolicyNumber = this.policyNumber
      ? this.policyNumber.trim()
      : "";

    // Validate that policy number is not blank before calling Apex.
    if (!cleanedPolicyNumber) {
      this.errorState = {
        userMessage:
          "Please enter a policy number before retrieving policy data.",
        errorCode: "VALIDATION_ERROR",
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
    this.startLoading("Retrieving policy data...");

    try {
      // Call Apex controller. Apex will call the service/backend layer.
      const response = await retrievePolicy({
        policyNumber: cleanedPolicyNumber
      });

      // If Apex returned success, store the policy data and move to Step 2.
      if (this.handleApiSuccess(response)) {
        this.policyData = response.data;
        this.currentStep = 2;
        this.resetGoalData();
        return;
      }

      // If Apex returned a safe business/backend error, show it to the user.
      this.setApiError(
        response,
        "Unable to retrieve policy data. Please try again or contact support."
      );
    } catch (error) {
      // Catch unexpected browser/Apex transport errors safely.
      this.setUnexpectedError(error);
    } finally {
      // Always stop loading after the action completes.
      this.stopLoading();
    }
  }

  // Handles typing in the Initial Target UAV field.
  handleInitialTargetUavChange(event) {
    // Store the entered value.
    this.goalData = {
      ...this.goalData,
      initialTargetUav: event.target.value,
      isInflationAdjustedUavStale:
        this.goalData.inflationAdjustedUavResult !== null
    };
    // Ask lightning-input to show inline validation feedback immediately.
    if (event.target && typeof event.target.reportValidity === "function") {
      event.target.reportValidity();
    }

    // Clear old errors when the user updates input.
    this.clearError();
  }

  // Handles typing in the Requested Final UAV field.
  handleRequestedFinalUavChange(event) {
    // Store the entered value.
    this.goalData = {
      ...this.goalData,
      requestedFinalUav: event.target.value,
      isSuggestedPremiumStale: this.goalData.suggestedPremiumResult !== null
    };

    // Ask lightning-input to show inline validation feedback immediately.
    if (event.target && typeof event.target.reportValidity === "function") {
      event.target.reportValidity();
    }

    // Clear old errors when the user updates input.
    this.clearError();
  }

  // Handles typing in the Requested Monthly Premium field.
  handleRequestedMonthlyPremiumChange(event) {
    // Store the entered value.
    this.goalData = {
      ...this.goalData,
      requestedMonthlyPremium: event.target.value,
      isFinalUavStale: this.goalData.finalUavResult !== null
    };
    // Ask lightning-input to show inline validation feedback immediately.
    if (event.target && typeof event.target.reportValidity === "function") {
      event.target.reportValidity();
    }

    // Clear old errors when the user updates input.
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
    this.startLoading("Loading inflation rate...");

    try {
      // Call Apex method.
      const response = await getInflationRate();

      // If successful, store the inflation rate response.
      if (this.handleApiSuccess(response)) {
        this.inflationRateData = response.data;
        return;
      }

      // If failed, show safe error details.
      this.setApiError(
        response,
        "Unable to load inflation rate. Please try again or contact support."
      );
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
        userMessage:
          "Please enter a positive Initial Target UAV before calculating.",
        errorCode: "VALIDATION_ERROR",
        correlationId: null
      };
      return;
    }

    // Prevent duplicate actions while loading.
    if (this.isLoading) {
      return;
    }

    // Start loading state.
    this.startLoading("Calculating inflation-adjusted UAV...");

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
      this.setApiError(
        response,
        "Unable to calculate inflation-adjusted UAV. Please try again or contact support."
      );
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
        userMessage:
          "Please enter a positive Requested Final UAV before calculating.",
        errorCode: "VALIDATION_ERROR",
        correlationId: null
      };
      return;
    }

    // Prevent duplicate actions while loading.
    if (this.isLoading) {
      return;
    }

    // Start loading state.
    this.startLoading("Calculating suggested premium...");

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
        if (
          !this.goalData.requestedMonthlyPremium &&
          response.data?.suggestedPremium !== undefined
        ) {
          this.goalData = {
            ...this.goalData,
            requestedMonthlyPremium: response.data.suggestedPremium
          };
        }

        return;
      }

      // If failed, show safe error details.
      this.setApiError(
        response,
        "Unable to calculate suggested premium. Please try again or contact support."
      );
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
        userMessage:
          "Please enter a positive Requested Monthly Premium before recalculating final UAV.",
        errorCode: "VALIDATION_ERROR",
        correlationId: null
      };
      return;
    }

    // Prevent duplicate actions while loading.
    if (this.isLoading) {
      return;
    }

    // Start loading state.
    this.startLoading("Recalculating final UAV...");

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
      this.setApiError(
        response,
        "Unable to recalculate final UAV. Please try again or contact support."
      );
    } catch (error) {
      // Catch unexpected browser/Apex transport errors safely.
      this.setUnexpectedError(error);
    } finally {
      // Always stop loading.
      this.stopLoading();
    }
  }

  // Moves from Step 2 into Step 3: Apply Alterations.
  async handleApplyAlterations() {
    // Do not navigate while an Apex/backend request is running.
    if (this.isLoading) {
      return;
    }

    // Clear any previous non-blocking message before entering Step 3.
    this.clearError();

    // Copy the Step 2 requested monthly premium into Step 3 premium change.
    this.alterationData = {
      ...this.alterationData,
      requestedMonthlyPremium:
        this.goalData.requestedMonthlyPremium ||
        this.goalData.finalUavResult?.requestedPremium ||
        null
    };

    // Step 3 is now activated.
    this.currentStep = 3;

    // Load Step 3 reference data for dropdowns.
    // This includes available funds and term extension options.
    await this.loadAvailableFunds();
    await this.loadTermExtensionOptions();
  }

  // Loads available funds from Apex/backend for Step 3 dropdowns.
  async loadAvailableFunds() {
    // Avoid duplicate backend calls if funds are already loaded.
    if (this.availableFunds.length > 0) {
      this.ensureDefaultFundsSelected();
      return;
    }

    this.startLoading("Loading available funds...");

    try {
      const response = await getFunds();

      if (this.handleApiSuccess(response)) {
        const funds = response.data?.funds;

        this.availableFunds = Array.isArray(funds) ? funds : [];
        this.ensureDefaultFundsSelected();
        return;
      }

      this.setApiError(
        response,
        "Unable to load available funds. Please try again or contact support."
      );
    } catch (error) {
      this.setUnexpectedError(error);
    } finally {
      this.stopLoading();
    }
  }

  // Loads valid term extension options from Apex/backend for Step 3.
  async loadTermExtensionOptions() {
    // Avoid duplicate backend calls if options are already loaded for this session.
    if (this.termExtensionOptions.length > 0) {
      return;
    }

    // Do not call backend without a policy number.
    if (!this.policyNumber) {
      this.errorState = {
        userMessage:
          "Policy number is missing. Please retrieve the policy again before applying alterations.",
        errorCode: "VALIDATION_ERROR",
        correlationId: null
      };
      return;
    }

    this.startLoading("Loading term extension options...");

    try {
      const response = await getTermExtensionOptions({
        policyNumber: this.policyNumber
      });

      if (this.handleApiSuccess(response)) {
        const options = response.data?.options;

        this.termExtensionOptions = Array.isArray(options) ? options : [];
        this.termExtensionOptionsData = response.data || null;

        // Default the dropdown to the first backend option if nothing is selected yet.
        if (
          !this.alterationData.termExtensionYears &&
          this.termExtensionOptions.length > 0
        ) {
          this.alterationData = {
            ...this.alterationData,
            termExtensionYears: String(this.termExtensionOptions[0])
          };
        }

        return;
      }

      this.setApiError(
        response,
        "Unable to load term extension options. Please try again or contact support."
      );
    } catch (error) {
      this.setUnexpectedError(error);
    } finally {
      this.stopLoading();
    }
  }

  // Creates a new fund allocation row for fund switching or redirection.
  createFundAllocationRow(prefix) {
    const defaultFundId =
      this.availableFunds.length > 0 ? this.availableFunds[0].fundId : "";

    const row = {
      key: `${prefix}-${this.nextAlterationRowKey}`,
      fundId: defaultFundId,
      allocationPercentage: null
    };

    this.nextAlterationRowKey += 1;

    return row;
  }

  // Ensures Step 3 fund-based sections have at least one row/default fund.
  ensureDefaultFundsSelected() {
    const defaultFundId =
      this.availableFunds.length > 0 ? this.availableFunds[0].fundId : "";

    if (!defaultFundId) {
      return;
    }

    const fundSwitchRows =
      this.alterationData.fundSwitchRows.length > 0
        ? this.alterationData.fundSwitchRows
        : [this.createFundAllocationRow("switch")];

    const redirectionRows =
      this.alterationData.redirectionRows.length > 0
        ? this.alterationData.redirectionRows
        : [this.createFundAllocationRow("redirection")];

    this.alterationData = {
      ...this.alterationData,
      aspFundId: this.alterationData.aspFundId || defaultFundId,
      fundSwitchRows: fundSwitchRows.map((row) => {
        return {
          ...row,
          fundId: row.fundId || defaultFundId
        };
      }),
      redirectionRows: redirectionRows.map((row) => {
        return {
          ...row,
          fundId: row.fundId || defaultFundId
        };
      })
    };
  }

  // Calculates allocation total for dynamic allocation rows.
  calculateAllocationTotal(rows) {
    if (!Array.isArray(rows)) {
      return 0;
    }

    return rows.reduce((total, row) => {
      const numericValue = Number(row.allocationPercentage);
      return total + (Number.isNaN(numericValue) ? 0 : numericValue);
    }, 0);
  }

  // Handles changes to the Step 3 requested monthly premium.
  handleAlterationRequestedPremiumChange(event) {
    this.alterationData = {
      ...this.alterationData,
      requestedMonthlyPremium: event.target.value
    };

    this.clearError();
  }

  // Enables/disables the Fund Switching section.
  handleFundSwitchToggle(event) {
    const enabled = event.target.checked;

    this.alterationData = {
      ...this.alterationData,
      fundSwitchEnabled: enabled,
      fundSwitchRows:
        this.alterationData.fundSwitchRows.length > 0
          ? this.alterationData.fundSwitchRows
          : [this.createFundAllocationRow("switch")]
    };

    this.ensureDefaultFundsSelected();
  }

  // Adds a Fund Switching allocation row.
  handleAddFundSwitchRow() {
    this.alterationData = {
      ...this.alterationData,
      fundSwitchRows: [
        ...this.alterationData.fundSwitchRows,
        this.createFundAllocationRow("switch")
      ]
    };
  }

  // Removes a Fund Switching allocation row.
  handleRemoveFundSwitchRow(event) {
    const rowKey = event.currentTarget.dataset.key;

    this.alterationData = {
      ...this.alterationData,
      fundSwitchRows: this.alterationData.fundSwitchRows.filter((row) => {
        return row.key !== rowKey;
      })
    };
  }

  // Handles selected fund changes in Fund Switching rows.
  handleFundSwitchFundChange(event) {
    const rowKey = event.currentTarget.dataset.key;
    const value = event.detail?.value || event.target.value;

    this.alterationData = {
      ...this.alterationData,
      fundSwitchRows: this.alterationData.fundSwitchRows.map((row) => {
        return row.key === rowKey ? { ...row, fundId: value } : row;
      })
    };
  }

  // Handles allocation percentage changes in Fund Switching rows.
  handleFundSwitchAllocationChange(event) {
    const rowKey = event.currentTarget.dataset.key;
    const value = event.target.value;

    this.alterationData = {
      ...this.alterationData,
      fundSwitchRows: this.alterationData.fundSwitchRows.map((row) => {
        return row.key === rowKey
          ? { ...row, allocationPercentage: value }
          : row;
      })
    };
  }

  // Enables/disables the ASP section.
  handleAspToggle(event) {
    this.alterationData = {
      ...this.alterationData,
      aspEnabled: event.target.checked
    };

    this.ensureDefaultFundsSelected();
  }

  // Handles ASP amount changes.
  handleAspAmountChange(event) {
    this.alterationData = {
      ...this.alterationData,
      aspAmount: event.target.value
    };
  }

  // Handles ASP fund selection.
  handleAspFundChange(event) {
    this.alterationData = {
      ...this.alterationData,
      aspFundId: event.detail?.value || event.target.value
    };
  }

  // Enables/disables the Future Premium Redirection section.
  handleRedirectionToggle(event) {
    const enabled = event.target.checked;

    this.alterationData = {
      ...this.alterationData,
      redirectionEnabled: enabled,
      redirectionRows:
        this.alterationData.redirectionRows.length > 0
          ? this.alterationData.redirectionRows
          : [this.createFundAllocationRow("redirection")]
    };

    this.ensureDefaultFundsSelected();
  }

  // Adds a Future Premium Redirection row.
  handleAddRedirectionRow() {
    this.alterationData = {
      ...this.alterationData,
      redirectionRows: [
        ...this.alterationData.redirectionRows,
        this.createFundAllocationRow("redirection")
      ]
    };
  }

  // Removes a Future Premium Redirection row.
  handleRemoveRedirectionRow(event) {
    const rowKey = event.currentTarget.dataset.key;

    this.alterationData = {
      ...this.alterationData,
      redirectionRows: this.alterationData.redirectionRows.filter((row) => {
        return row.key !== rowKey;
      })
    };
  }

  // Handles selected fund changes in Future Premium Redirection rows.
  handleRedirectionFundChange(event) {
    const rowKey = event.currentTarget.dataset.key;
    const value = event.detail?.value || event.target.value;

    this.alterationData = {
      ...this.alterationData,
      redirectionRows: this.alterationData.redirectionRows.map((row) => {
        return row.key === rowKey ? { ...row, fundId: value } : row;
      })
    };
  }

  // Handles allocation percentage changes in Future Premium Redirection rows.
  handleRedirectionAllocationChange(event) {
    const rowKey = event.currentTarget.dataset.key;
    const value = event.target.value;

    this.alterationData = {
      ...this.alterationData,
      redirectionRows: this.alterationData.redirectionRows.map((row) => {
        return row.key === rowKey
          ? { ...row, allocationPercentage: value }
          : row;
      })
    };
  }

  // Enables/disables the Increase ULS Term section.
  handleTermExtensionToggle(event) {
    this.alterationData = {
      ...this.alterationData,
      termExtensionEnabled: event.target.checked
    };
  }

  // Handles selected term extension years.
  handleTermExtensionYearsChange(event) {
    this.alterationData = {
      ...this.alterationData,
      termExtensionYears: event.detail?.value || event.target.value
    };
  }

  // Moves to the previous step.
  handleBack() {
    if (this.currentStep > 1) {
      this.currentStep -= 1;
    }
  }

  // Moves to the next step.
  handleNext() {
    // Production guard: Step 4+ is not available yet.
    // Step 3 is now allowed, but later steps remain blocked until approved.
    if (this.currentStep >= 3) {
      this.errorState = {
        hasError: true,
        errorCode: "STEP_NOT_AVAILABLE",
        userMessage:
          "The next step is not available yet. Please complete the current available calculator steps.",
        correlationId: null,
        supportDetails: null
      };
      return;
    }

    // Do not navigate while loading.
    if (this.isNextDisabled) {
      return;
    }

    if (this.currentStep < this.totalSteps) {
      this.currentStep += 1;
    }
  }

  // Clears the current error from the screen.
  handleResetCalculator() {
    this.currentStep = 1;
    this.policyNumber = "";
    this.policyData = null;
    this.inflationRateData = null;
    this.availableFunds = [];
    this.termExtensionOptions = [];
    this.termExtensionOptionsData = null;
    this.isLoading = false;
    this.loadingMessage = "";
    this.errorState = null;

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

    this.alterationData = {
      regularPremiumEnabled: true,
      requestedMonthlyPremium: null,
      fundSwitchEnabled: false,
      fundSwitchRows: [],
      aspEnabled: false,
      aspAmount: null,
      aspFundId: "",
      redirectionEnabled: false,
      redirectionRows: [],
      termExtensionEnabled: false,
      termExtensionYears: ""
    };
  }

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
    this.loadingMessage = "";
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
        userMessage:
          "No response was received. Please try again or contact support.",
        errorCode: "EMPTY_RESPONSE",
        correlationId: null
      };
      return;
    }

    this.errorState = {
      userMessage: response.userMessage || fallbackMessage,
      errorCode: response.errorCode || "UNKNOWN_ERROR",
      correlationId: response.correlationId || null
    };
  }

  formatCurrency(value) {
    if (value === null || value === undefined || value === "") {
      return "Not available";
    }

    const numericValue = Number(value);

    if (Number.isNaN(numericValue)) {
      return String(value);
    }

    return new Intl.NumberFormat("en-US", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(numericValue);
  }

  // Converts unexpected JavaScript/Apex transport errors into the shared error UI state.
  setUnexpectedError() {
    this.errorState = {
      hasError: true,
      errorCode: "UNEXPECTED_CLIENT_ERROR",
      userMessage:
        "Something went wrong while processing your request. Please try again or contact support.",
      correlationId: null,
      supportDetails: null
    };
  }

  // Returns the CSS class for each step in the visual stepper.
  getStepCssClass(stepNumber) {
    if (stepNumber === this.currentStep) {
      return "uls-step uls-step-active";
    }

    if (stepNumber < this.currentStep) {
      return "uls-step uls-step-complete";
    }

    return "uls-step";
  }

  // Safely returns a display value without showing undefined/null in the UI.
  getSafeValue(value, fallbackValue) {
    if (value === null || value === undefined || value === "") {
      return fallbackValue;
    }

    return value;
  }

  // Converts unexpected JavaScript/Apex errors into a safe readable message.
  reduceError(error) {
    if (Array.isArray(error?.body)) {
      return error.body.map((item) => item.message).join(", ");
    }

    if (typeof error?.body?.message === "string") {
      return error.body.message;
    }

    if (typeof error?.message === "string") {
      return error.message;
    }

    return "Unexpected error occurred. Please try again or contact support.";
  }
}
