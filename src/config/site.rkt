#lang racket/base

(require racket/date
         racket/list
         racket/string)

(provide site-name
         person-name
         writing-author
         site-description
         github-username
         repository-name
         github-profile-url
         site-origin
         site-base-path
         site-root-url
         nav-items
         current-year
         site-url
         canonical-url
         external-url?)

;; Keep the legal/person identity separate from the public pen name. Essays and
;; poems are credited to “Mica”; biographical and professional references use
;; Michael Khalil.
(define person-name "Michael Khalil")
(define writing-author "Mica")
(define site-name writing-author)
(define site-description
  "Software and experiments by Michael Khalil; essays and poems by Mica.")
(define github-username "lordofblackwood")
(define repository-name "mica-site")
(define github-profile-url
  (format "https://github.com/~a" github-username))

(define (normalise-origin value)
  (string-trim (or value "https://lordofblackwood.github.io") "/" #:left? #f))

(define (normalise-base-path value)
  (define trimmed (string-trim (or value "")))
  (cond
    [(or (string=? trimmed "") (string=? trimmed "/")) ""]
    [else (string-append "/" (string-trim trimmed "/"))]))

;; Local builds default to the domain root. GitHub Actions sets
;; SITE_BASE_PATH=/mica-site for this repository's project-site deployment.
(define site-origin (normalise-origin (getenv "SITE_ORIGIN")))
(define site-base-path (normalise-base-path (getenv "SITE_BASE_PATH")))
(define site-root-url
  (string-append site-origin site-base-path "/"))

;; label, path, section key
(define nav-items
  '(("Writing" "writing/" "writing")
    ("Poems" "poems/" "poems")
    ("Work" "work/" "work")
    ("About" "about/" "about")))

(define current-year (date-year (seconds->date (current-seconds))))

(define (external-url? value)
  (and (string? value)
       (regexp-match? #px"^(?:https?:|mailto:|tel:|#)" value)))

(define (site-url [path ""])
  (cond
    [(external-url? path) path]
    [else
     (define trailing-slash? (and (string? path) (string-suffix? path "/")))
     (define clean (string-trim (or path "") "/"))
     (cond
       [(string=? clean "") (string-append site-base-path "/")]
       [else
        (string-append site-base-path "/" clean
                       (if trailing-slash? "/" ""))])]))

(define (canonical-url [path ""])
  (cond
    [(and (string? path) (regexp-match? #px"^https?://" path)) path]
    [else
     (define trailing-slash?
       (and (string? path) (string-suffix? path "/")))
     (define clean (string-trim (or path "") "/"))
     (define canonical-path
       (cond
         [(string=? clean "index.html") ""]
         [(regexp-match #px"^(.*)/index[.]html$" clean)
          => (lambda (match) (string-append (second match) "/"))]
         [trailing-slash? (string-append clean "/")]
         [else clean]))
     (string-append site-origin (site-url canonical-path))]))
