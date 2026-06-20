import { createElement } from "@lwc/engine-dom";
import UlsCalculator from "c/ulsCalculator";

import retrievePolicy from "@salesforce/apex/UlsCalculatorController.retrievePolicy";
import calculateInflationAdjustedUav from "@salesforce/apex/UlsCalculatorController.calculateInflationAdjustedUav";

jest.mock(
  "@salesforce/apex/UlsCalculatorController.retrievePolicy",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/UlsCalculatorController.getInflationRate",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/UlsCalculatorController.calculateInflationAdjustedUav",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/UlsCalculatorController.calculateSuggestedPremium",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/UlsCalculatorController.calculateFinalUav",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

// Allows pending Promise callbacks and LWC rendering to finish.
const flushPromises = () => Promise.resolve().then(() => Promise.resolve());
function createComponent() {
  const element = createElement("c-uls-calculator", {
    is: UlsCalculator
  });

  document.body.appendChild(element);

  return element;
}

function getLightningInputByName(element, inputName) {
  return [...element.shadowRoot.querySelectorAll("lightning-input")].find(
    (input) => {
      return input.name === inputName;
    }
  );
}

function getLightningButtonByLabel(element, label) {
  return [...element.shadowRoot.querySelectorAll("lightning-button")].find(
    (button) => {
      return button.label === label;
    }
  );
}

function changeLightningInput(input, value) {
  input.value = value;

  // Some component versions call reportValidity on numeric lightning-input.
  // The Jest base component may not always provide it, so we safely stub it here.
  input.reportValidity = jest.fn();

  input.dispatchEvent(new CustomEvent("change"));
}

async function moveToStep2WithSuccessfulRetrieve(element) {
  retrievePolicy.mockResolvedValue({
    success: true,
    data: {
      policyNumber: "POL12345",
      customerName: "Test Customer",
      maturityDate: "2036-12-31",
      currentPremium: 1000,
      currentUav: 50000,
      missedPremiums: 0
    },
    errorCode: null,
    userMessage: null,
    correlationId: "TEST-CORR-SUCCESS-001"
  });

  const policyInput = getLightningInputByName(element, "policyNumber");
  changeLightningInput(policyInput, "POL12345");

  await flushPromises();

  const retrieveButton = getLightningButtonByLabel(element, "Retrieve Policy");
  retrieveButton.click();

  await flushPromises();
  await flushPromises();
}

describe("c-uls-calculator", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }

    jest.clearAllMocks();
  });

  it("renders Step 1 on initial load", () => {
    const element = createComponent();

    const policyInput = getLightningInputByName(element, "policyNumber");

    expect(element.shadowRoot.textContent).toContain("ULS Calculator");
    expect(element.shadowRoot.textContent).toContain(
      "Step 1: Policy Retrieval"
    );
    expect(policyInput).not.toBeUndefined();
    expect(policyInput.label).toBe("Policy Number");
  });

  it("keeps Retrieve Policy disabled when policy number is blank", () => {
    const element = createComponent();

    const retrieveButton = getLightningButtonByLabel(
      element,
      "Retrieve Policy"
    );

    expect(retrieveButton).not.toBeUndefined();
    expect(retrieveButton.disabled).toBe(true);
  });

  it("enables Retrieve Policy after policy number input", async () => {
    const element = createComponent();

    const policyInput = getLightningInputByName(element, "policyNumber");
    changeLightningInput(policyInput, "POL12345");

    await flushPromises();

    const retrieveButton = getLightningButtonByLabel(
      element,
      "Retrieve Policy"
    );

    expect(retrieveButton.disabled).toBe(false);
  });

  it("stores policy data and moves to Step 2 after successful retrieve", async () => {
    const element = createComponent();

    await moveToStep2WithSuccessfulRetrieve(element);

    expect(retrievePolicy).toHaveBeenCalledWith({
      policyNumber: "POL12345"
    });

    expect(element.shadowRoot.textContent).toContain("Step 2: Define Goal");
    expect(element.shadowRoot.textContent).toContain(
      "Retrieved Policy Summary"
    );
    expect(element.shadowRoot.textContent).toContain("Test Customer");
    expect(element.shadowRoot.textContent).toContain("50000");
  });

  it("displays safe backend/business error message and correlation ID", async () => {
    retrievePolicy.mockResolvedValue({
      success: false,
      data: null,
      errorCode: "POLICY_NOT_FOUND",
      userMessage:
        "Policy not found. Please check the policy number and try again.",
      correlationId: "TEST-CORR-ERROR-001"
    });

    const element = createComponent();

    const policyInput = getLightningInputByName(element, "policyNumber");
    changeLightningInput(policyInput, "POL-NOT-FOUND");

    await flushPromises();

    const retrieveButton = getLightningButtonByLabel(
      element,
      "Retrieve Policy"
    );
    retrieveButton.click();

    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.textContent).toContain(
      "We could not complete this action"
    );
    expect(element.shadowRoot.textContent).toContain(
      "Policy not found. Please check the policy number and try again."
    );
    expect(element.shadowRoot.textContent).toContain("POLICY_NOT_FOUND");
    expect(element.shadowRoot.textContent).toContain("TEST-CORR-ERROR-001");
  });

  it("enables Step 2 calculation buttons when positive numeric inputs are entered", async () => {
    const element = createComponent();

    await moveToStep2WithSuccessfulRetrieve(element);

    changeLightningInput(
      getLightningInputByName(element, "initialTargetUav"),
      "100000"
    );
    changeLightningInput(
      getLightningInputByName(element, "requestedFinalUav"),
      "250000"
    );
    changeLightningInput(
      getLightningInputByName(element, "requestedMonthlyPremium"),
      "3000"
    );

    await flushPromises();

    expect(
      getLightningButtonByLabel(element, "Calculate Inflation-Adjusted UAV")
        .disabled
    ).toBe(false);
    expect(
      getLightningButtonByLabel(element, "Calculate Suggested Premium").disabled
    ).toBe(false);
    expect(
      getLightningButtonByLabel(element, "Recalculate Final UAV").disabled
    ).toBe(false);
  });

  it("marks inflation-adjusted UAV result as stale after input changes post-calculation", async () => {
    calculateInflationAdjustedUav.mockResolvedValue({
      success: true,
      data: {
        policyNumber: "POL12345",
        initialUAV: 100000,
        inflationRate: 5,
        remainingYears: 10,
        inflationAdjustedAmount: 162889.46
      },
      errorCode: null,
      userMessage: null,
      correlationId: "TEST-CORR-CALC-001"
    });

    const element = createComponent();

    await moveToStep2WithSuccessfulRetrieve(element);

    const initialTargetInput = getLightningInputByName(
      element,
      "initialTargetUav"
    );
    changeLightningInput(initialTargetInput, "100000");

    await flushPromises();

    const calculateButton = getLightningButtonByLabel(
      element,
      "Calculate Inflation-Adjusted UAV"
    );
    calculateButton.click();

    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.textContent).toContain("162889.46");
    expect(element.shadowRoot.textContent).not.toContain(
      "One or more inputs changed after calculation. Please recalculate before continuing."
    );

    changeLightningInput(initialTargetInput, "110000");

    await flushPromises();

    expect(element.shadowRoot.textContent).toContain(
      "One or more inputs changed after calculation. Please recalculate before continuing."
    );
  });

  it("displays safe fallback behavior for unexpected Apex errors", async () => {
    retrievePolicy.mockRejectedValue({
      body: {
        message:
          "Raw Apex stack trace or transport error that should not be shown"
      }
    });

    const element = createComponent();

    const policyInput = getLightningInputByName(element, "policyNumber");
    changeLightningInput(policyInput, "POL12345");

    await flushPromises();

    const retrieveButton = getLightningButtonByLabel(
      element,
      "Retrieve Policy"
    );
    retrieveButton.click();

    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.textContent).toContain(
      "Something went wrong while processing your request. Please try again or contact support."
    );
    expect(element.shadowRoot.textContent).toContain("LWC_APEX_CALL_FAILED");
    expect(element.shadowRoot.textContent).not.toContain(
      "Raw Apex stack trace"
    );
  });

  it("keeps Next disabled on Step 2 because Step 3 is not implemented yet", async () => {
    const element = createComponent();

    await moveToStep2WithSuccessfulRetrieve(element);

    const nextButton = getLightningButtonByLabel(element, "Next");

    expect(nextButton).not.toBeUndefined();
    expect(nextButton.disabled).toBe(true);
    expect(element.shadowRoot.textContent).toContain("Step 2: Define Goal");
  });
});
