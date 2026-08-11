#lang pollen

◊define-meta[title]{Home}
◊define-meta[description]{Software and experiments by Michael Khalil; essays and poems by Mica.}
◊define-meta[section]{home}
◊define-meta[kind]{home}
◊define-meta[canonical-path]{index.html}

◊section[#:class "home-hero"]{
  ◊div[#:class "home-hero__copy"]{
    ◊h1{I’m Michael Khalil. I make software, study applied math, and write as Mica.}
    ◊p[#:class "hero-lede"]{This site collects my projects, experiments, essays, and poems—including work that is unfinished or did not go to plan.}
    ◊div[#:class "hero-actions"]{
      ◊(action-link "writing/" "Read the writing")
      ◊(action-link "work/" "See what I’m building" "secondary")
    }
  }
  ◊(field-note)
}

◊section[#:class "home-section"]{
  ◊(section-heading "Recently")
  ◊(home-recent)
}

◊section[#:class "home-section"]{
  ◊(section-heading "Selected work")
  ◊(selected-work-list #:limit 3 #:compact? #t)
}

◊section[#:class "home-section"]{
  ◊(section-heading "Elsewhere on GitHub")
  ◊(github-feed #:limit 3 #:compact? #t)
  ◊p[#:class "section-after-link"]{
    ◊a[#:href github-profile-url]{All repositories on GitHub}
    ◊span[#:aria-hidden "true"]{→}
  }
}
