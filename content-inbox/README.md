# Private writing inbox

`content-inbox/private/` is a local, gitignored review area for recovered writing that is sensitive, incomplete, ambiguously authored, or still needs transcription checks. Nothing in that directory is built, deployed, or committed.

The public repository intentionally contains no literary bodies until Michael selects and commits them himself.

To publish a reviewed piece:

1. Create its public source file:

   ```sh
   racket scripts/new-content.rkt fiction "Title"
   racket scripts/new-content.rkt essay "Title"
   racket scripts/new-content.rkt poem "Title"
   ```

2. Copy only the approved text into the new file.
3. Compare the public source line-for-line with Michael's original.
4. Keep `author` as `Mica` and change `provenance` from `unverified` to `verified-user-authored`.
5. Change `draft` from `true` to `false`.
6. Run `racket build.rkt` and review the result before committing.

Every published work is one file. Edit that file to revise it, change `draft` back to `true` to remove it from the generated site, or delete the file to remove the work entirely on the next build. A committed draft remains readable in this public GitHub repository, so do not move sensitive text out of the private inbox merely to hide it with `draft: true`.
