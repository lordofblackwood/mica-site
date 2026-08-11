# Mica

A personal publishing site for essays, fiction, poems, project notes, and GitHub work, built with Racket and Pollen.

## Status

The rebuild is implemented in the canonical `lordofblackwood/mica-site` repository: centralized site configuration, one-file content publishing, generated archives and homepage sections, resilient GitHub discovery, RSS/sitemap output, validation, compatibility redirects, and a scheduled GitHub Pages workflow. See [SITE_PLAN.md](SITE_PLAN.md) for the decisions and launch checklist.

Current authoring source lives under `src/`; `racket build.rkt` is the supported build path. `public/` and Pollen caches are generated and ignored.

## Setup

CI targets Racket 8.14. Install Pollen once:

```sh
raco pkg install --auto pollen
```

Public identity, navigation, GitHub username, origin, and URL behavior live in `src/config/site.rkt`. `person-name` is `Michael Khalil`; `writing-author` and the site brand are `Mica`. Change those values there rather than in templates.

The visual theme defaults to dark. The header toggle switches to the original light paper theme and remembers the visitor’s choice in local browser storage; both themes use the same content and layout.

## Add something

No essay, fiction, or poem body is currently tracked in this public repository. Michael keeps undecided work in the local, gitignored `content-inbox/private/` folder and will choose what to add and commit himself.

Use the scaffolder and edit the path it prints:

```sh
racket scripts/new-content.rkt essay "What I Learned Building This"
racket scripts/new-content.rkt fiction "A Small Story"
racket scripts/new-content.rkt poem "After the Rain"
racket scripts/new-content.rkt project "Small Useful Tool"
```

The mapping is:

- `essay` → `src/writing/<slug>.html.pm` → Writing
- `fiction` → `src/writing/<slug>.html.pm` → Writing
- `poem` → `src/poems/<slug>.html.pm` → Poems
- `project` → `src/work/<slug>.html.pm` → Work

Each item is one Pollen file. Its metadata controls every archive and homepage placement:

```pollen
◊define-meta[title]{What I Learned Building This}
◊define-meta[description]{One useful sentence about the piece.}
◊define-meta[section]{writing}
◊define-meta[kind]{essay}
◊define-meta[author]{Mica}
◊define-meta[provenance]{verified-user-authored}
◊define-meta[date]{2026-08-11}
◊define-meta[tags]{code, learning}
◊define-meta[draft]{true}
◊define-meta[featured]{false}
◊define-meta[featured-order]{999}
```

New files start as drafts. Essays, fiction, and poems are scaffolded with `author: Mica` and `provenance: unverified`. The build refuses to publish literary work until its text has been checked against Michael's source and provenance is changed to `verified-user-authored`; then set `draft` to `false`. Tags are comma-separated; use kebab-case for multiword tags, such as `creative-coding, Racket, self-worth`. A lower `featured-order` moves a featured item earlier in selected-work placements. Do not edit an archive or homepage list; the build discovers metadata automatically. Project files may also use `project-kind`, `status`, `github-repo`, and `live-url`.

To revise a published piece, edit its one source file. To unpublish it without losing the source, set `draft` to `true`; to remove it entirely, delete the source file and rebuild. The build recreates `public/`, so stale generated pages disappear automatically. Remember that this GitHub repository is public: a committed draft is hidden from the site but not from repository history. Sensitive or uncertain recovered work belongs in the gitignored `content-inbox/private/` area described in `content-inbox/README.md` until it is approved.

## Preview and build

Build the whole site into `public/`:

```sh
racket build.rkt
```

Local builds default to the domain root. Preview the built output:

```sh
python3 -m http.server 8000 --directory public
```

Then open [http://localhost:8000](http://localhost:8000).

`public/` is generated and can be replaced at any time. Never author content there.

Run the automated checks directly with:

```sh
raco test tests/site-core-test.rkt tests/github-sync-test.rkt
```

To exercise the GitHub Pages project path locally or in CI:

```sh
SITE_BASE_PATH=/mica-site racket build.rkt
```

`SITE_ORIGIN` is optional and controls canonical URLs. The checked-in GitHub Action sets `SITE_BASE_PATH=/mica-site`; a custom-domain deployment would normally use an empty base path.

## Refresh GitHub work

Refresh the tracked project snapshot, then rebuild:

```sh
racket scripts/sync-github.rkt
racket build.rkt
```

The sync imports public, owned repositories for the username in `src/config/site.rkt`. An optional `GITHUB_TOKEN` raises API limits. If GitHub is unavailable, the existing valid `src/data/github-projects.snapshot.json` remains in use.

Edit `src/data/github-project-overrides.json` to feature, hide, rename, redescribe, or relink a repository. For a project’s main link, an override wins, followed by the repository homepage, a derived GitHub Pages URL, and finally the source repository. The Pages workflow refreshes every day at 09:37 UTC, on manual runs, and on a `portfolio-refresh` repository dispatch, so newly added repositories and Pages sites appear without editing site content.

## Useful paths

```text
src/config/site.rkt                     identity, GitHub repository, navigation, URLs
src/writing/*.html.pm                   essays, fiction, and blog-style notes
src/poems/*.html.pm                     poems
content-inbox/README.md                 private review and publication workflow
src/work/*.html.pm                      handwritten project pages
src/now/index.html.pm                   current-focus page
src/resume/index.html.pm                narrative résumé page
src/data/github-project-overrides.json  editorial GitHub settings
src/data/github-projects.snapshot.json  last known good GitHub data
scripts/new-content.rkt                 one-command scaffolder
scripts/sync-github.rkt                 GitHub importer
scripts/validate-site.rkt               generated-page and link checks
build.rkt                               metadata validation and full build
public/                                 generated deployment artifact
```

The implementation and launch checklist are in [SITE_PLAN.md](SITE_PLAN.md).
