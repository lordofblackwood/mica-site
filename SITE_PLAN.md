# Mica site plan

## The outcome

Mica should feel like one personal body of work, not four unrelated mini-sites. It is now a small Racket/Pollen publishing system where essays, fiction, poems, project notes, and automatically discovered GitHub work can live together without making publishing feel like software maintenance.

The author workflow should stay deliberately small:

1. Run one command with a content type and title.
2. Write in the single `.html.pm` file it creates.
3. Change `draft` to `false` when the piece is ready.
4. Run one build command. The indexes and homepage update themselves.

The person behind the site is **Michael Khalil**. Essays and poems are published under the author name **Mica**, which also remains the site’s public brand. Both values are configured rather than repeated throughout templates.

## Repository boundary and starting point

The canonical checkout is the `lordofblackwood/mica-site` repository, deployed as a GitHub Pages project site beneath `/mica-site`. Before integration, its existing modified template and generated HTML were preserved in a complete external safety copy. The rebuild replaces the old source layout deliberately; generated folders such as `compiled/`, `_site/`, and `public/` remain disposable artifacts.

The audited prototype already established Racket, Pollen, a shared template, and a restrained visual direction. The implementation under `src/` keeps that foundation while replacing hard-coded navigation, identity, and indexes with data-driven equivalents.

Implementation, automated checks, and local visual QA are complete. Publishing remains gated on reviewing the public copy and committing the integration intentionally.

## Product principles

1. **The writing is the product.** Navigation and motion should help someone read, not compete for attention.
2. **One piece, one source file.** Adding a poem, fiction piece, or essay must not require editing an index, registry, template, or JSON manifest.
3. **Convention over ceremony.** Predictable folders and a short metadata block are enough to publish.
4. **Personal, not performative.** The site can be polished without sounding like a brand deck.
5. **Handwritten context wins.** Automation may discover a repository, but Michael can override its title, description, visibility, and link.
6. **External data cannot break the site.** GitHub sync uses a checked-in snapshot and a graceful fallback.
7. **Every URL is base-path aware.** The production project site lives below `/mica-site`; local preview lives at `/`.
8. **Generated files are replaceable.** Nothing in `public/` is edited by hand.
9. **Dark is the default, not a dead end.** The dark editorial palette opens first; a persistent, keyboard-accessible control keeps the light paper palette one click away.

## Information architecture

The public structure should stay understandable without a dropdown or taxonomy lesson.

| Destination | Route | Purpose | Source |
| --- | --- | --- | --- |
| Home | `/` | A short introduction, featured work, and the most recent writing/poem/project | Generated from configured copy and content metadata |
| Writing | `/writing/` | Essays and blog-style notes across code, research, faith, math, and life | `src/writing/*.html.pm` |
| Poems | `/poems/` | A quiet archive and dedicated reading layout | `src/poems/*.html.pm` |
| Work | `/work/` | Handwritten case studies plus automatically discovered GitHub repositories and Pages sites | `src/work/*.html.pm` plus the GitHub snapshot |
| About | `/about/` | A concise, factual introduction to Michael Khalil and the Mica writing name | `src/about/index.html.pm` |
| RSS | `/feed.xml` | A feed of published writing and poems | Generated during build |

“Writing” is the public home for both `essay` and `fiction`; it covers the blog and story use cases without forcing a second content system. “Work” is the public home for authored `project` pages and the automatic GitHub feed.

The primary navigation is therefore: **Writing, Poems, Work, About**. GitHub is an external footer/profile link, not a competing top-level section.

## Voice guide

The clearest existing voice cue is “having fun learning and failing.” The site should extend that attitude: curious, direct, technically literate, and honest about unfinished understanding. Essays and poems carry the Mica byline; professional and biographical facts refer to Michael Khalil.

### How it should sound

- Write in the first person when a person is actually speaking.
- Prefer specific verbs and concrete objects over broad claims: “I built a parser” is stronger than “I am passionate about innovation.”
- Let technical and human questions sit beside each other. There is no need to flatten code, theology, poetry, and personal reflection into a single professional persona.
- Use plain sentences, with an occasional short sentence for rhythm. Contractions are welcome.
- Be candid about experiments, mistakes, and ambiguity without turning failure into a performance.
- Describe projects through the question, the making, and what changed—not a list of buzzwords.
- Keep summaries to one useful sentence. They should tell a reader why the piece exists, not advertise it.
- Keep interface labels short: “Read the essay,” “See the work,” “Source,” and “Live site.”

### What to avoid

