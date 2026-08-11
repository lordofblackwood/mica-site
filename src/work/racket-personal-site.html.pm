#lang pollen

◊define-meta[title]{Racket / Pollen Personal Site}
◊define-meta[description]{This website, built as a flexible personal publishing system in Racket and Pollen.}
◊define-meta[section]{work}
◊define-meta[kind]{project}
◊define-meta[date]{2026-05-09}
◊define-meta[tags]{Racket, Pollen, static-site}
◊define-meta[draft]{false}
◊define-meta[featured]{true}
◊define-meta[project-kind]{publishing system}
◊define-meta[status]{active}

◊content-header[#:back-href "/work/" #:back-label "Work"]{Racket / Pollen Personal Site}

◊project-meta[#:status "active" #:kind "publishing system"]

◊lede{This site is part portfolio, part archive, part poetry collection, part research notebook, and part creative-coding project. Racket and Pollen turn all of that into a static site I can keep shaping myself.}

◊section-title{Why Racket}

◊p{Racket is a language for making languages, and Pollen makes documents programmable. That is useful for a site where an essay, a poem, and a project page should share a system without being forced into the same shape.}

◊section-title{What I want the system to do}

◊ul{
  ◊li{Make new writing easy to publish with a small, consistent metadata block.}
  ◊li{Give poems a reading experience that does not look like a blog template.}
  ◊li{Let project pages hold links, demos, screenshots, and honest notes about what is still unfinished.}
  ◊li{Discover public GitHub work automatically while leaving room for hand-written context.}
  ◊li{Build into portable static files that can be hosted on GitHub Pages.}
}
