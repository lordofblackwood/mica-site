#lang racket/base

(require json
         net/http-client
         racket/cmdline
         racket/date
         racket/file
         racket/format
         racket/list
         racket/path
         racket/port
         racket/runtime-path
         racket/string
         (only-in "../src/config/site.rkt"
                  github-username
                  [repository-name configured-repository-name]))

(provide github-username
         default-current-repository
         default-snapshot-path
         default-overrides-path
         derive-pages-url
         eligible-repository?
         normalize-repository
         merge-project-overrides
         order-projects
         prepare-projects
         make-github-snapshot
         read-json-file
         read-github-snapshot
         read-project-overrides
         load-github-projects
         write-json-atomically!
         github-api-repository-page
         fetch-public-repositories
         refresh-github-snapshot!)

;; Keep the defaults here so local builds and CI use the same account and do not
;; accidentally list the source repository as one of the portfolio projects.
(define default-current-repository configured-repository-name)

(define-runtime-path data-directory "../src/data")
(define default-snapshot-path
  (build-path data-directory "github-projects.snapshot.json"))
(define default-overrides-path
  (build-path data-directory "github-project-overrides.json"))

(define absent (gensym 'absent))

(define (alternate-json-key key)
  (cond
    [(symbol? key) (symbol->string key)]
    [(string? key) (string->symbol key)]
    [else #f]))

;; read-json normally creates symbol keys. Accept string keys too so callers can
;; construct fixtures and override data without depending on that detail.
(define (json-ref object key [default #f])
  (cond
    [(not (hash? object)) default]
    [(hash-has-key? object key) (hash-ref object key)]
    [else
     (define alternate (alternate-json-key key))
     (if (and alternate (hash-has-key? object alternate))
         (hash-ref object alternate)
         default)]))

(define (json-has-key? object key)
  (not (eq? (json-ref object key absent) absent)))

(define (json-string value [default ""])
  (if (string? value) value default))

(define (nonempty-string? value)
  (and (string? value) (not (string=? (string-trim value) ""))))

(define (json-number value [default 0])
  (if (real? value) value default))

(define (json-true? value)
  (eq? value #t))

(define (canonical-key key)
  (if (string? key) (string->symbol key) key))

(define (canonical-object object)
  (for/hasheq ([(key value) (in-hash object)])
    (values (canonical-key key) value)))

(define (merge-objects base override)
  (for/fold ([result (canonical-object base)])
            ([(key value) (in-hash (canonical-object override))])
    (hash-set result key value)))

(define (repository-name repository)
  (json-string (json-ref repository 'name "")))

(define (repository-topics repository)
  (define value (json-ref repository 'topics '()))
  (if (list? value)
      (filter string? value)
      '()))

(define (portfolio-hidden-topic? repository)
  (for/or ([topic (in-list (repository-topics repository))])
    (string-ci=? topic "portfolio-hidden")))

(define (repository-owned-by? repository username)
  (define owner (json-ref repository 'owner absent))
  ;; The /users/:name/repos?type=owner endpoint always includes owner. Keeping
  ;; owner optional makes normalized API fixtures and cached data easy to test.
  (or (eq? owner absent)
      (and (hash? owner)
           (let ([login (json-string (json-ref owner 'login ""))])
             (or (string=? login "") (string-ci=? login username))))))

(define (eligible-repository? repository
                              #:username [username github-username]
                              #:current-repository
                              [current-repository default-current-repository])
  (define name (repository-name repository))
  (and (not (string=? name ""))
       (repository-owned-by? repository username)
       (not (json-true? (json-ref repository 'private #f)))
       (not (json-true? (json-ref repository 'fork #f)))
       (not (json-true? (json-ref repository 'archived #f)))
       (not (json-true? (json-ref repository 'disabled #f)))
       (not (portfolio-hidden-topic? repository))
       (or (not current-repository)
           (not (string-ci=? name current-repository)))))

(define (derive-pages-url repository #:username [username github-username])
  (define name (repository-name repository))
  (cond
    [(or (string=? name "")
         (not (json-true? (json-ref repository 'has_pages #f))))
     ""]
    [(string-ci=? name (string-append username ".github.io"))
     (format "https://~a.github.io/" username)]
    [else
     (format "https://~a.github.io/~a/" username name)]))

(define (preferred-project-url project)
  (cond
    [(nonempty-string? (json-ref project 'homepage ""))
     (json-ref project 'homepage)]
    [(nonempty-string? (json-ref project 'pages_url ""))
     (json-ref project 'pages_url)]
    [else (json-string (json-ref project 'repo_url ""))]))

;; Normalize only fields the portfolio needs. API-only state (fork, archive,
;; disabled, private, has_pages) is consumed during filtering/derivation and is
;; deliberately left out of the checked-in cache.
(define (normalize-repository repository #:username [username github-username])
  (define name (repository-name repository))
  (when (string=? name "")
    (raise-arguments-error 'normalize-repository
                           "repository has no non-empty name"
                           "repository" repository))
  (define project
    (hasheq 'name name
            'title name
            'description (json-string (json-ref repository 'description ""))
            'repo_url (json-string (json-ref repository 'html_url ""))
            'homepage (json-string (json-ref repository 'homepage ""))
            'pages_url (derive-pages-url repository #:username username)
            'language (json-string (json-ref repository 'language ""))
            'topics (repository-topics repository)
            'stars (json-number (json-ref repository 'stargazers_count 0))
            'forks (json-number (json-ref repository 'forks_count 0))
            'updated_at (json-string (json-ref repository 'updated_at ""))
            'featured #f))
  (hash-set project 'url (preferred-project-url project)))

(define (override-project-map overrides)
  (cond
    [(not (hash? overrides))
     (raise-argument-error 'merge-project-overrides "hash?" overrides)]
    [(json-has-key? overrides 'projects)
     (define projects (json-ref overrides 'projects))
     (unless (hash? projects)
       (raise-arguments-error 'merge-project-overrides
                              "the projects override value must be an object"
                              "projects" projects))
     projects]
    [else overrides]))

(define (override-for-name overrides name)
  (define exact (json-ref overrides name absent))
  (if (not (eq? exact absent))
      exact
      (for/first ([(key value) (in-hash overrides)]
                  #:when (string-ci=? (if (symbol? key)
                                          (symbol->string key)
                                          (format "~a" key))
                                      name))
        value)))

(define (merge-one-project project override)
  (cond
    [(not override) project]
    [(not (hash? override))
     (raise-arguments-error 'merge-project-overrides
                            "each repository override must be an object"
                            "repository" (json-ref project 'name "")
                            "override" override)]
    [else
     (define merged (merge-objects project override))
     ;; An explicit `url` wins. Otherwise recompute it so overriding homepage or
     ;; pages_url also changes the card's primary destination.
     (if (json-has-key? override 'url)
         merged
         (hash-set merged 'url (preferred-project-url merged)))]))

(define (merge-project-overrides projects overrides)
  (define project-overrides (override-project-map overrides))
  (for/list ([project (in-list projects)]
             #:do [(define override
                     (override-for-name project-overrides
                                        (json-ref project 'name "")))
                   (define merged (merge-one-project project override))]
             #:unless (json-true? (json-ref merged 'hidden #f)))
    ;; `hidden` controls inclusion; it is not presentation data and need not be
    ;; copied into the generated snapshot.
    (if (json-has-key? merged 'hidden)
        (hash-remove merged 'hidden)
        merged)))

(define (featured-project? project)
  (json-true? (json-ref project 'featured #f)))

(define (pages-project? project)
  (nonempty-string? (json-ref project 'pages_url "")))

(define (project-before? left right)
  (define left-featured? (featured-project? left))
  (define right-featured? (featured-project? right))
  (define left-pages? (pages-project? left))
  (define right-pages? (pages-project? right))
  (define left-updated (json-string (json-ref left 'updated_at "")))
  (define right-updated (json-string (json-ref right 'updated_at "")))
  (cond
    [(not (eq? left-featured? right-featured?)) left-featured?]
    [(not (eq? left-pages? right-pages?)) left-pages?]
    [(not (string=? left-updated right-updated))
     (string>? left-updated right-updated)]
    [else
     (string-ci<? (json-string (json-ref left 'name ""))
                  (json-string (json-ref right 'name "")))]))

(define (order-projects projects)
  (sort projects project-before?))

(define (prepare-projects repositories
                          [overrides (hasheq 'projects (hasheq))]
                          #:username [username github-username]
                          #:current-repository
                          [current-repository default-current-repository])
  (unless (list? repositories)
    (raise-argument-error 'prepare-projects "list?" repositories))
  (define normalized
    (for/list ([repository (in-list repositories)]
               #:when (eligible-repository?
                       repository
                       #:username username
                       #:current-repository current-repository))
      (normalize-repository repository #:username username)))
  (order-projects (merge-project-overrides normalized overrides)))

(define (utc-timestamp [seconds (current-seconds)])
  (define date (seconds->date seconds #f))
  (define (two n) (~r n #:min-width 2 #:pad-string "0"))
  (format "~a-~a-~aT~a:~a:~aZ"
          (~r (date-year date) #:min-width 4 #:pad-string "0")
          (two (date-month date))
          (two (date-day date))
          (two (date-hour date))
          (two (date-minute date))
          (two (date-second date))))

(define (make-github-snapshot projects
                              #:username [username github-username]
                              #:generated-at [generated-at (utc-timestamp)])
  (unless (list? projects)
    (raise-argument-error 'make-github-snapshot "list?" projects))
  (hasheq 'schema_version 1
          'username username
          'generated_at generated-at
          'projects projects))

(define (read-json-file path)
  (call-with-input-file path read-json))

(define (valid-snapshot? snapshot)
  (and (hash? snapshot)
       (equal? (json-ref snapshot 'schema_version #f) 1)
       (string? (json-ref snapshot 'username #f))
       (list? (json-ref snapshot 'projects #f))))

(define (read-github-snapshot [path default-snapshot-path])
  (define snapshot (read-json-file path))
  (unless (valid-snapshot? snapshot)
    (raise-arguments-error 'read-github-snapshot
                           "not a valid GitHub project snapshot"
                           "path" path))
  snapshot)

(define (read-project-overrides [path default-overrides-path])
  (if (file-exists? path)
      (let ([overrides (read-json-file path)])
        (unless (hash? overrides)
          (raise-arguments-error 'read-project-overrides
                                 "override file must contain a JSON object"
                                 "path" path))
        ;; Validate the shape now so a typo fails close to its source.
        (override-project-map overrides)
        overrides)
      (hasheq 'schema_version 1 'projects (hasheq))))

(define (load-github-projects [path default-snapshot-path])
  (json-ref (read-github-snapshot path) 'projects '()))

(define (write-json-atomically! value path)
  (define target (path->complete-path path))
  (define parent (or (path-only target) (current-directory)))
  (make-directory* parent)
  ;; A temporary file in the destination directory keeps the final rename on
  ;; one filesystem, which is the part that makes replacement atomic.
  (define temporary
    (make-temporary-file ".github-projects-~a.tmp" #f parent))
  (dynamic-wind
    void
    (lambda ()
      (call-with-output-file temporary
        (lambda (output)
          (write-json value output)
          (newline output))
        #:exists 'truncate/replace)
      (rename-file-or-directory temporary target #t))
    (lambda ()
      (when (file-exists? temporary)
        (delete-file temporary))))
  (void))

(define (successful-http-status? status)
  (and (bytes? status)
       (regexp-match? #rx#"(^|[ ])2[0-9][0-9]([ ]|$)" status)))

(define (github-api-repository-page username token page per-page)
  (define request-path
    (format "/users/~a/repos?type=owner&sort=updated&direction=desc&per_page=~a&page=~a"
            username per-page page))
  (define headers
    (append
     (list #"User-Agent: mica-site-github-sync"
           #"Accept: application/vnd.github+json"
           #"X-GitHub-Api-Version: 2022-11-28")
     (if (nonempty-string? token)
         (list (string->bytes/utf-8 (string-append "Authorization: Bearer " token)))
         '())))
  (define-values (status _response-headers input)
    (http-sendrecv "api.github.com"
                   request-path
                   #:ssl? #t
                   #:method #"GET"
                   #:headers headers))
  (define body
    (dynamic-wind void
                  (lambda () (port->string input))
                  (lambda () (close-input-port input))))
  (unless (successful-http-status? status)
    (define excerpt
      (if (> (string-length body) 400)
          (string-append (substring body 0 400) "…")
          body))
    (error 'github-api-repository-page
           "GitHub returned ~a for page ~a: ~a"
           (bytes->string/utf-8 status #\?) page excerpt))
  (define response
    (call-with-input-string body read-json))
  (unless (list? response)
    (error 'github-api-repository-page
           "GitHub response for page ~a was not a repository list"
           page))
  response)

(define (fetch-public-repositories
         #:username [username github-username]
         #:token [token (getenv "GITHUB_TOKEN")]
         #:per-page [per-page 100]
         #:request-page [request-page github-api-repository-page])
  (unless (and (exact-integer? per-page) (<= 1 per-page 100))
    (raise-argument-error 'fetch-public-repositories
                          "exact integer from 1 through 100"
                          per-page))
  (let loop ([page 1] [repositories '()])
    (define batch (request-page username token page per-page))
    (unless (list? batch)
      (raise-arguments-error 'fetch-public-repositories
                             "request-page did not return a list"
                             "page" page
                             "result" batch))
    (define accumulated (append repositories batch))
    (if (< (length batch) per-page)
        accumulated
        (loop (add1 page) accumulated))))

(define (default-warning message)
  (eprintf "GitHub sync: ~a\n" message))

(define (refresh-github-snapshot!
         #:username [username github-username]
         #:token [token (getenv "GITHUB_TOKEN")]
         #:current-repository
         [current-repository default-current-repository]
         #:snapshot-path [snapshot-path default-snapshot-path]
         #:overrides-path [overrides-path default-overrides-path]
         #:allow-offline? [allow-offline? #t]
         #:on-warning [on-warning default-warning]
         #:fetch [fetcher
                  (lambda (requested-username requested-token)
                    (fetch-public-repositories
                     #:username requested-username
                     #:token requested-token))])
  ;; Only network/fetch failures invoke the cache fallback. Invalid overrides,
  ;; transformation bugs, and write failures stay visible instead of being
  ;; silently mistaken for an offline build.
  (define-values (repositories cached-snapshot)
    (with-handlers
        ([exn:fail?
          (lambda (fetch-failure)
            (if (and allow-offline? (file-exists? snapshot-path))
                (with-handlers ([exn:fail?
                                 (lambda (_cache-failure)
                                   (raise fetch-failure))])
                  (define cached (read-github-snapshot snapshot-path))
                  (on-warning
                   (format "~a; using cached snapshot from ~a"
                           (exn-message fetch-failure)
                           snapshot-path))
                  (values #f cached))
                (raise fetch-failure)))])
      (values (fetcher username token) #f)))
  (if cached-snapshot
      cached-snapshot
      (let* ([overrides (read-project-overrides overrides-path)]
             [projects
              (prepare-projects repositories
                                overrides
                                #:username username
                                #:current-repository current-repository)]
             [snapshot
              (make-github-snapshot projects #:username username)])
        (write-json-atomically! snapshot snapshot-path)
        snapshot)))

(module+ main
  (define selected-username github-username)
  (define selected-current-repository default-current-repository)
  (define selected-snapshot-path default-snapshot-path)
  (define selected-overrides-path default-overrides-path)
  (define allow-offline? #t)

  (command-line
   #:program "sync-github.rkt"
   #:once-each
   [("-u" "--username") username
    "GitHub username to synchronize"
    (set! selected-username username)]
   [("--current-repo") repository
    "Repository containing this portfolio (excluded from projects)"
    (set! selected-current-repository repository)]
   [("--snapshot" "--cache") path
    "Snapshot/cache JSON destination"
    (set! selected-snapshot-path (string->path path))]
   [("--overrides") path
    "Local project-overrides JSON file"
    (set! selected-overrides-path (string->path path))]
   [("--strict-online")
    "Fail instead of using the existing snapshot when GitHub is unavailable"
    (set! allow-offline? #f)])

  (define snapshot
    (refresh-github-snapshot!
     #:username selected-username
     #:current-repository selected-current-repository
     #:snapshot-path selected-snapshot-path
     #:overrides-path selected-overrides-path
     #:allow-offline? allow-offline?))
  (printf "GitHub project snapshot: ~a projects in ~a\n"
          (length (json-ref snapshot 'projects '()))
          selected-snapshot-path))
