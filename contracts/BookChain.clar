;; BookChain: Community Library Resource System
;; Version: 1.0.0

(define-data-var library-coordinator principal tx-sender)
(define-data-var reading-credits uint u0)
(define-data-var engagement-score uint u82) ;; engagement points per assessment cycle
(define-data-var last-engagement-assessment uint u0) ;; last block when engagement was assessed

(define-map reader-activity-log principal uint)

;; Helper function to ensure only the library coordinator can perform certain actions
(define-private (is-library-coordinator (caller principal))
  (begin
    (asserts! (is-eq caller (var-get library-coordinator)) (err u800))
    (ok true)))

;; Initialize the library resource platform
(define-public (establish-library-network (coordinator principal))
  (begin
    (asserts! (is-none (map-get? reader-activity-log coordinator)) (err u801))
    (var-set library-coordinator coordinator)
    (ok "BookChain library network established")))

;; Record reading activity
(define-public (record-reading-activity (pages uint))
  (begin
    (asserts! (> pages u0) (err u802))
    (let ((current-activity (default-to u0 (map-get? reader-activity-log tx-sender))))
      (map-set reader-activity-log tx-sender (+ current-activity pages))
      (var-set reading-credits (+ (var-get reading-credits) pages))
      (ok (+ current-activity pages)))))

;; Assess engagement scores for all readers
(define-public (assess-community-engagement)
  (begin
    (try! (is-library-coordinator tx-sender))
    (let ((current-block stacks-block-height)
          (previous-assessment (var-get last-engagement-assessment)))
      (asserts! (> current-block previous-assessment) (err u803))
      ;; Calculate engagement based on blocks elapsed
      (let ((elapsed (- current-block previous-assessment))
            (total-engagement (* elapsed (var-get engagement-score))))
        (var-set last-engagement-assessment current-block)
        (var-set reading-credits (+ (var-get reading-credits) total-engagement))
        (ok total-engagement)))))

;; Distribute reading credits and claim engagement premiums
(define-public (distribute-engagement-premium)
  (begin
    (let ((reader-activity (default-to u0 (map-get? reader-activity-log tx-sender))))
      (asserts! (> reader-activity u0) (err u804))
      (let ((total-credits (var-get reading-credits))
            (new-engagement (* (var-get engagement-score) (- stacks-block-height (var-get last-engagement-assessment))))
            (activity-ratio (/ (* reader-activity u100000) total-credits)))
        ;; Calculate premium based on activity ratio
        (let ((premium-amount (/ (* activity-ratio new-engagement) u100000)))
          (map-delete reader-activity-log tx-sender)
          (var-set reading-credits (- (var-get reading-credits) reader-activity))
          (ok (+ reader-activity premium-amount)))))))

;; Read-only functions
(define-read-only (get-reader-activity-log (reader principal))
  (default-to u0 (map-get? reader-activity-log reader)))

(define-read-only (get-library-stats)
  {
    coordinator: (var-get library-coordinator),
    total-credits: (var-get reading-credits),
    engagement-score: (var-get engagement-score),
    last-assessment: (var-get last-engagement-assessment)
  })

(define-read-only (get-reading-credits)
  (var-get reading-credits))