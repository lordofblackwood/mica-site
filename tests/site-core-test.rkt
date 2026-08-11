#lang racket/base

(require rackunit
         racket/list
         racket/string
         (only-in "../build.rkt" verified-literary-provenance?)
         "../scripts/new-content.rkt"
         "../src/config/site.rkt"
         "../src/pollen.rkt")

(test-case "slugify produces stable filenames"
  (check-equal? (slugify "A Small, Useful Tool")
                "a-small-useful-tool")
  (check-equal? (slugify "  C# + Racket?! ") "c-racket"))

(test-case "fiction scaffolds as Mica writing"
  (define-values (directory section kind) (content-spec "fiction"))
  (check-equal? directory "writing")
  (check-equal? section "writing")
  (check-equal? kind "fiction")
  (define template (page-template "Small Story" section kind))
  (check-true (string-contains? template "◊define-meta[kind]{fiction}"))
  (check-true
   (string-contains? template
                     (format "◊define-meta[author]{~a}" writing-author)))
  (check-true
   (string-contains? template "◊define-meta[provenance]{unverified}")))

(test-case "only verified user-authored literary work may publish"
  (check-false
   (verified-literary-provenance?
    (hash 'provenance "unverified")))
  (check-true
   (verified-literary-provenance?
    (hash 'provenance "verified-user-authored"))))

(test-case "site URLs preserve external links and prefix internal links"
  (check-equal? (site-url "https://example.com") "https://example.com")
  (check-true (string-suffix? (site-url "writing/") "/writing/"))
  (check-true (string-suffix? (canonical-url "writing/") "/writing/"))
  (check-true (string-suffix? (canonical-url "writing/index.html")
                              "/writing/")))

(test-case "poem lines drop parser whitespace and surrounding quotes"
  (check-equal? (normalise-poem-line "  \"A line.\"\n") "A line.")
  (check-equal? (normalise-poem-line " blank ") 'blank)
  (check-false (normalise-poem-line " \n ")))

(test-case "theme control is a real accessible button"
  (define control (theme-toggle))
  (check-equal? (first control) 'button)
  (check-not-false (member '(type "button") (second control)))
  (check-not-false (member '(data-theme-toggle "true") (second control)))
  (check-not-false (member '(aria-label "Switch to light mode")
                           (second control))))

(test-case "Poetry Reset is the first featured Work project"
  (define poetry-reset
    (findf (lambda (item)
             (string=? (content-item-title item) "Poetry Reset"))
           (discover-content "work")))
  (check-pred content-item? poetry-reset)
  (when poetry-reset
    (check-equal? (content-item-kind poetry-reset) "project")
    (check-not-false (content-item-featured poetry-reset))
    (check-equal? (content-item-featured-order poetry-reset) 0)))

(test-case "content discovery preserves collection invariants"
  (define writing (discover-content "writing"))
  (define poems (discover-content "poems"))
  (define work (discover-content "work"))
  (check-true (>= (length work) 6))
  (check-true
   (andmap (lambda (item)
             (and (member (content-item-kind item) '("essay" "fiction")) #t))
           writing))
  (check-true
   (andmap (lambda (item)
             (string=? (content-item-author item) writing-author))
           (append writing poems)))
  (check-true
   (andmap (lambda (item)
             (string=? (content-item-author item) person-name))
           work)))