- Corporate filler such as “leveraging,” “cutting-edge,” “thought leader,” or “results-driven.”
- Invented credentials, outcomes, dates, clients, or biographical facts.
- Generic claims that could belong to any portfolio.
- Explaining a poem before the reader gets to read it.
- Rewriting the language or lineation of a poem to make it match the site’s prose voice.
- Making every unfinished project sound complete.

### Directional examples

These are tone references, not mandatory final copy:

| Generic | More like Mica |
| --- | --- |
| “Research and code” | “Things I built to understand something.” |
| “Tech, theology, math, life” | “Notes on code, faith, math, and whatever refuses to stay in one category.” |
| “View projects” | “See what I’m building.” |
| “Welcome to my portfolio” | “I write poems, build software, and keep notes on what I learn the hard way.” |

### Rewrite boundary

Rewrite navigation, homepage copy, archive introductions, project summaries, calls to action, and About copy with this guide. Preserve poems as authored. Preserve factual meaning in imported essays and case studies, and flag missing biography or project details instead of guessing.

## Technical architecture

Racket is the orchestration layer and Pollen is the document layer. Pollen parses each content file and provides reusable document tags; Racket discovers metadata, validates sources, refreshes external data, and assembles the static output.

The target tree is:

```text
.
├── build.rkt
├── scripts/
│   ├── new-content.rkt
│   ├── sync-github.rkt
│   └── validate-site.rkt
├── src/
│   ├── config/
│   │   └── site.rkt
│   ├── data/
│   │   ├── github-project-overrides.json
│   │   └── github-projects.snapshot.json
│   ├── static/
│   │   ├── css/site.css
│   │   └── js/site.js
│   ├── writing/*.html.pm
│   ├── poems/*.html.pm
│   ├── work/*.html.pm
│   ├── about/index.html.pm
│   ├── now/index.html.pm
│   ├── resume/index.html.pm
│   ├── pollen.rkt
│   └── template.html.p
├── public/                 # generated; never hand-edited
└── .github/workflows/
    └── deploy.yml
```

### Central configuration

`src/config/site.rkt` is the single source of truth for public identity and deployment details. It should own:

- `site-name` (currently `"Mica"`)
- `person-name` (currently `"Michael Khalil"`)
- `writing-author` (currently `"Mica"`)
- site description/tagline
- GitHub username and profile URL
- canonical origin
- deployment base path
- navigation labels and routes
- optional contact/social links

Templates and tag functions must consume these values instead of repeating either identity or assembling URLs themselves.

Local builds use an empty base path. GitHub Actions sets:

```sh
SITE_BASE_PATH=/mica-site
```

`SITE_ORIGIN` remains configurable for the owner’s GitHub Pages domain or a future custom domain. Internal links and assets go through the shared `site-url` helper; canonical URLs go through `canonical-url`.

### One-file content model

Every published item is represented by one Pollen source file. Folder and `kind` decide where it appears:

| Scaffolder kind | Source folder | Metadata `section` | Public collection |
| --- | --- | --- | --- |
| `essay` | `src/writing/` | `writing` | Writing |
| `fiction` | `src/writing/` | `writing` | Writing |
| `poem` | `src/poems/` | `poems` | Poems |
| `project` | `src/work/` | `work` | Work |

Common metadata:

| Field | Required | Meaning |
| --- | --- | --- |
| `title` | Yes | Public title |
| `description` | Yes | One-sentence archive/home summary |
| `section` | Yes | `writing`, `poems`, or `work` |
| `kind` | Yes | `essay`, `fiction`, `poem`, or `project` |
| `author` | Essays/fiction/poems | `Mica`; enforced for all literary writing |
| `provenance` | Published essays/fiction/poems | Must be `verified-user-authored`; new drafts start `unverified` |
| `date` | Yes | ISO date, `YYYY-MM-DD` |
| `tags` | Yes | Comma-separated tokens; use kebab-case for multiword tags |
| `draft` | Yes | `true` keeps it out of published discovery; `false` publishes it |
| `featured` | Yes | `true` makes it eligible for featured placement |

Project pages may also set `project-kind`, `status`, `github-repo`, and `live-url`. The filename is the stable slug; changing it changes the public URL.

Example metadata:

```pollen
#lang pollen

◊define-meta[title]{A Small Useful Title}
◊define-meta[description]{One sentence that says what this piece is doing.}
◊define-meta[section]{writing}
◊define-meta[kind]{essay}
◊define-meta[author]{Mica}
◊define-meta[date]{2026-08-11}
◊define-meta[tags]{code, learning}
◊define-meta[draft]{true}
◊define-meta[featured]{false}
```

Multiword tags use kebab-case so archive filters remain predictable—for example, `creative-coding, Racket, self-worth`. `project-kind` and `status` remain human-readable phrases.

### One-command scaffolder

The stable command contract is:

