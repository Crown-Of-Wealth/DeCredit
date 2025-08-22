;; Personalized Credit Scoring for DeFi Loans
;; A smart contract that maintains credit scores for users based on their borrowing history,
;; collateral ratios, payment behavior, and other risk factors to enable personalized
;; interest rates and loan terms in decentralized finance protocols.

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-SCORE (err u102))
(define-constant ERR-LOAN-NOT-FOUND (err u103))
(define-constant ERR-ALREADY-PAID (err u104))
(define-constant ERR-INVALID-PARAMETER (err u105))

;; Scoring parameters
(define-constant MIN-CREDIT-SCORE u300)
(define-constant MAX-CREDIT-SCORE u850)
(define-constant DEFAULT-SCORE u500)
(define-constant SCORE-IMPROVEMENT-FACTOR u10)
(define-constant SCORE-PENALTY-FACTOR u25)

;; Data maps and vars
;; User credit profiles storing comprehensive credit information
(define-map user-profiles
  principal
  {
    credit-score: uint,
    total-loans: uint,
    successful-payments: uint,
    missed-payments: uint,
    total-borrowed: uint,
    total-repaid: uint,
    average-collateral-ratio: uint,
    last-updated: uint
  }
)

;; Active loans with detailed tracking
(define-map active-loans
  uint
  {
    borrower: principal,
    amount: uint,
    collateral-amount: uint,
    interest-rate: uint,
    due-date: uint,
    is-paid: bool,
    created-at: uint
  }
)

;; Payment history for behavioral analysis
(define-map payment-history
  { user: principal, loan-id: uint }
  {
    paid-amount: uint,
    payment-date: uint,
    was-on-time: bool
  }
)

(define-data-var next-loan-id uint u1)
(define-data-var total-users uint u0)

;; Private functions
;; Calculate base score from payment history and loan performance
(define-private (calculate-base-score (profile (tuple (credit-score uint) (total-loans uint) (successful-payments uint) (missed-payments uint) (total-borrowed uint) (total-repaid uint) (average-collateral-ratio uint) (last-updated uint))))
  (let (
    (payment-ratio (if (> (get total-loans profile) u0)
                     (/ (* (get successful-payments profile) u100) (get total-loans profile))
                     u50))
    (repayment-ratio (if (> (get total-borrowed profile) u0)
                       (/ (* (get total-repaid profile) u100) (get total-borrowed profile))
                       u50))
    (penalty-score (* (get missed-payments profile) SCORE-PENALTY-FACTOR))
  )
    (+ (+ (* payment-ratio u3) (* repayment-ratio u2)) 
       (/ (get average-collateral-ratio profile) u10)
       (- u0 penalty-score))
  )
)

;; Validate loan parameters for security
(define-private (validate-loan-params (amount uint) (collateral uint) (duration uint))
  (and (> amount u0)
       (> collateral u0)
       (>= collateral (/ (* amount u120) u100)) ;; Min 120% collateral
       (and (>= duration u1) (<= duration u365)) ;; 1-365 days
  )
)

;; Update user profile after loan activity
(define-private (update-user-stats (user principal) (amount uint) (collateral uint))
  (let (
    (current-profile (default-to 
      { credit-score: DEFAULT-SCORE, total-loans: u0, successful-payments: u0, 
        missed-payments: u0, total-borrowed: u0, total-repaid: u0, 
        average-collateral-ratio: u150, last-updated: block-height }
      (map-get? user-profiles user)))
    (new-total-loans (+ (get total-loans current-profile) u1))
    (new-total-borrowed (+ (get total-borrowed current-profile) amount))
    (collateral-ratio (/ (* collateral u100) amount))
    (new-avg-collateral (/ (+ (* (get average-collateral-ratio current-profile) 
                               (get total-loans current-profile)) collateral-ratio) 
                            new-total-loans))
  )
    (map-set user-profiles user
      (merge current-profile {
        total-loans: new-total-loans,
        total-borrowed: new-total-borrowed,
        average-collateral-ratio: new-avg-collateral,
        last-updated: block-height
      })
    )
  )
)

;; Public functions
;; Initialize or retrieve user credit profile
(define-public (get-or-create-profile (user principal))
  (match (map-get? user-profiles user)
    profile (ok profile)
    (begin
      (map-set user-profiles user {
        credit-score: DEFAULT-SCORE,
        total-loans: u0,
        successful-payments: u0,
        missed-payments: u0,
        total-borrowed: u0,
        total-repaid: u0,
        average-collateral-ratio: u150,
        last-updated: block-height
      })
      (var-set total-users (+ (var-get total-users) u1))
      (ok (unwrap! (map-get? user-profiles user) (err u999)))
    )
  )
)

