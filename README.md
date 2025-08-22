DeCredit
========

A smart contract for personalized credit scoring in decentralized finance (DeFi), enabling dynamic interest rates and loan terms based on a user's on-chain borrowing and repayment history.

* * * * *

📄 Table of Contents
--------------------

-   Introduction

-   How It Works

-   Key Features

-   Constants and Variables

-   Functions

-   Scoring Logic

-   Errors

-   Security

-   Deployment

-   Usage Examples

-   Contributing

-   License

* * * * *

💡 Introduction
---------------

**DeCredit** is a Clarity smart contract that addresses a critical challenge in decentralized lending: the lack of a credit scoring system. Traditional finance relies on credit scores to assess a borrower's risk and determine loan terms. This contract brings a similar, but decentralized, concept to the blockchain by creating on-chain credit profiles for users. By analyzing a user's borrowing history, payment behavior, and collateral management, DeCredit assigns a transparent, non-custodial credit score. This score then allows for a more efficient and equitable lending market, where users with strong financial discipline can access more favorable interest rates and loan terms, moving away from the one-size-fits-all model prevalent in the current landscape.

* * * * *

⚙️ How It Works
---------------

The contract operates by mapping user addresses to a comprehensive credit profile. When a user interacts with the contract (e.g., by applying for a loan or making a payment), their profile is updated. The core of the system is the `calculate-and-update-credit-score` function, which uses a multifaceted algorithm to determine a user's creditworthiness. This algorithm considers both positive and negative behaviors, such as on-time payments, consistent collateralization, and missed payments. The resulting score, which is stored on-chain, can then be referenced by other DeFi protocols to offer personalized loan products.

* * * * *

✨ Key Features
--------------

-   **Personalized Interest Rates**: Interest rates are dynamically adjusted based on a user's credit score, rewarding responsible borrowers with lower rates.

-   **On-Chain Credit Profile**: Each user has a unique credit profile stored immutably on the Stacks blockchain, providing a transparent and verifiable record of their borrowing history.

-   **Holistic Scoring Algorithm**: The credit score is calculated using multiple factors, including successful payments, collateral ratios, and total loan history, providing a robust and fair assessment.

-   **Decentralized and Non-Custodial**: The system is fully decentralized, with no central authority controlling or altering credit scores. Users retain full control of their assets and data.

-   **Open and Extensible**: The contract can be easily integrated with other DeFi protocols to enable innovative lending products, such as under-collateralized loans or revolving credit lines.

* * * * *

📦 Constants and Variables
--------------------------

| Name | Type | Description |
| --- | --- | --- |
| `CONTRACT-OWNER` | `principal` | The address of the contract's deployer. |
| `MIN-CREDIT-SCORE` | `uint` | The minimum possible credit score (`u300`). |
| `MAX-CREDIT-SCORE` | `uint` | The maximum possible credit score (`u850`). |
| `DEFAULT-SCORE` | `uint` | The starting score for new users (`u500`). |
| `SCORE-IMPROVEMENT-FACTOR` | `uint` | The factor used to increase scores. Not currently used in the final version. |
| `SCORE-PENALTY-FACTOR` | `uint` | The base penalty for missed payments. |
| `user-profiles` | `map` | Stores comprehensive credit information for each `principal`. |
| `active-loans` | `map` | Tracks detailed information for active loans by `loan-id`. |
| `payment-history` | `map` | Records individual payment history for behavioral analysis. |
| `next-loan-id` | `data-var` | A counter to assign a unique ID to each new loan. |
| `total-users` | `data-var` | Tracks the total number of users with a profile. |

* * * * *

🛠️ Functions
-------------

### Private Functions

-   `calculate-base-score (profile)`:

    -   **Description**: Calculates a preliminary score based on a user's payment and repayment ratios.

    -   **Parameters**: `profile` (a tuple of user data).

    -   **Returns**: A `uint` representing the base score.

-   `validate-loan-params (amount, collateral, duration)`:

    -   **Description**: Ensures that loan parameters meet minimum requirements, such as minimum collateralization and a valid duration.

    -   **Parameters**: `amount` (`uint`), `collateral` (`uint`), `duration` (`uint`).

    -   **Returns**: A `bool` indicating if the parameters are valid.

-   `update-user-stats (user, amount, collateral)`:

    -   **Description**: Updates a user's profile statistics after a loan application, including total loans, borrowed amount, and average collateral ratio.

    -   **Parameters**: `user` (`principal`), `amount` (`uint`), `collateral` (`uint`).

    -   **Returns**: `(ok true)` or an error.

### Public Functions

-   `get-or-create-profile (user)`:

    -   **Description**: Retrieves a user's credit profile or creates a new one with the default score if it doesn't exist.

    -   **Parameters**: `user` (`principal`).

    -   **Returns**: `(ok { ... })` with the profile data or an error.

-   `apply-for-loan (amount, collateral-amount, duration)`:

    -   **Description**: Allows a user to apply for a loan. It validates the parameters, checks the user's credit score, and issues a loan with a personalized interest rate.

    -   **Parameters**: `amount` (`uint`), `collateral-amount` (`uint`), `duration` (`uint`).

    -   **Returns**: `(ok { loan-id: ..., interest-rate: ... })` or an error.