```sh
racket scripts/new-content.rkt <essay|fiction|poem|project> "Title"
```

The script should:

1. Validate the kind and non-empty title.
2. Create a lowercase, URL-safe slug.
3. Refuse to overwrite a source file that already exists.
4. Choose the correct folder, `section`, and body starter.
5. Fill today’s ISO date and safe metadata defaults (`draft: true`, `featured: false`).
6. Print the exact file it created and the next publish step.

It must not edit any archive or homepage file. Creating a fourth content type later should require adding one mapping, not cloning the whole pipeline.

### Automatic indexes

Index pages are views over metadata, not handwritten lists. Discovery should:

- scan only `.html.pm` content files beneath the three collection folders;
- omit index pages and anything with `draft: true`;
- validate required metadata before rendering;
- sort newest first, with a deterministic title tie-break;
- use `featured` for selected homepage/work placement;
- derive item URLs through the configured base path;
- produce useful empty states when a collection has no published items.

Adding or deleting a content file must update the relevant archive, count, homepage recency, and feed on the next build with no additional edit.

## Automatic GitHub projects and Pages links

The automatic feed is intentionally a build-time import rather than a client-side request. The resulting site remains fast, private-token-free, and readable if GitHub is unavailable.

### Data flow

```text
GitHub public repositories API
        ↓  scripts/sync-github.rkt
normalize + filter + apply overrides
        ↓
src/data/github-projects.snapshot.json
        ↓  build.rkt / Pollen helpers
Work page + homepage recent item
```

`racket scripts/sync-github.rkt` reads the configured GitHub username, fetches public owned repositories, normalizes the result, and atomically replaces the snapshot. `GITHUB_TOKEN` is optional for local use and useful in CI for a higher rate limit. The token must never be written into output or committed.

The importer excludes private, disabled, archived, and forked repositories; the site repository itself; repositories tagged `portfolio-hidden`; and repositories hidden through the override file.

Each normalized record keeps enough data to render without another request: repository name, display title, description, language, topics, update time, source URL, homepage, Pages state/URL, and featured state.

### Link precedence

For the main project destination:

1. An explicit override wins.
2. A repository `homepage` wins when it is a valid URL.
3. If GitHub reports `has_pages`, use the derived GitHub Pages URL.
4. Otherwise, link to the repository.

The source link always points to the repository. For a project repository, the default Pages shape is `https://<user>.github.io/<repo>/`; the special `<user>.github.io` repository uses the domain root.

This makes newly enabled Pages sites appear without hand-editing a project card.

### Handwritten overrides

`src/data/github-project-overrides.json` is the small, versioned editorial layer. It uses repository names as keys and may override fields such as `title`, `description`, `featured`, `hidden`, and `pages_url`:

```json
{
  "schema_version": 1,
  "projects": {
    "example-repository": {
      "featured": true,
      "description": "What I was trying to understand by building this.",
      "pages_url": "https://example.invalid/demo/"
    }
  }
}
```

Override fields beat normalized API fields. Results sort featured first, then repositories with Pages sites, then most recently updated.

Authored files in `src/work/` remain the place for a full case study. The GitHub feed is the broad automatic inventory. If a repository has both, the authored page should be presented as the richer “case study” while source/live links still come from normalized data where useful.

### Failure and refresh behavior

- The snapshot is versioned and must be valid JSON.
- A failed fetch leaves an existing valid snapshot untouched and the build continues with it.
- If no valid snapshot exists, the Work page renders an honest empty state plus the configured GitHub profile link.
- A scheduled GitHub Actions build refreshes the API data before rendering, so a new public repository or newly enabled Pages site appears without a source edit.
- `workflow_dispatch` provides a “refresh now” button.
- The checked-in daily schedule runs at 09:37 UTC; manual and `portfolio-refresh` dispatches are also supported.

The deployment workflow runs on pushes to `main`, on the schedule, manually, and through `portfolio-refresh`. It installs Racket/Pollen, runs the GitHub sync, validates the site, builds `public/` with `SITE_BASE_PATH=/mica-site`, uploads that directory as the Pages artifact, and deploys it. A sync failure uses the checked-in snapshot rather than failing an otherwise valid site build.

## Build contract

`racket build.rkt` is the one production build entry point. It should:

1. Validate configuration, source metadata, internal source references, override JSON, and snapshot JSON.
2. Render Pollen sources under `src/`.
3. copy only rendered pages and intentional static assets into a clean `public/` directory;
4. generate collection indexes, RSS, and the sitemap;
5. preserve no stale page from a deleted source;
6. print an actionable summary and exit non-zero on an invalid source.

