#lang pollen

◊define-meta[title]{Poetry Reset}
◊define-meta[description]{A local-first, installable writing practice for redirecting difficult moments into short, concrete language.}
◊define-meta[section]{work}
◊define-meta[kind]{tool}
◊define-meta[date]{2026-08-11}
◊define-meta[tags]{poetry, creative-coding, local-first, PWA}
◊define-meta[draft]{false}
◊define-meta[featured]{false}
◊define-meta[canonical-path]{tools/poetry-reset/}
◊define-meta[manifest]{tools/poetry-reset/manifest.webmanifest}
◊define-meta[asset-root]{tools/poetry-reset/}

◊(define (html-select #:id id #:class class-name #:data-pr-field field . elements)
   `(select ((id ,id) (class ,class-name) (data-pr-field ,field)) ,@elements))

◊section[#:class "poetry-reset" #:data-poetry-reset "true"]{
  ◊header[#:class "poetry-reset__masthead"]{
    ◊div[#:class "poetry-reset__masthead-copy"]{
      ◊h1{Poetry Reset}
      ◊p[#:class "poetry-reset__tagline"]{Turn the next three minutes into language.}
      ◊p[#:class "poetry-reset__privacy-line"]{Drafts are stored on this device.}
    }
    ◊div[#:class "poetry-reset__masthead-controls"]{
      ◊button[#:type "button"
              #:class "poetry-reset__button poetry-reset__button--install"
              #:data-pr-action "install"]{Install app}
      ◊p[#:class "poetry-reset__model-badge"
         #:data-pr-output "llm-badge"
         #:role "status"]{Local model not loaded}
    }
  }

  ◊section[#:class "poetry-reset__stats" #:aria-label "Writing progress"]{
    ◊dl[#:class "poetry-reset__stat"]{
      ◊dt[#:class "poetry-reset__sr-only"]{Current day}
      ◊dd[#:data-pr-stat "day"]{Day 01 / 260}
    }
    ◊dl[#:class "poetry-reset__stat"]{
      ◊dt[#:class "poetry-reset__sr-only"]{Current streak}
      ◊dd[#:data-pr-stat "streak"]{0 day streak}
    }
    ◊dl[#:class "poetry-reset__stat"]{
      ◊dt[#:class "poetry-reset__sr-only"]{Completed sessions}
      ◊dd[#:data-pr-stat "sessions"]{0 sessions}
    }
    ◊dl[#:class "poetry-reset__stat"]{
      ◊dt[#:class "poetry-reset__sr-only"]{Words written}
      ◊dd[#:data-pr-stat "words"]{0 words}
    }
  }

  ◊section[#:class "poetry-reset__rescue" #:aria-labelledby "poetry-reset-rescue-heading"]{
    ◊h2[#:id "poetry-reset-rescue-heading"]{Rescue}
    ◊div[#:class "poetry-reset__rescue-controls"]{
      ◊button[#:type "button"
              #:class "poetry-reset__button poetry-reset__button--emergency"
              #:data-pr-action "emergency"]{Emergency prompt}
      ◊button[#:type "button"
              #:class "poetry-reset__button"
              #:data-pr-action "urge-surf"]{Urge surf}
      ◊button[#:type "button"
              #:class "poetry-reset__button"
              #:data-pr-action "ground"]{Ground me}
    }
    ◊p[#:class "poetry-reset__care-note"]{Creative support, not emergency care.}
  }

  ◊div[#:class "poetry-reset__workspace"]{
    ◊section[#:class "poetry-reset__writing" #:aria-labelledby "poetry-reset-prompt"]{
      ◊fieldset[#:class "poetry-reset__mood"]{
        ◊legend{Mood}
        ◊div[#:class "poetry-reset__mood-options" #:data-pr-moods "true"]{
          ◊button[#:type "button" #:class "poetry-reset__mood-button" #:data-pr-mood "calm" #:aria-pressed "false"]{Calm}
          ◊button[#:type "button" #:class "poetry-reset__mood-button" #:data-pr-mood "intense" #:aria-pressed "false"]{Intense}
          ◊button[#:type "button" #:class "poetry-reset__mood-button" #:data-pr-mood "identity" #:aria-pressed "true"]{Identity}
          ◊button[#:type "button" #:class "poetry-reset__mood-button" #:data-pr-mood "emergency" #:aria-pressed "false"]{Emergency}
        }
      }

      ◊p[#:class "poetry-reset__prompt-meta"]{
        ◊span[#:data-pr-output "week"]{Day 01}
        ◊span[#:aria-hidden "true"]{ · }
        ◊span[#:data-pr-output "phase"]{Interruption}
        ◊span[#:aria-hidden "true"]{ · }
        ◊span[#:data-pr-output "mode"]{Identity}
      }
      ◊h2[#:id "poetry-reset-prompt" #:class "poetry-reset__prompt" #:data-pr-output "prompt"]{
        Someone asks you, very gently, ‘When did you start believing you were the one who would always be left behind?’
      }

      ◊div[#:class "poetry-reset__prompt-notes"]{
        ◊section[#:aria-labelledby "poetry-reset-why-heading"]{
          ◊h3[#:id "poetry-reset-why-heading"]{Why it works}
          ◊p[#:data-pr-output "why"]{Concrete detail moves the loop from explanation into craft.}
        }
        ◊section[#:aria-labelledby "poetry-reset-followup-heading"]{
          ◊h3[#:id "poetry-reset-followup-heading"]{Follow-up}
          ◊p[#:data-pr-output "followup"]{Rewrite the final line so it contains the smallest possible amount of hope.}
        }
      }

      ◊div[#:class "poetry-reset__prompt-controls"]{
        ◊button[#:type "button"
                #:class "poetry-reset__button poetry-reset__button--emergency"
                #:data-pr-action "emergency"]{Emergency prompt}
        ◊button[#:type "button"
                #:class "poetry-reset__button"
                #:data-pr-action "generate"]{Generate local prompt}
        ◊button[#:type "button"
                #:class "poetry-reset__button"
                #:data-pr-action "new-prompt"]{New prompt}
        ◊button[#:type "button"
                #:class "poetry-reset__button"
                #:data-pr-action "copy"]{Copy}
      }

      ◊label[#:class "poetry-reset__sr-only" #:for "poetry-reset-writing"]{Your writing}
      ◊textarea[#:id "poetry-reset-writing"
               #:class "poetry-reset__textarea"
               #:data-pr-field "writing"
               #:placeholder "Begin before you feel ready."
               #:maxlength "50000"
               #:autocomplete "off"
               #:spellcheck "true"
               #:aria-describedby "poetry-reset-save-status"]{}
      ◊div[#:class "poetry-reset__draft-meta"]{
      ◊p[#:id "poetry-reset-save-status" #:data-pr-save-status "true"]{Local saved}
        ◊p[#:data-pr-draft-words "true"]{0 words}
      }

      ◊div[#:class "poetry-reset__timer-controls"]{
        ◊fieldset[#:class "poetry-reset__timer-presets"]{
          ◊legend{Time}
          ◊button[#:type "button" #:class "poetry-reset__timer-button" #:data-pr-action "timer-1" #:aria-pressed "true"]{1 min}
          ◊button[#:type "button" #:class "poetry-reset__timer-button" #:data-pr-action "timer-2" #:aria-pressed "false"]{2 min}
          ◊button[#:type "button" #:class "poetry-reset__timer-button" #:data-pr-action "timer-3" #:aria-pressed "false"]{3 min}
        }
        ◊div[#:class "poetry-reset__timer-readout"]{
          ◊output[#:data-pr-output "timer" #:aria-live "off"]{01:00}
          ◊span[#:data-pr-timer-state "true"]{ready}
        }
        ◊button[#:type "button"
                #:class "poetry-reset__button poetry-reset__button--quiet"
                #:data-pr-action "timer-stop"]{Reset}
        ◊div[#:class "poetry-reset__session-actions"]{
          ◊button[#:type "button"
                  #:class "poetry-reset__button"
                  #:data-pr-action "save-draft"]{Save draft}
          ◊button[#:type "button"
                  #:class "poetry-reset__button poetry-reset__button--emergency"
                  #:data-pr-action "complete"]{Complete session}
        }
      }
    }

    ◊aside[#:class "poetry-reset__model" #:aria-labelledby "poetry-reset-model-heading"]{
      ◊h2[#:id "poetry-reset-model-heading"]{Local model}
      ◊p{No account or API key. The first load downloads a model; generation then runs in this browser.}

      ◊label[#:for "poetry-reset-model"]{Choose a local model}
      ◊html-select[#:id "poetry-reset-model"
                   #:class "poetry-reset__select"
                   #:data-pr-field "model"]{
        ◊option[#:value "Llama-3.2-1B-Instruct-q4f16_1-MLC"]{Llama 3.2 1B · lighter}
        ◊option[#:value "Phi-3.5-mini-instruct-q4f16_1-MLC-1k"]{Phi 3.5 mini · stronger}
      }
      ◊button[#:type "button"
              #:class "poetry-reset__button poetry-reset__button--model"
              #:data-pr-action "load-model"]{Load local model}

      ◊div[#:class "poetry-reset__model-progress"]{
        ◊output[#:data-pr-model-percent "true"]{0%}
        ◊progress[#:data-pr-model-progress "true"
                  #:aria-label "Local model download progress"
                  #:max "100"
                  #:value "0"]{0%}
      }
      ◊p[#:class "poetry-reset__model-status"
         #:data-pr-output "model-status"
         #:aria-live "off"]{WebGPU check pending}

      ◊p[#:class "poetry-reset__model-link"]{
        ◊a[#:href "#starter-system-prompt"]{Starter system prompt}
      }
      ◊details[#:class "poetry-reset__privacy-details"]{
        ◊summary{How local privacy works}
        ◊p{Built-in prompts do not load model code. If you choose the optional model, this page imports a pinned WebLLM module from esm.run and downloads public model files; generation is designed to run in your browser, and loading it means trusting that provider. Drafts, progress, and prompt history otherwise remain in this browser unless you export them.}
      }
    }
  }

  ◊div[#:class "poetry-reset__progress-layout"]{
    ◊section[#:class "poetry-reset__progression" #:aria-labelledby "poetry-reset-progression-heading"]{
      ◊h2[#:id "poetry-reset-progression-heading"]{Progression map}
      ◊p{260 days, from interruption to mastery.}
      ◊ol[#:class "poetry-reset__phase-legend"]{
        ◊li[#:data-pr-phase "interruption"]{◊span{1–30}◊span{Interruption}}
        ◊li[#:data-pr-phase "emotional-precision"]{◊span{31–70}◊span{Emotional precision}}
        ◊li[#:data-pr-phase "identity-reconstruction"]{◊span{71–120}◊span{Identity reconstruction}}
        ◊li[#:data-pr-phase "power-boundaries"]{◊span{121–180}◊span{Power and boundaries}}
        ◊li[#:data-pr-phase "transformation"]{◊span{181–230}◊span{Transformation}}
        ◊li[#:data-pr-phase "mastery"]{◊span{231–260}◊span{Mastery}}
      }
      ◊div[#:class "poetry-reset__map"
          #:data-pr-map "true"
          #:role "group"
          #:aria-label "260-day writing progression"]{
        ◊p[#:class "poetry-reset__map-loading"]{Loading your 260-day map…}
      }
      ◊p[#:class "poetry-reset__map-note"]{Choose a day to revisit its prompt and draft.}
    }

    ◊aside[#:class "poetry-reset__intervention" #:aria-labelledby "poetry-reset-intervention-heading"]{
      ◊h2[#:id "poetry-reset-intervention-heading"]{Interventions}
      ◊h3{Urge surf}
      ◊div[#:class "poetry-reset__intervention-copy"
          #:data-pr-output "intervention"
          #:role "status"
          #:aria-live "polite"]{
        ◊p{For 90 seconds, do not argue with the urge.}
        ◊p{Notice where it lives in the body.}
        ◊p{Give it shape, temperature, and movement.}
        ◊p{Say: ‘This rises. This peaks. This passes.’}
        ◊p{Then write one sentence that starts with ‘It moves like…’}
      }
      ◊div[#:class "poetry-reset__breath"
          #:data-pr-breath "true"
          #:aria-label "Ninety-second urge-surf breathing timer"]{
        ◊span[#:class "poetry-reset__breath-circle" #:data-pr-output "breath-label"]{Exhale}
        ◊output[#:data-pr-breath-timer "true"]{90 sec}
      }
    }
  }

  ◊div[#:class "poetry-reset__records-layout"]{
    ◊section[#:class "poetry-reset__history" #:aria-labelledby "poetry-reset-history-heading"]{
      ◊div[#:class "poetry-reset__section-heading"]{
        ◊h2[#:id "poetry-reset-history-heading"]{Writing history}
        ◊div[#:class "poetry-reset__import-export"]{
          ◊button[#:type "button" #:class "poetry-reset__button" #:data-pr-action "export-data"]{Export data}
          ◊button[#:type "button" #:class "poetry-reset__button" #:data-pr-action "import-data"]{Import data}
          ◊button[#:type "button" #:class "poetry-reset__button" #:data-pr-action "export-text"]{Export writings}
          ◊input[#:id "poetry-reset-import"
                #:data-pr-field "import-file"
                #:type "file"
                #:accept "application/json"
                #:hidden "hidden"]{}
        }
      }
      ◊div[#:class "poetry-reset__history-list"
          #:data-pr-history "true"
          #:aria-label "Saved writing history"]{
        ◊p{No saved writings yet.}
        ◊p{Save a draft or complete a day to keep your work.}
      }
    }

    ◊section[#:class "poetry-reset__settings" #:aria-labelledby "poetry-reset-settings-heading"]{
      ◊h2[#:id "poetry-reset-settings-heading"]{Settings}
      ◊div[#:class "poetry-reset__setting"]{
        ◊label[#:for "poetry-reset-target"]{Daily target}
        ◊html-select[#:id "poetry-reset-target"
                     #:class "poetry-reset__select"
                     #:data-pr-field "target-minutes"]{
          ◊option[#:value "1"]{1 min}
          ◊option[#:value "2"]{2 min}
          ◊option[#:value "3"]{3 min}
        }
      }
      ◊div[#:class "poetry-reset__setting"]{
        ◊label[#:for "poetry-reset-sound"]{Sound}
        ◊html-select[#:id "poetry-reset-sound"
                     #:class "poetry-reset__select"
                     #:data-pr-field "sound"]{
          ◊option[#:value "on"]{on}
          ◊option[#:value "off"]{off}
        }
      }

      ◊details[#:id "starter-system-prompt" #:class "poetry-reset__system-prompt"]{
        ◊summary{Starter system prompt}
        ◊label[#:class "poetry-reset__sr-only" #:for "poetry-reset-system-prompt"]{Local model system prompt}
        ◊textarea[#:id "poetry-reset-system-prompt"
                 #:class "poetry-reset__textarea poetry-reset__textarea--system"
                 #:data-pr-field "system-prompt"
                 #:spellcheck "true"]{You are a trauma-informed poetry coach, behavioral redirection designer, and master writing teacher.

Generate exactly one short writing prompt for a 1–3 minute session.

The prompt must:
- interrupt compulsive loops without shaming the writer
- build a strong positive self-identity
- use one precise writing constraint
- be emotionally gripping within five seconds
- avoid generic advice
- avoid telling the user they are broken
- avoid clinical claims, diagnosis, or crisis counseling
- be safe: no self-harm instructions, no spiraling, no revenge fantasies
- include one follow-up that stabilizes or strengthens the writer after the intense moment

Return JSON only:
{
  "prompt": "...",
  "why": "One sentence explaining the writing or attention mechanism.",
  "followup": "One short follow-up prompt.",
  "mode": "calm|intense|identity|emergency"
}}
        ◊button[#:type "button"
                #:class "poetry-reset__button"
                #:data-pr-action "reset-system"]{Reset starter prompt}
      }

      ◊div[#:class "poetry-reset__reset-controls"]{
        ◊button[#:type "button"
                #:class "poetry-reset__button"
                #:data-pr-action "reset-streak"]{Reset streak only}
        ◊button[#:type "button"
                #:class "poetry-reset__button poetry-reset__button--emergency"
                #:data-pr-action "reset-all"]{Reset everything}
      }
      ◊p[#:class "poetry-reset__reset-note"]{Missing a day is information, not failure.}
      ◊p[#:class "poetry-reset__storage-note"]{Stored only in this browser unless you export it.}
    }
  }

  ◊p[#:class "poetry-reset__sr-only"
     #:data-pr-announcement "true"
     #:role "status"
     #:aria-live "polite"
     #:aria-atomic "true"]{}
}

◊noscript{
  ◊p[#:class "poetry-reset__noscript"]{Poetry Reset needs JavaScript for local saving, timers, progression, and optional local-model generation. Your browser can still display the starter prompt above.}
}

◊script[#:defer "defer" #:src (site-url "tools/poetry-reset/poetry-reset.js")]{}
