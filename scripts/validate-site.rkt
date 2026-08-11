#lang racket/base

(require racket/file
         racket/list
         racket/path
         racket/runtime-path
         racket/string
         "../src/config/site.rkt")

(define-runtime-path default-public-directory "../public")

(define required-pages
  '("index.html"
    "writing/index.html"
    "poems/index.html"
    "work/index.html"
    "about/index.html"
    "work/poetry-reset.html"
    "tools/poetry-reset/index.html"))

(define required-deploy-assets
  '("tools/poetry-reset/manifest.webmanifest"
    "tools/poetry-reset/sw.js"
    "tools/poetry-reset/icon.svg"
    "tools/poetry-reset/site.css"
    "tools/poetry-reset/site.js"
    "tools/poetry-reset/poetry-reset.js"))

(define (html-file? path)
  (and (file-exists? path)
       (regexp-match? #px"[.]html$" (path->string path))))

(define (external-reference? reference)
  (or (string=? reference "")
      (regexp-match? #px"^(?:https?:|mailto:|tel:|data:|javascript:|#)" reference)))

(define (strip-query-and-fragment reference)
  (first (string-split reference #px"[?#]" #:trim? #f)))

(define (strip-site-base reference)
  (cond
    [(and (not (string=? site-base-path ""))
          (or (string=? reference site-base-path)
              (string-prefix? reference (string-append site-base-path "/"))))
     (substring reference (string-length site-base-path))]
    [else reference]))

(define (reference->target public-directory page reference)
  (define clean (strip-site-base (strip-query-and-fragment reference)))
  (define root-relative? (string-prefix? clean "/"))
  (define without-leading (string-trim clean "/" #:right? #f))
  (define target
    (cond
      [(and root-relative? (string=? without-leading "")) public-directory]
      [root-relative? (build-path public-directory without-leading)]
      [(string=? clean "") (path-only page)]
      [else (build-path (path-only page) clean)]))
  (define normalised (simplify-path target #f))
  (cond
    [(or (string-suffix? clean "/") (directory-exists? normalised))
     (build-path normalised "index.html")]
    [else normalised]))

(define (page-references html)
  (regexp-match* #px"(?:href|src)=\"([^\"]+)\"" html
                 #:match-select second))

(define (validate-site [public-directory default-public-directory])
  (unless (directory-exists? public-directory)
    (raise-user-error 'validate-site
                      "public directory does not exist: ~a"
                      public-directory))

  (define failures '())
  (define (fail! message) (set! failures (cons message failures)))

  (for ([required (in-list required-pages)])
    (unless (file-exists? (build-path public-directory required))
      (fail! (format "missing required page: ~a" required))))

  (for ([required (in-list required-deploy-assets)])
    (unless (file-exists? (build-path public-directory required))
      (fail! (format "missing required deploy asset: ~a" required))))

  (define homepage-path (build-path public-directory "index.html"))
  (when (file-exists? homepage-path)
    (define homepage (file->string homepage-path))
    (for ([required-theme-marker
           '("data-theme=\"dark\""
             "data-theme-toggle=\"true\""
             "data-theme-color"
             "mica-theme")])
      (unless (string-contains? homepage required-theme-marker)
        (fail! (format "index.html is missing theme marker: ~a"
                       required-theme-marker)))))

  (define pages (find-files html-file? public-directory))
  (for ([page (in-list pages)])
    (define relative (path->string (find-relative-path public-directory page)))
    (define html (file->string page))
    (unless (regexp-match? #px"(?i:<!doctype html>)" html)
      (fail! (format "~a has no HTML doctype" relative)))
    (unless (= 1 (length (regexp-match* #px"<h1(?:[ >])" html)))
      (fail! (format "~a must contain exactly one h1" relative)))
    (for ([forbidden '("#lang pollen" "<root" "htmlheadmeta")])
      (when (string-contains? html forbidden)
        (fail! (format "~a contains leaked build text: ~a" relative forbidden))))

    (for ([reference (in-list (page-references html))]
          #:unless (external-reference? reference))
      (define target (reference->target public-directory page reference))
      (unless (file-exists? target)
        (fail!
         (format "~a links to missing ~a"
                 relative
                 reference)))))

  (unless (file-exists? (build-path public-directory "feed.xml"))
    (fail! "missing feed.xml"))
  (unless (file-exists? (build-path public-directory "sitemap.xml"))
    (fail! "missing sitemap.xml"))

  (cond
    [(null? failures)
     (printf "Validated ~a HTML pages; internal links resolve.\n" (length pages))
     #t]
    [else
     (raise-user-error
      'validate-site
      (string-append "site validation failed:\n  - "
                     (string-join (reverse failures) "\n  - ")))]))

(module+ main
  (validate-site))

(provide validate-site
         reference->target
         strip-site-base)
