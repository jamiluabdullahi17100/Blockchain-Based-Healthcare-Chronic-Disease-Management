;; Provider Verification Contract
;; Validates healthcare entities and manages their credentials

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROVIDER_EXISTS (err u101))
(define-constant ERR_PROVIDER_NOT_FOUND (err u102))
(define-constant ERR_INVALID_LICENSE (err u103))

;; Data Variables
(define-data-var next-provider-id uint u1)

;; Data Maps
(define-map providers
  { provider-id: uint }
  {
    wallet-address: principal,
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    specialty: (string-ascii 50),
    verified: bool,
    registration-date: uint
  }
)

(define-map provider-by-address
  { wallet-address: principal }
  { provider-id: uint }
)

;; Public Functions

;; Register a new healthcare provider
(define-public (register-provider (name (string-ascii 100)) (license-number (string-ascii 50)) (specialty (string-ascii 50)))
  (let
    (
      (provider-id (var-get next-provider-id))
      (caller tx-sender)
    )
    ;; Check if provider already exists
    (asserts! (is-none (map-get? provider-by-address { wallet-address: caller })) ERR_PROVIDER_EXISTS)

    ;; Validate license number (basic check - not empty)
    (asserts! (> (len license-number) u0) ERR_INVALID_LICENSE)

    ;; Store provider data
    (map-set providers
      { provider-id: provider-id }
      {
        wallet-address: caller,
        name: name,
        license-number: license-number,
        specialty: specialty,
        verified: false,
        registration-date: block-height
      }
    )

    ;; Create address mapping
    (map-set provider-by-address
      { wallet-address: caller }
      { provider-id: provider-id }
    )

    ;; Increment next provider ID
    (var-set next-provider-id (+ provider-id u1))

    (ok provider-id)
  )
)

;; Verify a provider (only contract owner)
(define-public (verify-provider (provider-id uint))
  (begin
    ;; Only contract owner can verify
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    ;; Check if provider exists
    (match (map-get? providers { provider-id: provider-id })
      provider-data
      (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data { verified: true })
        )
        (ok true)
      )
      ERR_PROVIDER_NOT_FOUND
    )
  )
)

;; Read-only Functions

;; Get provider by ID
(define-read-only (get-provider (provider-id uint))
  (map-get? providers { provider-id: provider-id })
)

;; Get provider ID by address
(define-read-only (get-provider-by-address (wallet-address principal))
  (map-get? provider-by-address { wallet-address: wallet-address })
)

;; Check if provider is verified
(define-read-only (is-provider-verified (provider-id uint))
  (match (map-get? providers { provider-id: provider-id })
    provider-data
    (get verified provider-data)
    false
  )
)

;; Get next provider ID
(define-read-only (get-next-provider-id)
  (var-get next-provider-id)
)
