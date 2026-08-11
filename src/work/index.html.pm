#lang pollen

◊define-meta[title]{Work}
◊define-meta[description]{Software, research, and creative projects by Michael Khalil, plus an automatically updated GitHub archive.}
◊define-meta[section]{work}
◊define-meta[kind]{index}
◊define-meta[canonical-path]{work/}

◊header[#:class "work-header"]{
  ◊div{
    ◊h1{Work}
    ◊p[#:class "lede"]{Software, research, and experiments. Some are finished; some are still in progress.}
  }
  ◊aside[#:class "archive-note"]{
    ◊h2{how this works}
    ◊p{The project pages explain what I tried and where it stands. The GitHub list updates automatically.}
  }
}

◊section[#:class "work-section"]{
  ◊(section-heading "Selected")
  ◊(selected-work-list #:limit 3)
}

◊section[#:class "work-section"]{
  ◊div[#:class "section-heading-with-note"]{
    ◊(section-heading "From GitHub")
    ◊p{Public repositories update automatically.}
  }
  ◊(github-feed)
  ◊p[#:class "section-after-link"]{
    ◊a[#:href github-profile-url]{All repositories on GitHub}
    ◊span[#:aria-hidden "true"]{→}
  }
}