`scripts/validate-site.rkt` remains callable independently for faster diagnostics. The validator should report a source path and field name, never a bare “build failed.”

`public/` is the only deployment artifact. `compiled/`, `_site/`, and `public/` stay ignored.

## Delivery phases and acceptance criteria

### Phase 0 — Establish the safe repository boundary

Inventory the original prototype, confirm the canonical checkout and Pages deployment, and preserve local changes before integration.

Acceptance criteria:

- The intended Git repository root is explicitly confirmed before commits or deployment.
- Existing local changes are preserved in a recoverable safety copy before replacement.
- Original source/content is either preserved in place or deliberately migrated with a traceable mapping.
- Generated caches are excluded from future commits.

### Phase 1 — Consolidate the Racket/Pollen foundation

Move runtime sources under `src/`, centralize identity/URLs, establish one template and shared design tokens, and make `build.rkt` produce `public/`.

Acceptance criteria:

- Changing `site-name` in `src/config/site.rkt` changes the visible brand, title metadata, footer, and accessible home label without another edit.
- A local build uses root-relative local URLs; a build with `SITE_BASE_PATH=/mica-site` prefixes every internal page, asset, and canonical route correctly.
- No generated file needs manual editing.
- A second consecutive clean build produces the same file set.

### Phase 2 — Make publishing boring

Finish the one-file schema, scaffolder, validator, discovery helpers, and generated collection/home indexes.

Acceptance criteria:

- Each of the three documented scaffolder invocations creates the correct source file with valid metadata and does not overwrite an existing file.
- A draft is absent from production indexes; changing only `draft` to `false` makes it appear.
- Adding a published file updates its archive and the homepage without touching an index.
- Invalid dates, missing titles/descriptions, wrong sections, duplicate output paths, and invalid booleans produce actionable validation errors.
- Poem line and stanza structure survives rendering.

### Phase 3 — Rewrite and shape the reading experience

Apply the voice guide to homepage, navigation support copy, archive introductions, calls to action, project summaries, and About. Give poems, essays, and project case studies layouts suited to their content while keeping one visual system.

Acceptance criteria:

- No generic placeholder copy remains.
- No biography, result, or credential has been invented.
- Poems retain their authored language and lineation.
- Every page has one clear `h1`, visible keyboard focus, useful link text, adequate contrast, and a sensible narrow-screen layout.
- Motion respects `prefers-reduced-motion` and the site remains usable without JavaScript.

### Phase 4 — Add resilient GitHub discovery

Implement the importer, tracked snapshot, editorial overrides, automatic Work feed, and refresh schedule.

Acceptance criteria:

- Running `racket scripts/sync-github.rkt` creates valid normalized JSON atomically.
- Forks, archived/disabled repositories, the site repository, `portfolio-hidden` repositories, and hidden overrides do not render.
- A valid homepage is preferred, then a derived Pages URL, then the repository URL.
- An override can rename, describe, feature, hide, or relink a repository without changing sync code.
- Simulated network/API failure preserves and renders the last valid snapshot.
- A new public repository appears after a scheduled or manual workflow run without editing a Pollen page.

### Phase 5 — Validate and deploy

Exercise the complete author-to-Pages path and make the GitHub Action the reproducible deployment route.

Acceptance criteria:

- From a clean checkout, documented dependency installation plus `racket build.rkt` creates `public/`.
- Validation, build, and deployment run in CI on `main`; scheduled/manual runs also refresh GitHub data.
- The deployed site works beneath `/mica-site`, including nested-page navigation, CSS, JavaScript, canonical URLs, and external links.
- There are no broken internal links, missing intentional assets, accidental draft pages, or horizontal overflow at common phone widths.
- Core pages are keyboard-navigable and pass an automated accessibility smoke check without serious violations.

## Final launch checklist

- Reconfirm the GitHub owner, repository name, default branch, and Pages origin before changing deployment settings or adding a custom domain.
- Confirm the Michael Khalil biography, Mica byline, final tagline, contact links, and which imported pieces are ready to publish.
- Review every migrated piece for voice and factual accuracy.
- Review GitHub exclusions and overrides; do not assume every public repository belongs in a portfolio.
- Commit a known-good GitHub snapshot before the first deployment.
- Run the validator and a clean production build at `/mica-site`.
- Preview `public/` at desktop and mobile widths, with JavaScript disabled and reduced motion enabled.
- Keep Pages configured to deploy through GitHub Actions.

## Definition of done

The site is done when Michael can publish an essay, fiction piece, poem, or project from one new source file; archives and homepage update automatically; public GitHub work refreshes on a schedule with correct Pages links; a network failure does not break the build; identity and base paths are configured once; and the deployed site still sounds like a person rather than a portfolio generator.
