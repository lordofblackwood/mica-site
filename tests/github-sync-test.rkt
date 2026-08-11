#lang racket/base

(require json
         rackunit
         racket/file
         racket/list
         racket/runtime-path
         "../scripts/sync-github.rkt")

(define (repo name
              #:owner [owner github-username]
              #:fork [fork #f]
              #:archived [archived #f]
              #:disabled [disabled #f]
              #:private [private #f]
              #:has-pages [has-pages #f]
              #:topics [topics '()]
              #:homepage [homepage ""]
              #:updated [updated "2026-01-01T00:00:00Z"])
  (hash 'name name
        'owner (hash 'login owner)
        'fork fork
        'archived archived
        'disabled disabled
        'private private
        'has_pages has-pages
        'topics topics
        'homepage homepage
        'description (string-append name " description")
        'html_url (string-append "https://github.com/lordofblackwood/" name)
        'language "Racket"
        'stargazers_count 3
        'forks_count 1
        'updated_at updated))

(test-case "normalization derives Pages and preferred URLs"
  (define project
    (normalize-repository
     (repo "poem-machine"
           #:has-pages #t
           #:homepage "https://poems.example")))
  (check-equal? (hash-ref project 'pages_url)
                "https://lordofblackwood.github.io/poem-machine/")
  (check-equal? (hash-ref project 'url) "https://poems.example")
  (check-equal? (hash-ref project 'stars) 3)
  (check-false (hash-has-key? project 'archived))
  (check-equal?
   (derive-pages-url (repo "lordofblackwood.github.io" #:has-pages #t))
   "https://lordofblackwood.github.io/"))

(test-case "ineligible repository states and hidden topic are filtered"
  (define candidates
    (list (repo "visible")
          (repo "fork" #:fork #t)
          (repo "archive" #:archived #t)
          (repo "disabled" #:disabled #t)
          (repo "private" #:private #t)
          (repo "foreign" #:owner "someone-else")
          (repo "mica-site")
          (repo "secret" #:topics '("art" "PORTFOLIO-HIDDEN"))))
  (check-equal?
   (map (lambda (project) (hash-ref project 'name))
        (prepare-projects candidates))
   '("visible")))

(test-case "local overrides win, can change the primary link, and can hide"
  (define projects
    (prepare-projects
     (list (repo "alpha" #:has-pages #t)
           (repo "omit-me"))
     (hash 'schema_version 1
           'projects
           (hash 'alpha
                 (hash 'title "A better title"
                       'description "Hand-written copy"
                       'homepage "https://custom.example")
                 'omit-me (hash 'hidden #t)))))
  (check-equal? (length projects) 1)
  (define alpha (first projects))
  (check-equal? (hash-ref alpha 'title) "A better title")
  (check-equal? (hash-ref alpha 'description) "Hand-written copy")
  (check-equal? (hash-ref alpha 'url) "https://custom.example"))

(test-case "projects sort featured, then Pages, then recently updated"
  (define projects
    (prepare-projects
     (list (repo "plain-new" #:updated "2026-04-01T00:00:00Z")
           (repo "page-old" #:has-pages #t #:updated "2024-01-01T00:00:00Z")
           (repo "featured-no-page" #:updated "2023-01-01T00:00:00Z")
           (repo "page-new" #:has-pages #t #:updated "2026-02-01T00:00:00Z"))
     (hash 'projects
           (hash 'featured-no-page (hash 'featured #t)))))
  (check-equal?
   (map (lambda (project) (hash-ref project 'name)) projects)
   '("featured-no-page" "page-new" "page-old" "plain-new")))

(test-case "fetch follows pagination until a short page"
  (define calls '())
  (define (request-page _username _token page per-page)
    (set! calls (cons (list page per-page) calls))
    (case page
      [(1) (build-list per-page (lambda (index) (repo (format "repo-~a" index))))]
      [(2) (list (repo "last"))]
      [else (error 'request-page "unexpected page")]))
  (define fetched
    (fetch-public-repositories #:per-page 3 #:request-page request-page))
  (check-equal? (length fetched) 4)
  (check-equal? (reverse calls) '((1 3) (2 3))))

(test-case "atomic JSON replacement produces a readable snapshot"
  (define directory (make-temporary-file "github-sync-atomic-~a" 'directory))
  (dynamic-wind
    void
    (lambda ()
      (define path (build-path directory "nested" "snapshot.json"))
      (define snapshot
        (make-github-snapshot '() #:generated-at "2026-01-01T00:00:00Z"))
      (write-json-atomically! snapshot path)
      (check-equal? (read-github-snapshot path) snapshot)
      (check-equal? (directory-list (build-path directory "nested"))
                    (list (string->path "snapshot.json"))))
    (lambda () (delete-directory/files directory))))

(test-case "refresh writes transformed data and fetch failure uses cache unchanged"
  (define directory (make-temporary-file "github-sync-refresh-~a" 'directory))
  (dynamic-wind
    void
    (lambda ()
      (define snapshot-path (build-path directory "snapshot.json"))
      (define overrides-path (build-path directory "overrides.json"))
      (write-json-atomically!
       (hash 'schema_version 1
             'projects (hash 'alpha (hash 'featured #t 'title "Alpha!")))
       overrides-path)
      (define fresh
        (refresh-github-snapshot!
         #:snapshot-path snapshot-path
         #:overrides-path overrides-path
         #:fetch (lambda (_username _token)
                   (list (repo "alpha") (repo "mica-site")))))
      (check-equal? (length (hash-ref fresh 'projects)) 1)
      (check-equal? (hash-ref (first (hash-ref fresh 'projects)) 'title)
                    "Alpha!")
      (define bytes-before (file->bytes snapshot-path))
      (define warning #f)
      (define cached
        (refresh-github-snapshot!
         #:snapshot-path snapshot-path
         #:overrides-path overrides-path
         #:on-warning (lambda (message) (set! warning message))
         #:fetch (lambda (_username _token)
                   (error 'offline "network unavailable"))))
      (check-equal? cached fresh)
      (check-equal? (file->bytes snapshot-path) bytes-before)
      (check-regexp-match #rx"using cached snapshot" warning))
    (lambda () (delete-directory/files directory))))

(test-case "strict refresh propagates fetch failures"
  (define missing-path
    (build-path (find-system-path 'temp-dir)
                "github-sync-deliberately-missing"
                "snapshot.json"))
  (check-exn
   #rx"network unavailable"
   (lambda ()
     (refresh-github-snapshot!
      #:snapshot-path missing-path
      #:allow-offline? #f
      #:fetch (lambda (_username _token)
                (error 'offline "network unavailable"))))))
