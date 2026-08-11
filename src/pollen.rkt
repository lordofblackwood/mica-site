#lang racket/base

(require json
         pollen/core
         pollen/tag
         racket/file
         racket/format
         racket/list
         racket/path
         racket/runtime-path
         racket/string
         racket/match
         txexpr
         "config/site.rkt")

(provide (all-defined-out)
         (all-from-out "config/site.rkt"))

(define-runtime-path source-root/raw ".")
(define source-root (simplify-path source-root/raw #t))
(define-runtime-path github-snapshot-path "data/github-projects.snapshot.json")

;; -----------------------------------------------------------------------------
;; Metadata and content discovery

(struct content-item
  (title description section kind author date tags featured featured-order href source
         project-kind status github-repo live-url)
  #:transparent)

(define (value->string value [default ""])
  (cond
    [(string? value) value]
    [(symbol? value) (symbol->string value)]
    [(not value) default]
    [else (format "~a" value)]))

(define (meta-ref metas key [default ""])
  (value->string (hash-ref metas key #f) default))

(define (current-meta key [default ""])
  (define metas (current-metas))
  (if (hash? metas) (meta-ref metas key default) default))

(define (truthy? value)
  (member (string-downcase (value->string value)) '("true" "yes" "1" "on")))

(define (split-tags value)
  (filter (lambda (tag) (not (string=? tag "")))
          (map string-trim
               (string-split (value->string value) ","))))

(define (content-source? path)
  (and (file-exists? path)
       (regexp-match? #px"[.]html[.]pm$" (path->string path))
       (not (regexp-match? #px"(?:^|/)index[.]html[.]pm$"
                           (path->string path)))))

(define (source->relative-output source)
  (regexp-replace #px"[.]pm$"
                  (path->string (find-relative-path source-root source))
                  ""))

(define (source->href source)
  (site-url (source->relative-output source)))

(define literary-kinds '("essay" "fiction" "poem"))
(define prose-kinds '("essay" "fiction"))

(define (literary-kind? kind)
  (and (member (value->string kind) literary-kinds) #t))

(define (prose-kind? kind)
  (and (member (value->string kind) prose-kinds) #t))

(define (author-for-kind kind)
  (if (literary-kind? kind)
      writing-author
      person-name))

(define (source->content-item source)
  (define metas (get-metas source))
  (content-item
   (meta-ref metas 'title "Untitled")
   (meta-ref metas 'description "")
   (meta-ref metas 'section "")
   (meta-ref metas 'kind "")
   (meta-ref metas 'author
             (author-for-kind (meta-ref metas 'kind "")))
   (meta-ref metas 'date "")
   (split-tags (hash-ref metas 'tags ""))
   (truthy? (hash-ref metas 'featured #f))
   (or (string->number (meta-ref metas 'featured-order "999")) 999)
   (source->href source)
   source
   (meta-ref metas 'project-kind "")
   (meta-ref metas 'status "")
   (meta-ref metas 'github-repo "")
   (meta-ref metas 'live-url "")))

(define (content-before? left right)
  (cond
    [(not (string=? (content-item-date left) (content-item-date right)))
     (string>? (content-item-date left) (content-item-date right))]
    [else
     (string-ci<? (content-item-title left) (content-item-title right))]))

(define (discover-content [section #f])
  (define items
    (for/list ([source (in-list (find-files content-source? source-root))]
               #:do [(define metas (get-metas source))]
               #:unless (truthy? (hash-ref metas 'draft #f))
               #:when (or (not section)
                          (string=? (meta-ref metas 'section)
                                    (value->string section))))
      (source->content-item source)))
  (sort items content-before?))

(define (find-content title)
  (findf (lambda (item) (string=? (content-item-title item) title))
         (discover-content)))

(define (latest-content section)
  (match (discover-content section)
    [(cons item _) item]
    [_ #f]))

;; -----------------------------------------------------------------------------
;; Shared document tags

(define (root . elements)
  `(div ((class "page-content")) ,@elements))

(define (heading . elements) `(h2 ,@elements))
(define (subheading . elements) `(h3 ,@elements))
(define (lede . elements) `(p ((class "lede")) ,@elements))
(define (section-title . elements) `(h2 ((class "section-title")) ,@elements))
(define (pullquote . elements) `(blockquote ((class "pullquote")) ,@elements))
(define (note . elements) `(aside ((class "note")) ,@elements))

(define (link url . elements)
  `(a ((href ,(if (external-url? url) url (site-url url)))) ,@elements))

(define (action-link url label [tone "primary"])
  `(a ((href ,(site-url url)) (class ,(format "action-link action-link--~a" tone)))
     (span ,label)
     (svg ((viewBox "0 0 24 24") (aria-hidden "true") (class "arrow-icon"))
       (path ((d "M5 12h13M13 6l6 6-6 6"))))))

(define (section-heading label)
  `(div ((class "ruled-heading"))
     (h2 ,label)
     (span ((class "ruled-heading__line") (aria-hidden "true")))))

(define (content-header #:back-href [back-href #f]
                        #:back-label [back-label "Back"]
                        . title-elements)
  (define date (current-meta 'date ""))
  (define kind (current-meta 'kind ""))
  (define author (current-meta 'author (author-for-kind kind)))
  (define writing? (literary-kind? kind))
  `(header ((class "content-header"))
     ,@(if back-href
           `((a ((class "back-link") (href ,(site-url back-href)))
               (span ((aria-hidden "true")) "←")
               ,back-label))
           '())
     (div ((class "content-header__grid"))
       (div
         (h1 ,@title-elements)
         ,@(cond
             [writing?
              `((p ((class "content-byline"))
                  (span "By " ,author)
                  ,@(if (string=? date "")
                        '()
                        `((span ((aria-hidden "true")) " · ")
                          (span "Added " ,(format-date date))))))]
             [(string=? date "") '()]
             [else
              `((p ((class "content-date"))
                  "Added "
                  ,(format-date date)))]))
       (div ((class "page-index") (aria-hidden "true"))
         (span "01.")))))

(define (project-meta #:repo [repo #f]
                      #:live [live #f]
                      #:status [status (current-meta 'status "active")]
                      #:kind [kind (current-meta 'project-kind "project")])
  `(div ((class "project-meta"))
     (span ,kind)
     (span ((aria-hidden "true")) "·")
     (span ,status)
     ,@(if repo
           `((a ((href ,repo) (rel "me")) "Source"))
           '())
     ,@(if live
           `((a ((href ,live)) "Live site"))
           '())))

(define (normalise-poem-line line)
  (cond
    [(eq? line 'blank) 'blank]
    [else
     (define trimmed (string-trim (value->string line)))
     (cond
       [(string=? trimmed "") #f]
       [(string=? trimmed "blank") 'blank]
       [(and (>= (string-length trimmed) 2)
             (char=? (string-ref trimmed 0) #\")
             (char=? (string-ref trimmed (sub1 (string-length trimmed))) #\"))
        (substring trimmed 1 (sub1 (string-length trimmed)))]
       [else trimmed])]))

(define (poem . lines)
  (define cleaned (filter values (map normalise-poem-line lines)))
  `(div ((class "poem") (role "document"))
     ,@(for/list ([line (in-list cleaned)])
         (if (eq? line 'blank)
             '(div ((class "stanza-break") (aria-hidden "true")))
             `(p ,line)))))

(define (format-date value)
  (match (regexp-match #px"^(\\d{4})-(\\d{2})-(\\d{2})$" value)
    [(list _ year month day)
     (define month-name
       (list-ref '("January" "February" "March" "April" "May" "June"
                   "July" "August" "September" "October" "November" "December")
                 (sub1 (string->number month))))
     (format "~a ~a, ~a" month-name (number->string (string->number day)) year)]
    [_ value]))

(define (format-index value)
  (string-append (~r value #:min-width 2 #:pad-string "0") "."))

;; -----------------------------------------------------------------------------
;; Navigation and site chrome

(define (nav-link item active-section)
  (match-define (list label path section) item)
  `(a (,@(if (string=? section active-section)
             '((aria-current "page"))
             '())
       (href ,(site-url path)))
     ,label))

(define (theme-toggle)
  `(button ((type "button")
            (class "theme-toggle")
            (data-theme-toggle "true")
            (aria-label "Switch to light mode"))
     (span ((class "theme-toggle__icon")
            (data-theme-icon "true")
            (aria-hidden "true"))
       "☀")
     (span ((class "theme-toggle__label")
            (data-theme-label "true"))
       "Light")))

(define (site-header [active-section "home"])
  `(header ((class "site-header"))
     (a ((class "brand") (href ,(site-url ""))
         (aria-label ,(format "~a, home" site-name)))
       ,site-name)
     (div ((class "site-header__controls"))
       (nav ((class "desktop-nav") (aria-label "Primary navigation"))
         ,@(for/list ([item (in-list nav-items)]) (nav-link item active-section)))
       ,(theme-toggle)
       (details ((class "mobile-nav"))
         (summary "Menu")
         (nav ((aria-label "Mobile navigation"))
           ,@(for/list ([item (in-list nav-items)]) (nav-link item active-section)))))))

(define (site-footer)
  `(footer ((class "site-footer"))
     (div ((class "site-footer__links"))
       (a ((href ,github-profile-url) (rel "me")) "GitHub")
       (a ((href ,(site-url "feed.xml"))) "RSS")
       (span ,(format "© ~a ~a" current-year person-name)))
     (p "having fun learning and failing")))

;; -----------------------------------------------------------------------------
;; Editorial list components

(define code-tags '("code" "engineering" "software" "racket" "creative-coding"
                    "machine-learning" "sql" "systems"))
(define research-tags '("research" "theology" "computational-theology"
                        "medical-imaging" "math" "machine-learning"))
(define life-tags '("life" "identity" "self-worth" "personal-site" "faith"
                    "grief" "healing"))

(define (tags-intersect? tags candidates)
  (for/or ([tag (in-list tags)]) (member (string-downcase tag) candidates)))

(define (item-filter-keys item)
  (define tags (content-item-tags item))
  (string-join
   (filter values
           (list (and (string=? (content-item-kind item) "fiction") "fiction")
                 (and (tags-intersect? tags code-tags) "code")
                 (and (tags-intersect? tags research-tags) "research")
                 (and (tags-intersect? tags life-tags) "life")))
   " "))

(define (index-row item index)
  (define tags (content-item-tags item))
  `(article ((class "index-row")
             (data-filter-keys ,(item-filter-keys item)))
     (span ((class "row-number") (aria-hidden "true")) ,(format-index index))
     (div ((class "index-row__title"))
       (h3 (a ((href ,(content-item-href item))) ,(content-item-title item)))
       ,@(if (string=? (content-item-description item) "")
             '()
             `((p ((class "index-row__description")) ,(content-item-description item)))))
     (time ((datetime ,(content-item-date item))) ,(format-date (content-item-date item)))
     ,@(if (null? tags)
           '((span ((class "index-row__tags"))))
           `((span ((class "index-row__tags")) ,(string-join tags ", "))))
     (a ((class "row-arrow")
         (href ,(content-item-href item))
         (aria-label ,(format "Read ~a" (content-item-title item))))
       (svg ((viewBox "0 0 24 24") (aria-hidden "true"))
         (path ((d "M5 12h13M13 6l6 6-6 6")))))))

(define (content-index section #:filters? [filters? #f])
  (define items (discover-content section))
  (define show-filters? (and filters? (pair? items)))
  (define available-filters
    (append '("All")
            (if (ormap (lambda (item)
                         (string=? (content-item-kind item) "fiction"))
                       items)
                '("Fiction")
                '())
            '("Code" "Research" "Life")))
  `(div ((class "archive")
         ,@(if show-filters? '((data-content-filter "true")) '()))
     ,@(if show-filters?
           `((div ((class "archive-filters") (aria-label "Filter writing"))
               ,@(for/list ([filter available-filters])
                   `(button ((type "button")
                             (data-filter-value ,(string-downcase filter))
                             ,@(if (string=? filter "All")
                                   '((aria-pressed "true"))
                                   '((aria-pressed "false"))))
                      ,filter))))
           '())
     ,@(if (null? items)
           '((p ((class "archive-empty")) "Nothing is published here yet."))
           `((div ((class "index-list") (aria-live "polite"))
               ,@(for/list ([item (in-list items)]
                            [index (in-naturals 1)])
                   (index-row item index)))
             (p ((class "archive-count"))
               (span ((data-visible-count "true"))
                     ,(number->string (length items)))
               ,(if (= (length items) 1) " piece" " pieces"))))))

(define (work-row item index #:compact? [compact? #f])
  `(article ((class ,(if compact? "work-row work-row--compact" "work-row")))
     (span ((class "row-number") (aria-hidden "true")) ,(format-index index))
     (div ((class "work-row__body"))
       (h3 (a ((href ,(content-item-href item))) ,(content-item-title item)))
       ,@(if compact? '() `((p ,(content-item-description item)))))
     ,@(if compact?
           '()
           `((p ((class "work-row__meta"))
               ,(string-join
                 (filter (lambda (value) (not (string=? value "")))
                         (list (content-item-project-kind item)
                               (content-item-status item)))
                 " · "))))
     (a ((class "work-row__link") (href ,(content-item-href item)))
       ,@(if compact?
             '()
             (list (if (string=? (content-item-project-kind item) "creative coding")
                       "Read the notes"
                       "Read the case study")))
       (svg ((viewBox "0 0 24 24") (aria-hidden "true") (class "arrow-icon"))
         (path ((d "M5 12h13M13 6l6 6-6 6")))))))

(define (selected-work-list #:limit [limit 3] #:compact? [compact? #f])
  (define work-items (discover-content "work"))
  (define featured
    (sort (filter content-item-featured work-items)
          < #:key content-item-featured-order))
  (define selected (take (if (null? featured) work-items featured)
                         (min limit (length (if (null? featured) work-items featured)))))
  `(div ((class "work-list"))
     ,@(for/list ([item (in-list selected)]
                  [index (in-naturals 1)])
         (work-row item index #:compact? compact?))))

;; -----------------------------------------------------------------------------
;; GitHub snapshot rendering

(define (json-ref object key [default #f])
  (cond
    [(hash? object)
     (hash-ref object key
               (lambda ()
                 (hash-ref object (symbol->string key) default)))]
    [else default]))

(define (load-github-projects)
  (with-handlers ([exn:fail? (lambda (_) '())])
    (call-with-input-file github-snapshot-path
      (lambda (input)
        (define data (read-json input))
        (cond
          [(list? data) data]
          [(hash? data)
           (define projects (json-ref data 'projects #f))
           (define repositories (json-ref data 'repositories #f))
           (cond
             [(list? projects) projects]
             [(list? repositories) repositories]
             [else '()])]
          [else '()])))))

(define (github-project-name project)
  (value->string (or (json-ref project 'title #f)
                     (json-ref project 'name #f)
                     "Untitled repository")))

(define (github-project-url project)
  (value->string (or (json-ref project 'url #f)
                     (json-ref project 'homepage #f)
                     (json-ref project 'pages_url #f)
                     (json-ref project 'repo_url #f)
                     github-profile-url)))

(define (github-project-description project)
  (value->string (or (json-ref project 'description #f)
                     (json-ref project 'summary #f)
                     "")))

(define (github-project-language project)
  (value->string (json-ref project 'language "")))

(define (github-project-source-url project)
  (value->string (or (json-ref project 'html_url #f)
                     (json-ref project 'repo_url #f)
                     (format "~a/~a" github-profile-url (github-project-name project)))))

(define (github-project-live-url project)
  (value->string (or (json-ref project 'live_url #f)
                     (json-ref project 'pages_url #f)
                     (json-ref project 'homepage #f)
                     "")))

(define (github-row project index #:compact? [compact? #f])
  (define name (github-project-name project))
  (define description (github-project-description project))
  (define language (github-project-language project))
  (define source-url (github-project-source-url project))
  (define live-url (github-project-live-url project))
  (define project-url (github-project-url project))
  `(article ((class ,(if compact? "github-row github-row--compact" "github-row")))
     (span ((class "row-number") (aria-hidden "true")) ,(format-index index))
     (div ((class "github-row__identity"))
       (h3 (a ((href ,project-url)) ,name))
       ,@(if (or compact? (string=? description ""))
             '()
             `((p ,description))))
     ,@(if compact?
           `((span ((class "github-row__compact-meta"))
               ,(string-join
                 (filter (lambda (value)
                           (and (string? value) (not (string=? value ""))))
                         (list language (and (not (string=? live-url "")) "live site")))
                 " · ")))
           `((span ((class "github-row__language")) ,language)
             (div ((class "github-row__links"))
               (a ((href ,source-url)) "Source")
               ,@(if (string=? live-url "")
                     '()
                     `((a ((href ,live-url)) "Live site"))))))
     (a ((class "row-arrow") (href ,project-url)
         (aria-label ,(format "Open ~a" name)))
       (svg ((viewBox "0 0 24 24") (aria-hidden "true"))
         (path ((d "M5 12h13M13 6l6 6-6 6")))))))

(define (github-feed #:limit [limit #f] #:compact? [compact? #f])
  (define projects (load-github-projects))
  (define shown
    (if limit (take projects (min limit (length projects))) projects))
  `(div ((class "github-feed"))
     ,@(if (null? shown)
           `((p ((class "github-empty"))
               "The project list is refreshing. "
               (a ((href ,github-profile-url)) "See everything on GitHub.")))
           (for/list ([project (in-list shown)]
                      [index (in-naturals 1)])
             (github-row project index #:compact? compact?)))))

(define (home-recent)
  (define candidates
    (filter values
            (list (latest-content "writing")
                  (latest-content "poems"))))
  (define github-projects (load-github-projects))
  `(div ((class "recent-list"))
     ,@(for/list ([entry (in-list (append candidates
                                         (if (null? github-projects)
                                             '()
                                             (list (first github-projects)))))]
                  [index (in-naturals 1)])
         (cond
           [(content-item? entry)
            `(article ((class "recent-row"))
               (span ((class "row-number") (aria-hidden "true")) ,(format-index index))
               (h3 (a ((href ,(content-item-href entry))) ,(content-item-title entry)))
               (span ((class "recent-row__kind")) ,(content-item-kind entry))
               (a ((class "row-arrow") (href ,(content-item-href entry))
                   (aria-label ,(format "Open ~a" (content-item-title entry))))
                 (svg ((viewBox "0 0 24 24") (aria-hidden "true"))
                   (path ((d "M5 12h13M13 6l6 6-6 6"))))))]
           [else
            (define name (github-project-name entry))
            (define project-url (github-project-url entry))
            `(article ((class "recent-row"))
               (span ((class "row-number") (aria-hidden "true")) ,(format-index index))
               (h3 (a ((href ,project-url)) ,name))
               (span ((class "recent-row__kind")) "project")
               (a ((class "row-arrow") (href ,project-url)
                   (aria-label ,(format "Open ~a" name)))
                 (svg ((viewBox "0 0 24 24") (aria-hidden "true"))
                   (path ((d "M5 12h13M13 6l6 6-6 6"))))))]))))

(define (field-note)
  `(aside ((class "field-note") (aria-label "Notes to self"))
     (div ((class "field-note__words"))
       (h2 "notes to self")
       (p "build to understand")
       (ul (li "math") (li "code") (li "language") (li "meaning")))
     (svg ((class "field-note__graph") (viewBox "0 0 220 150")
           (role "img") (aria-label "A hand-drawn curve rising across a graph"))
       (path ((class "graph-axis") (d "M34 118H198M58 136V16")))
       (path ((class "graph-curve") (d "M58 111 C93 109 125 99 148 76 C171 53 176 27 181 17")))
       (path ((class "graph-dash") (d "M58 116 C102 113 136 92 157 63 C169 47 184 39 196 35")))
       (text ((x "202") (y "124")) "x")
       (text ((x "49") (y "15")) "y"))
     (pre ((class "field-note__code"))
       "def seek(thing):\n  while not understood(thing):\n    build()\n    read()\n    write()\n    question()\n  return closer")
     (p ((class "field-note__return")) "keep returning.")))

(define (article-pagination #:previous-href [previous-href #f]
                            #:previous-title [previous-title ""]
                            #:next-href [next-href #f]
                            #:next-title [next-title ""])
  `(nav ((class "article-pagination") (aria-label "More writing"))
     ,@(if previous-href
           `((a ((class "article-pagination__previous")
                 (href ,(site-url previous-href)))
               (span ((aria-hidden "true")) "←")
               (span ,previous-title)))
           '((span)))
     ,@(if next-href
           `((a ((class "article-pagination__next")
                 (href ,(site-url next-href)))
               (span ,next-title)
               (span ((aria-hidden "true")) "→")))
           '((span)))))

(define (already-prefixed-site-url? value)
  (and (string? value)
       (not (string=? site-base-path ""))
       (or (string=? value site-base-path)
           (string-prefix? value (string-append site-base-path "/")))))

(define (resolve-site-url value)
  (if (already-prefixed-site-url? value) value (site-url value)))

(define (collection-pagination [current-path #f])
  (define section (current-meta 'section ""))
  (define current-href
    (and current-path (resolve-site-url (value->string current-path))))
  (define items (discover-content section))
  (define position
    (index-where items
                 (lambda (item)
                   (and current-href
                        (string=? (resolve-site-url (content-item-href item))
                                  current-href)))))
  (cond
    [(not position) '(span)]
    [else
     (define previous (and (> position 0) (list-ref items (sub1 position))))
     (define next (and (< position (sub1 (length items)))
                       (list-ref items (add1 position))))
     `(nav ((class "article-pagination") (aria-label "More from this section"))
        ,@(if previous
              `((a ((class "article-pagination__previous")
                    (href ,(resolve-site-url (content-item-href previous))))
                  (span ((aria-hidden "true")) "←")
                  (span ,(content-item-title previous))))
              '((span)))
        ,@(if next
              `((a ((class "article-pagination__next")
                    (href ,(resolve-site-url (content-item-href next))))
                  (span ,(content-item-title next))
                  (span ((aria-hidden "true")) "→")))
              '((span))))]))
