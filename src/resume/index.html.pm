#lang pollen

◊define-meta[title]{Résumé}
◊define-meta[description]{A narrative résumé and professional overview for Michael Khalil.}
◊define-meta[section]{about}
◊define-meta[kind]{page}
◊define-meta[date]{2026-08-11}
◊define-meta[tags]{software, applied-mathematics, machine-learning}
◊define-meta[draft]{false}
◊define-meta[featured]{false}

◊content-header[#:back-href "/about/" #:back-label "About"]{Résumé}

◊lede{I am a software engineer with a strong computer-science and applied-mathematics background, focused on reliable systems, machine-learning workflows, data products, and tools that turn ambiguous problems into structured solutions.}

◊note{◊p{This is the narrative version of my résumé. A downloadable PDF can be added when it is ready.}}

◊section-title{Professional direction}

◊p{I am building toward senior- and principal-level software-engineering work in AI and ML, data products, developer tools, or mathematically informed systems. I am strongest when a problem requires both implementation skill and conceptual structure: designing the architecture, clarifying the domain, testing edge cases, and building something people can actually use.}

◊section-title{Core strengths}

◊ul{
  ◊li{Python, Racket, TypeScript, Angular, C#, and SQL.}
  ◊li{TensorFlow, Keras, machine-learning workflows, and model evaluation.}
  ◊li{Data visualization, query parsing, and data-product design.}
  ◊li{Technical writing, test design, and turning uncertain requirements into maintainable systems.}
}

◊section-title{Selected project experience}

◊h3{Intracranial Hemorrhage Detection and Segmentation}

◊p{Machine-learning research project · Recent}

◊ul{
  ◊li{Built a CT-imaging pipeline for multi-label hemorrhage classification and multi-class segmentation.}
  ◊li{Used multi-window CT inputs, skull stripping, mask rasterization, U-Net segmentation, and classifier ablations.}
  ◊li{Evaluated models with Dice, IoU, F1, AUC, and Hamming loss while documenting limitations from class imbalance and difficult subtypes.}
}

◊h3{Acts of Andrew Computational Theology Pipeline}

◊p{Computational humanities and text analysis · Recent}

◊ul{
  ◊li{Designed a three-corpus comparison framework for the canonical Gospels, the Acts of Andrew, and Gregory of Tours’ redacted version.}
  ◊li{Developed a proposition-scoring method for Encratic and Manichaean theological signals.}
  ◊li{Combined retrieval, entailment-style scoring, thematic mapping, and close-reading interpretation.}
}

◊h3{SQL Parser and Query Rewriter}

◊p{Software-engineering utility · Recent}

◊ul{
  ◊li{Worked on parsing and transforming SQL SELECT statements while preserving CTEs, subqueries, ordering, filtering, and paging semantics.}
  ◊li{Focused on top-level SELECT detection, nested SELECT exclusion, TOP insertion, WHERE, ORDER BY, OFFSET, FETCH, and unit-test coverage.}
}

◊h3{NBA Natural-Language Analytics Platform}

◊p{Data-product concept · Exploratory}

◊ul{
  ◊li{Explored a conversational interface for NBA data analysis that could generate dashboards and visualizations from natural-language questions.}
  ◊li{Focused on translating analyst questions into data queries, charts, and explainable outputs for coaches, media, and fans.}
}

◊section-title{Education}

◊h3{M.S. Applied Mathematics}

◊p{Northeastern University · In progress}

◊p{Focus areas include applied linear algebra, quantum information, quantum computing, and mathematical foundations relevant to machine learning and quantum algorithms.}

◊h3{B.S. Computer Science}

◊p{Northeastern University · Completed}

◊p{Foundation in software engineering, algorithms, systems, and application development.}

◊section-title{Research interests}

◊ul{
  ◊li{Quantum algorithms and quantum machine learning.}
  ◊li{Applied ML systems for medical imaging and text analysis.}
  ◊li{LLM and retrieval-augmented pipelines for structured interpretation.}
  ◊li{Computational humanities and theology.}
  ◊li{Data products that turn natural language into visual analysis.}
}
