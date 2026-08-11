#lang racket

(require pollen/core
         pollen/render
         pollen/setup
         racket/file
         racket/list
         racket/match
         racket/path
         racket/runtime-path
         racket/string
         (only-in "scripts/sync-github.rkt"
                  read-github-snapshot
                  read-project-overrides
                  refresh-github-snapshot!)
         "src/config/site.rkt"
         "src/pollen.rkt")

(define-runtime-path repository-root ".")
(define source-directory (simplify-path (build-path repository-root "src") #t))
(define public-directory (simplify-path (build-path repository-root "public") #t))

(define (html-markup-source? path)
  (and (file-exists? path)
       (regexp-match? #px"[.]html[.]pm$" (path->string path))))

(define (source-output-path source)
  (string->path
   (regexp-replace #px"[.]pm$" (path->string source) "")))

(define (draft-source? source)
  (truthy? (hash-ref (get-metas source) 'draft #f)))

(define required-content-metadata
  '(title description section kind date tags draft featured))

(define section-kinds
  (hash "writing" '("essay" "fiction")
        "poems" '("poem")
        "work" '("project")))

(define literary-kinds '("essay" "fiction" "poem"))
(define verified-user-provenance "verified-user-authored")

(define (verified-literary-provenance? metas)
  (and (hash-has-key? metas 'provenance)
       (string=? (meta-ref metas 'provenance)
                 verified-user-provenance)))

(define (valid-boolean-metadata? value)
  (member (string-downcase (value->string value)) '("true" "false")))

(define (leap-year? year)
  (or (zero? (modulo year 400))
      (and (zero? (modulo year 4))
           (not (zero? (modulo year 100))))))

(define (valid-iso-date? value)
  (match (regexp-match #px"^(\\d{4})-(\\d{2})-(\\d{2})$"
                       (value->string value))
    [(list _ year-text month-text day-text)
     (define year (string->number year-text))
     (define month (string->number month-text))
     (define day (string->number day-text))
     (define days-per-month
       (vector 31 (if (leap-year? year) 29 28) 31 30 31 30
               31 31 30 31 30 31))
     (and (<= 1 month 12)
          (<= 1 day (vector-ref days-per-month (sub1 month))))]
    [_ #f]))

(define (validate-content-sources! sources)
  (define failures '())
  (define (fail! source message)
    (set! failures
          (cons (format "~a: ~a"
                        (path->string
                         (find-relative-path repository-root source))
                        message)
                failures)))
  (for ([source (in-list sources)]
        #:when (content-source? source))
    (define metas (get-metas source))
    (for ([key (in-list required-content-metadata)])
      (unless (hash-has-key? metas key)
        (fail! source (format "missing required metadata ‘~a’" key))))
    (for ([key (in-list '(title description section kind date))])
      (when (and (hash-has-key? metas key)
                 (string=? (string-trim (meta-ref metas key)) ""))
        (fail! source (format "metadata ‘~a’ cannot be empty" key))))
    (define section (meta-ref metas 'section))
    (define kind (meta-ref metas 'kind))
    (cond
      [(not (hash-has-key? section-kinds section))
       (fail! source "section must be writing, poems, or work")]
      [(not (member kind (hash-ref section-kinds section)))
       (fail! source
              (format "kind ‘~a’ does not match section ‘~a’" kind section))])
    (when (member kind literary-kinds)
      (cond
        [(not (hash-has-key? metas 'author))
         (fail! source "essays, fiction, and poems require author metadata")]
        [(not (string=? (meta-ref metas 'author) writing-author))
         (fail! source
                (format "author must be ‘~a’ for essays, fiction, and poems"
                        writing-author))])
      (unless (truthy? (hash-ref metas 'draft #f))
        (unless (verified-literary-provenance? metas)
          (fail! source
                 (format "published literary provenance must be ‘~a’"
                         verified-user-provenance)))))
    (when (and (hash-has-key? metas 'date)
               (not (valid-iso-date? (hash-ref metas 'date))))
      (fail! source "date must be a real calendar date in YYYY-MM-DD form"))
    (for ([key (in-list '(draft featured))])
      (when (and (hash-has-key? metas key)
                 (not (valid-boolean-metadata? (hash-ref metas key))))
        (fail! source (format "metadata ‘~a’ must be true or false" key))))
    (when (and (hash-has-key? metas 'featured-order)
               (not (exact-nonnegative-integer?
                     (string->number (meta-ref metas 'featured-order)))))
      (fail! source "featured-order must be a non-negative integer")))
  (unless (null? failures)
    (raise-user-error
     'build-site
     (string-append "invalid content metadata:\n  - "
                    (string-join (reverse failures) "\n  - ")))))

(define (copy-file-under-root! file from-root to-root)
  (define relative (find-relative-path from-root file))
  (define destination (build-path to-root relative))
  (make-parent-directory* destination)
  (copy-file file destination #t))

(define (xml-escape value)
  (for/fold ([escaped (format "~a" value)])
            ([pair (in-list '(("&" . "&amp;")
                              ("<" . "&lt;")
                              (">" . "&gt;")
                              ("\"" . "&quot;")
                              ("'" . "&apos;")))])
    (string-replace escaped (car pair) (cdr pair))))

(define (output-path->site-path output)
  (define relative (path->string (find-relative-path source-directory output)))
  (cond
    [(string=? relative "index.html") ""]
    [(regexp-match #px"^(.*)/index[.]html$" relative)
     => (lambda (match) (string-append (second match) "/"))]
    [else relative]))

(define (write-sitemap! sources)
  (define urls
    (for/list ([source (in-list sources)])
      (canonical-url (output-path->site-path (source-output-path source)))))
  (call-with-output-file (build-path public-directory "sitemap.xml")
    #:exists 'replace
    (lambda (output)
      (display "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" output)
      (display "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n" output)
      (for ([url (in-list urls)])
        (fprintf output "  <url><loc>~a</loc></url>\n" (xml-escape url)))
      (display "</urlset>\n" output))))

(define (write-feed!)
  (define all-feed-items
    (sort (append (discover-content "writing")
                  (discover-content "poems"))
          content-before?))
  (define feed-items
    (take all-feed-items (min 20 (length all-feed-items))))
  (call-with-output-file (build-path public-directory "feed.xml")
    #:exists 'replace
    (lambda (output)
      (display "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" output)
      (display "<rss version=\"2.0\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\"><channel>\n" output)
      (fprintf output "  <title>~a — Writing and poems</title>\n"
               (xml-escape site-name))
      (fprintf output "  <link>~a</link>\n" (xml-escape site-root-url))
      (fprintf output "  <description>~a</description>\n" (xml-escape site-description))
      (for ([item (in-list feed-items)])
        (define relative-path
          (source->relative-output (content-item-source item)))
        (define url (canonical-url relative-path))
        (display "  <item>\n" output)
        (fprintf output "    <title>~a</title>\n" (xml-escape (content-item-title item)))
        (fprintf output "    <link>~a</link>\n" (xml-escape url))
        (fprintf output "    <guid>~a</guid>\n" (xml-escape url))
        (fprintf output "    <description>~a</description>\n"
                 (xml-escape (content-item-description item)))
        (fprintf output "    <dc:creator>~a</dc:creator>\n"
                 (xml-escape (content-item-author item)))
        (display "  </item>\n" output))
      (display "</channel></rss>\n" output))))

;; Keep stable collection and project links working after the site restructure.
(define compatibility-redirects
  '(("about.html" . "about/")
    ("art.html" . "work/creative-practice.html")
    ("now.html" . "now/")
    ("resume.html" . "resume/")
    ("blog.html" . "writing/")
    ("poetry.html" . "poems/")
    ("projects.html" . "work/")
    ("projects/acts-of-andrew.html" . "work/acts-of-andrew.html")
    ("projects/ich-ml.html" . "work/ich-ml.html")
    ("projects/nba-analytics.html" . "work/nba-analytics.html")
    ("projects/racket-personal-site.html" . "work/racket-personal-site.html")
    ("projects/sql-parser.html" . "work/sql-parser.html")
    ("art/skyline-stars.html" . "work/skyline-stars.html")))

(define (write-compatibility-redirects!)
  (for ([(legacy-path destination) (in-dict compatibility-redirects)])
    (define output-path (build-path public-directory legacy-path))
    (define destination-url (site-url destination))
    (make-parent-directory* output-path)
    (call-with-output-file output-path
      #:exists 'replace
      (lambda (output)
        (fprintf output "<!doctype html>\n<html lang=\"en\">\n<head>\n")
        (display "  <meta charset=\"utf-8\">\n" output)
        (display "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n" output)
        (display "  <meta name=\"robots\" content=\"noindex\">\n" output)
        (fprintf output "  <meta http-equiv=\"refresh\" content=\"0; url=~a\">\n"
                 (xml-escape destination-url))
        (fprintf output "  <link rel=\"canonical\" href=\"~a\">\n"
                 (xml-escape (canonical-url destination)))
        (fprintf output "  <link rel=\"stylesheet\" href=\"~a\">\n"
                 (xml-escape (site-url "static/css/site.css")))
        (fprintf output "  <title>Page moved · ~a</title>\n</head>\n<body>\n"
                 (xml-escape site-name))
        (display "  <main class=\"site-main page-content\">\n" output)
        (display "    <h1>This page moved.</h1>\n" output)
        (fprintf output "    <p><a href=\"~a\">Continue to the new page</a>.</p>\n"
                 (xml-escape destination-url))
        (display "  </main>\n</body>\n</html>\n" output)))))

(define (maybe-refresh-github!)
  (when (string-ci=? (or (getenv "GITHUB_SYNC_MODE") "offline") "refresh")
    (displayln "Refreshing GitHub project snapshot …")
    (refresh-github-snapshot!)))

(define (validate-configuration-and-data!)
  (when (string=? (string-trim site-name) "")
    (raise-user-error 'build-site "site-name cannot be empty"))
  (when (string=? (string-trim github-username) "")
    (raise-user-error 'build-site "github-username cannot be empty"))
  (unless (regexp-match? #px"^https://" site-origin)
    (raise-user-error 'build-site "SITE_ORIGIN must be an https URL"))
  ;; These readers validate schema and override shape even during an offline
  ;; build, so malformed cached data cannot silently empty the Work page.
  (read-github-snapshot)
  (read-project-overrides))

(define (clear-pollen-caches!)
  (define compiled-directories
    (for/list ([path (in-directory source-directory)]
               #:when (and (directory-exists? path)
                           (equal? (file-name-from-path path)
                                   (string->path "compiled"))))
      path))
  (for ([directory (in-list compiled-directories)])
    (delete-directory/files directory)))

(define (build-site!)
  (maybe-refresh-github!)
  (validate-configuration-and-data!)
  (clear-pollen-caches!)

  (when (directory-exists? public-directory)
    (delete-directory/files public-directory))
  (make-directory* public-directory)

  (parameterize ([current-directory source-directory]
                 [current-project-root source-directory])
    (define all-sources
      (sort (find-files html-markup-source? source-directory)
            path<?))
    (validate-content-sources! all-sources)
    (define publishable-sources
      (filter-not draft-source? all-sources))

    ;; Remove only outputs derived from known Pollen sources, avoiding stale
    ;; articles without treating hand-authored assets as generated files.
    (for ([source (in-list all-sources)])
      (define output (source-output-path source))
      (when (file-exists? output) (delete-file output)))

    (for ([source (in-list publishable-sources)])
      (render-to-file source))

    (for ([source (in-list publishable-sources)])
      (copy-file-under-root! (source-output-path source)
                             source-directory
                             public-directory))

    (define static-directory (build-path source-directory "static"))
    (when (directory-exists? static-directory)
      (copy-directory/files static-directory
                            (build-path public-directory "static")))

    ;; Files under src/public are already deployable and keep their paths at
    ;; the public root. This is useful for scoped assets such as manifests and
    ;; service workers that must live beside the page they control.
    (define passthrough-directory (build-path source-directory "public"))
    (when (directory-exists? passthrough-directory)
      (for ([file (in-directory passthrough-directory)]
            #:when (file-exists? file))
        (copy-file-under-root! file
                               passthrough-directory
                               public-directory)))

    ;; Keep the installable Poetry Reset shell entirely inside its worker scope,
    ;; so offline startup never depends on out-of-scope subresources and the
    ;; source CSS/JS still has a single maintained copy.
    (define poetry-reset-shell-directory
      (build-path public-directory "tools" "poetry-reset"))
    (make-directory* poetry-reset-shell-directory)
    (for ([copy-spec
           (in-list
            (list
             (cons (build-path static-directory "css" "site.css")
                   (build-path poetry-reset-shell-directory "site.css"))
             (cons (build-path static-directory "js" "site.js")
                   (build-path poetry-reset-shell-directory "site.js"))
             (cons (build-path static-directory "js" "poetry-reset.js")
                   (build-path poetry-reset-shell-directory "poetry-reset.js"))))])
      (copy-file (car copy-spec) (cdr copy-spec) #t))

    (write-sitemap! publishable-sources)
    (write-feed!)
    (write-compatibility-redirects!)

    (define validate-site
      (dynamic-require (build-path repository-root "scripts" "validate-site.rkt")
                       'validate-site))
    (validate-site public-directory)

    ;; Pollen renders beside its source files. Once the deployable copies are
    ;; validated, remove those derived files and caches so authoring stays clean.
    (for ([source (in-list all-sources)])
      (define output (source-output-path source))
      (when (file-exists? output) (delete-file output)))
    (clear-pollen-caches!)

    (printf "Built ~a pages into ~a\n"
            (length publishable-sources)
            (path->string public-directory))))

(module+ main
  (build-site!))

(provide build-site! verified-literary-provenance?)
