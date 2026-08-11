#lang racket

(require racket/cmdline
         racket/date
         racket/file
         racket/path
         racket/runtime-path
         racket/string
         (only-in "../src/config/site.rkt" writing-author))

(define-runtime-path repository-root "..")

(define (today)
  (define date (seconds->date (current-seconds)))
  (format "~a-~a-~a"
          (date-year date)
          (~r (date-month date) #:min-width 2 #:pad-string "0")
          (~r (date-day date) #:min-width 2 #:pad-string "0")))

(define (slugify title)
  (define lowered (string-downcase title))
  (define words (regexp-match* #px"[a-z0-9]+" lowered))
  (if (null? words) "untitled" (string-join words "-")))

(define (content-spec type)
  (case (string->symbol (string-downcase type))
    [(essay) (values "writing" "writing" "essay")]
    [(fiction) (values "writing" "writing" "fiction")]
    [(poem) (values "poems" "poems" "poem")]
    [(project) (values "work" "work" "project")]
    [else
     (raise-user-error 'new-content
                       "type must be essay, fiction, poem, or project; received ~a"
                       type)]))

(define (page-template title section kind)
  (define common
    (string-append
     "#lang pollen\n\n"
     (format "◊define-meta[title]{~a}\n" title)
     "◊define-meta[description]{Add a short, honest description.}\n"
     (format "◊define-meta[section]{~a}\n" section)
     (format "◊define-meta[kind]{~a}\n" kind)
     (if (member kind '("essay" "fiction" "poem"))
         (string-append
          (format "◊define-meta[author]{~a}\n" writing-author)
          "◊define-meta[provenance]{unverified}\n")
         "")
     (format "◊define-meta[date]{~a}\n" (today))
     "◊define-meta[tags]{}\n"
     "◊define-meta[draft]{true}\n"
     "◊define-meta[featured]{false}\n"
     "◊define-meta[featured-order]{999}\n"))
  (case (string->symbol kind)
    [(essay fiction)
     (string-append
      common
      "\n"
      (format "◊content-header[#:back-href \"/writing/\" #:back-label \"Writing\"]{~a}\n\n" title)
      "◊lede{Start with the sentence that makes you want to keep reading.}\n\n"
      "◊p{Write here.}\n")]
    [(poem)
     (string-append
      common
      "\n"
      (format "◊content-header[#:back-href \"/poems/\" #:back-label \"Poems\"]{~a}\n\n" title)
      "◊poem{\n"
      "  \"Start here.\"\n"
      "}\n")]
    [(project)
     (string-append
      common
      "◊define-meta[project-kind]{software}\n"
      "◊define-meta[status]{in progress}\n"
      "◊define-meta[github-repo]{}\n"
      "◊define-meta[live-url]{}\n\n"
      (format "◊content-header[#:back-href \"/work/\" #:back-label \"Work\"]{~a}\n\n" title)
      "◊project-meta[#:status \"in progress\" #:kind \"software\"]\n\n"
      "◊lede{What is this, and why did you make it?}\n\n"
      "◊section-title{What I built}\n\n"
      "◊p{Write here.}\n")]))

(define (create-content! type title)
  (define-values (directory section kind) (content-spec type))
  (define destination
    (build-path repository-root "src" directory
                (format "~a.html.pm" (slugify title))))
  (when (file-exists? destination)
    (raise-user-error 'new-content
                      "refusing to overwrite existing file ~a"
                      (path->string destination)))
  (make-parent-directory* destination)
  (call-with-output-file destination
    #:exists 'error
    (lambda (output)
      (display (page-template title section kind) output)))
  (printf "Created draft: ~a\n" (path->string destination))
  (displayln "Edit it, then change draft to false when it is ready to publish.")
  destination)

(module+ main
  (command-line
   #:program "new-content.rkt"
   #:args (type title)
   (create-content! type title)))

(provide slugify content-spec page-template create-content!)