;; Apply for a loan with credit score validation
(define-public (apply-for-loan (amount uint) (collateral-amount uint) (duration uint))
  (let (
    (loan-id (var-get next-loan-id))
    (profile-result (get-or-create-profile tx-sender))
    (current-score (get credit-score (try! profile-result)))
    (interest-rate (if (>= current-score u700) u5
                   (if (>= current-score u600) u8
                   (if (>= current-score u500) u12 u18))))
  )
    (asserts! (validate-loan-params amount collateral-amount duration) ERR-INVALID-PARAMETER)
    (asserts! (>= current-score MIN-CREDIT-SCORE) ERR-INSUFFICIENT-SCORE)
    
    (map-set active-loans loan-id {
      borrower: tx-sender,
      amount: amount,
      collateral-amount: collateral-amount,
      interest-rate: interest-rate,
      due-date: (+ block-height duration),
      is-paid: false,
      created-at: block-height
    })
    
    (update-user-stats tx-sender amount collateral-amount)
    (var-set next-loan-id (+ loan-id u1))
    (ok { loan-id: loan-id, interest-rate: interest-rate })
  )
)

;; Make payment on a loan
(define-public (make-payment (loan-id uint) (amount uint))
  (let (
    (loan (unwrap! (map-get? active-loans loan-id) ERR-LOAN-NOT-FOUND))
    (is-on-time (<= block-height (get due-date loan)))
    (profile (unwrap! (map-get? user-profiles (get borrower loan)) ERR-LOAN-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender (get borrower loan)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-paid loan)) ERR-ALREADY-PAID)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    
    ;; Record payment
    (map-set payment-history { user: tx-sender, loan-id: loan-id } {
      paid-amount: amount,
      payment-date: block-height,
      was-on-time: is-on-time
    })
    
    ;; Mark loan as paid if full amount
    (if (>= amount (get amount loan))
      (begin
        (map-set active-loans loan-id (merge loan { is-paid: true }))
        ;; Update profile with successful payment
        (map-set user-profiles tx-sender
          (merge profile {
            successful-payments: (+ (get successful-payments profile) u1),
            total-repaid: (+ (get total-repaid profile) amount),
            last-updated: block-height
          }))
      )
      true
    )
    
    (ok true)
  )
)

;; Comprehensive credit score calculation and update system
;; This function performs a holistic analysis of user behavior and updates their credit score
;; based on multiple risk factors including payment history, collateral management, and loan performance
(define-public (calculate-and-update-credit-score (user principal))
  (let (
    (profile (unwrap! (map-get? user-profiles user) ERR-LOAN-NOT-FOUND))
    (base-score (calculate-base-score profile))
    (total-loans (get total-loans profile))
    (successful-ratio (if (> total-loans u0) 
                        (/ (* (get successful-payments profile) u100) total-loans) u0))
    (missed-ratio (if (> total-loans u0) 
                    (/ (* (get missed-payments profile) u100) total-loans) u0))
    
    ;; Advanced scoring factors
    (payment-consistency-bonus (if (>= successful-ratio u90) u50 u0))
    (high-volume-bonus (if (> total-loans u10) u25 u0))
    (collateral-management-score (get average-collateral-ratio profile))
    (collateral-bonus (if (>= collateral-management-score u200) u30 
                      (if (>= collateral-management-score u150) u15 u0)))
    
    ;; Risk penalties
    (missed-payment-penalty (* missed-ratio u2))
    (low-collateral-penalty (if (< collateral-management-score u130) u40 u0))
    (recent-activity-bonus (if (> (- block-height (get last-updated profile)) u100) u0 u10))
    
    ;; Calculate final score with bounds checking
    (raw-score (+ base-score payment-consistency-bonus high-volume-bonus 
                  collateral-bonus recent-activity-bonus 
                  (- u0 missed-payment-penalty) (- u0 low-collateral-penalty)))
    (bounded-score (if (> raw-score MAX-CREDIT-SCORE) MAX-CREDIT-SCORE
                   (if (< raw-score MIN-CREDIT-SCORE) MIN-CREDIT-SCORE raw-score)))
  )
    ;; Update the user's credit score and profile
    (map-set user-profiles user
      (merge profile {
        credit-score: bounded-score,
        last-updated: block-height
      }))
    
    ;; Return comprehensive score breakdown for transparency
    (ok {
      new-score: bounded-score,
      previous-score: (get credit-score profile),
      payment-ratio: successful-ratio,
      missed-ratio: missed-ratio,
      collateral-ratio: collateral-management-score,
      total-loans: total-loans,
      score-factors: {
        base: base-score,
        consistency-bonus: payment-consistency-bonus,
        volume-bonus: high-volume-bonus,
        collateral-bonus: collateral-bonus,
        activity-bonus: recent-activity-bonus,
        missed-penalty: missed-payment-penalty,
        collateral-penalty: low-collateral-penalty
      }
    })
  )
)
