#lang pollen

◊define-meta[title]{SQL Parser and Query Rewriter}
◊define-meta[description]{Utilities for transforming SQL SELECT queries while respecting nested queries, CTEs, and clause order.}
◊define-meta[section]{work}
◊define-meta[kind]{project}
◊define-meta[date]{2026-05-09}
◊define-meta[tags]{SQL, parsers, software}
◊define-meta[draft]{false}
◊define-meta[featured]{false}
◊define-meta[project-kind]{software engineering}
◊define-meta[status]{engineering utility}

◊content-header[#:back-href "/work/" #:back-label "Work"]{SQL Parser and Query Rewriter}

◊project-meta[#:status "engineering utility" #:kind "software engineering"]

◊lede{A set of utilities for parsing and transforming SQL SELECT queries without confusing final clauses with the ones inside CTEs or subqueries.}

◊p{The project focuses on controlled query transformations: inserting or adjusting TOP clauses, locating the final top-level SELECT, adding filters, sorting, and paging, and avoiding accidental edits inside nested queries.}

◊section-title{The hard parts}

◊ul{
  ◊li{Finding the top-level SELECT when CTEs and subqueries are present.}
  ◊li{Distinguishing final query clauses from nested clauses.}
  ◊li{Preserving SQL meaning while editing strings or parse trees.}
  ◊li{Testing interactions among DISTINCT, ALL, TOP, ORDER BY, OFFSET, and FETCH.}
}

◊section-title{Why it matters}

◊p{This is the kind of engineering problem where correctness hides in edge cases. Making the common case work is only the beginning; the transformation has to remain predictable when the query becomes complicated.}
