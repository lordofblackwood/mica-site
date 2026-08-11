#lang pollen

◊define-meta[title]{Poetry Reset}
◊define-meta[description]{A local-first, installable poetry practice that turns difficult moments into short writing sessions and a 260-day progression.}
◊define-meta[section]{work}
◊define-meta[kind]{project}
◊define-meta[date]{2026-08-11}
◊define-meta[tags]{poetry, creative-coding, local-first, PWA}
◊define-meta[draft]{false}
◊define-meta[featured]{true}
◊define-meta[featured-order]{0}
◊define-meta[project-kind]{local-first writing tool}
◊define-meta[status]{active experiment}
◊define-meta[github-repo]{https://github.com/lordofblackwood/mica-site}

◊content-header[#:back-href "/work/" #:back-label "Work"]{Poetry Reset}

◊project-meta[#:repo "https://github.com/lordofblackwood/mica-site"
             #:live (site-url "tools/poetry-reset/")
             #:status "active experiment"
             #:kind "local-first writing tool"]

◊lede{Poetry Reset turns the next one to three minutes into language: a private, installable writing practice built for interruption, emotional precision, and artistic growth.}

◊p{
  ◊a[#:class "action-link action-link--primary"
     #:href (site-url "tools/poetry-reset/")]{Open Poetry Reset}
}

◊section-title{What it does}

◊p{The tool pairs short emergency prompts with a focused writing surface, one-to-three-minute timers, gentle draft saving, and a 260-day progression from interruption to mastery. Urge-surf and grounding interventions make the next moment smaller; writing history makes completed work visible without turning a missed day into failure.}

◊section-title{Local by design}

◊p{Drafts, settings, streaks, progression, and writing history stay in the browser unless the writer chooses to export them. An optional browser-based language model can generate prompts without an account or API key after its public model files have downloaded. The built-in prompt library remains available when WebGPU or the local model is not.}

◊section-title{Why I built it}

◊p{Poetry Reset treats creative practice as a way to interrupt a loop without pretending that art is emergency care. The goal is modest and concrete: stay with one honest sentence long enough to turn intensity into craft, then return tomorrow with evidence that you showed up.}

◊note{
  ◊p{Poetry Reset is a creative support tool, not crisis counseling or medical care. If a situation is immediately dangerous, contact local emergency services or a crisis line.}
}