-   `make-payment (loan-id, amount)`:

    -   **Description**: Records a payment for a specific loan. It updates the payment history and marks the loan as paid if the full amount is settled.

    -   **Parameters**: `loan-id` (`uint`), `amount` (`uint`).

    -   **Returns**: `(ok true)` or an error.

-   `calculate-and-update-credit-score (user)`:

    -   **Description**: The main scoring function. It performs a comprehensive analysis of the user's profile and updates their credit score based on a set of weighted factors.

    -   **Parameters**: `user` (`principal`).

    -   **Returns**: `(ok { ... })` with the new score and a detailed breakdown of the calculation or an error.

* * * * *

📊 Scoring Logic
----------------

The `calculate-and-update-credit-score` function uses a detailed algorithm to determine the final credit score. The score is a combination of a `base-score` and several bonus and penalty factors.

-   **Base Score**: Calculated from the ratio of successful payments to total loans and the ratio of total repaid to total borrowed.

-   **Bonuses**:

    -   `payment-consistency-bonus`: A bonus for a high ratio (>= 90%) of successful payments.

    -   `high-volume-bonus`: A bonus for users with a large number of loans (>= 10).

    -   `collateral-bonus`: A bonus for maintaining a high average collateral ratio (>= 150%).

    -   `recent-activity-bonus`: A small bonus for recent activity on the contract.

-   **Penalties**:

    -   `missed-payment-penalty`: A penalty for the ratio of missed payments.

    -   `low-collateral-penalty`: A penalty for an average collateral ratio below a certain threshold (< 130%).

The final score is capped between **MIN-CREDIT-SCORE** (`u300`) and **MAX-CREDIT-SCORE** (`u850`) to prevent extreme values.

* * * * *

🛑 Errors
---------

-   `ERR-NOT-AUTHORIZED (u100)`: The transaction sender is not authorized to perform this action.

-   `ERR-INVALID-AMOUNT (u101)`: The amount provided is not valid (e.g., zero or negative).

-   `ERR-INSUFFICIENT-SCORE (u102)`: The user's credit score is below the minimum required for a loan.

-   `ERR-LOAN-NOT-FOUND (u103)`: The specified loan ID does not exist.

-   `ERR-ALREADY-PAID (u104)`: The loan has already been paid in full.

-   `ERR-INVALID-PARAMETER (u105)`: A parameter passed to a function is invalid.

* * * * *

🔒 Security
-----------

-   **Input Validation**: All public functions include checks to validate input parameters, preventing common issues like zero-value transactions or invalid loan durations.

-   **Access Control**: The `make-payment` function ensures that only the original borrower can make payments on their loan.

-   **Immutability**: Once deployed, the core logic of the smart contract cannot be changed, ensuring transparency and reliability.

* * * * *

🚀 Deployment
-------------

The contract is written in **Clarity**, a decidable language for smart contracts on the Stacks blockchain. To deploy this contract, you will need a Stacks development environment, such as the `clarity-cli` or a web-based IDE like the Stacks sandbox.

1.  **Clone the repository**: `git clone [repository-url]`

2.  **Install dependencies**: Follow the instructions for your Clarity development environment.

3.  **Deploy**: Use your preferred tool to deploy the contract to a Stacks testnet or mainnet.

* * * * *

💻 Usage Examples
-----------------

### 1\. Applying for a Loan

A user with an existing credit score of `u650` wants to apply for a loan. Their score is high enough to be approved.

Code snippet

```
(contract-call? 'SP123...my-contract apply-for-loan u1000 u1500 u90)

```

-   **amount**: `u1000` STX (or other token)

-   **collateral-amount**: `u1500` STX (150% collateral)

-   **duration**: `u90` blocks (approximately 90 days)

The contract will check the user's score, validate the loan parameters, and issue a loan with a personalized interest rate (in this case, `u8`).

### 2\. Making a Payment

The borrower wants to repay their loan with `id u1`.

Code snippet

```
(contract-call? 'SP123...my-contract make-payment u1 u1000)

```

-   **loan-id**: `u1`

-   **amount**: `u1000` (the full amount of the loan)

This call records the payment, marks the loan as paid, and updates the user's profile with a successful payment.

### 3\. Checking and Updating Your Score

A user can manually trigger a credit score update after multiple successful repayments.

Code snippet

```
(contract-call? 'SP123...my-contract calculate-and-update-credit-score tx-sender)

```

This function will return a detailed breakdown of the score calculation, providing full transparency into how the score was determined.

* * * * *

🙏 Contributing
---------------

Contributions are welcome! If you have suggestions for improvements, new features, or find a bug, please open an issue or submit a pull request.

* * * * *

📝 License
----------

This project is licensed under the [MIT License](https://www.google.com/search?q=https://github.com/mit-license.txt).

```
MIT License

Copyright (c) 2025 Ogunlana Oluwabunmi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```

![profile picture](https://lh3.googleusercontent.com/a/ACg8ocLyIOO_tYtBde9l4U0KcY5JT-3yKZzmRaJQgAl3BEbwOqhRMjYorQ=s64-c)
