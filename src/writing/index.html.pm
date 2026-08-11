#lang pollen

◊define-meta[title]{Writing}
◊define-meta[description]{Essays, fiction, and notes by Mica on software, research, creative work, and learning.}
◊define-meta[section]{writing}
◊define-meta[kind]{index}
◊define-meta[canonical-path]{writing/}

◊header[#:class "archive-header"]{
  ◊div{
    ◊h1{Writing}
    ◊p[#:class "lede"]{Essays, fiction, and notes by Mica about software, Racket, research, and creative work.}
  }
  ◊aside[#:class "archive-note"]{
    ◊h2{how this works}
    ◊p{New pieces appear here automatically when I publish them.}
  }
}

◊(content-index "writing" #:filters? #t)
