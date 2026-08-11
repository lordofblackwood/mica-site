◊(local-require pollen/template pollen/core "pollen.rkt")
◊(define page-title (or (select 'title metas) site-name))
◊(define page-description (or (select 'description metas) site-description))
◊(define page-section (or (select 'section metas) "home"))
◊(define page-kind (or (select 'kind metas) "page"))
◊(define page-author (or (select 'author metas) (author-for-kind page-kind)))
◊(define page-path (or (select 'canonical-path metas) (symbol->string here)))
◊(define page-manifest (select 'manifest metas))
◊(define page-asset-root (select 'asset-root metas))
◊(define (page-asset shared-path scoped-name)
   (site-url
    (if page-asset-root
        (string-append page-asset-root scoped-name)
        shared-path)))

<!doctype html>
<html lang="en" data-section="◊|page-section|" data-kind="◊|page-kind|" data-theme="dark">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="◊|page-description|">
  <meta name="author" content="◊|page-author|">
  <meta name="color-scheme" content="dark light">
  <meta name="theme-color" content="#121416" data-theme-color>
  <script>
    (() => {
      const root = document.documentElement;
      let theme = "dark";

      try {
        const savedTheme = localStorage.getItem("mica-theme");
        if (savedTheme === "dark" || savedTheme === "light") theme = savedTheme;
      } catch (_) {
        // Storage can be unavailable in strict privacy contexts. Dark remains
        // the deliberately chosen, fully functional default.
      }

      root.dataset.theme = theme;
      const themeColor = document.querySelector("[data-theme-color]");
      if (themeColor) themeColor.content = theme === "dark" ? "#121416" : "#f6f1e7";
    })();
  </script>
  <meta property="og:type" content="website">
  <meta property="og:title" content="◊|page-title| · ◊|site-name|">
  <meta property="og:description" content="◊|page-description|">
  <meta property="og:url" content="◊(canonical-url page-path)">
  <title>◊|page-title| · ◊|site-name|</title>
  <link rel="canonical" href="◊(canonical-url page-path)">
  <link rel="alternate" type="application/rss+xml" title="◊|site-name| — Writing and poems" href="◊(site-url "feed.xml")">
  ◊(if page-manifest
         (->html `(link ((rel "manifest")
                         (href ,(site-url page-manifest)))))
         "")
  <link rel="stylesheet" href="◊(page-asset "static/css/site.css" "site.css")">
  <script defer src="◊(page-asset "static/js/site.js" "site.js")"></script>
</head>
<body>
  <a class="skip-link" href="#main-content">Skip to content</a>
  ◊(->html (site-header page-section))
  <main id="main-content" class="site-main">
    ◊(->html doc)
    ◊(if (literary-kind? page-kind)
         (->html (collection-pagination page-path))
         "")
  </main>
  ◊(->html (site-footer))
</body>
</html>
