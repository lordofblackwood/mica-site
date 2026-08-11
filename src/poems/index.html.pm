#lang pollen

◊define-meta[title]{Poems}
◊define-meta[description]{Poems and fragments by Mica.}
◊define-meta[section]{poems}
◊define-meta[kind]{index}
◊define-meta[canonical-path]{poems/}

◊header[#:class "archive-header archive-header--poems"]{
  ◊div{
    ◊h1{Poems}
    ◊p[#:class "lede"]{Poems and fragments by Mica.}
  }
  ◊aside[#:class "archive-note"]{
    ◊h2{reading note}
    ◊p{No summaries. Start with a title.}
  }
}

◊(content-index "poems")
