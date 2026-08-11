#lang pollen

◊define-meta[title]{Skyline Stars}
◊define-meta[description]{A Racket bitmap experiment using rotation, masks, and weighted randomness to place stars over a skyline.}
◊define-meta[section]{work}
◊define-meta[kind]{project}
◊define-meta[date]{2026-05-09}
◊define-meta[tags]{Racket, creative-coding, generative-art}
◊define-meta[draft]{false}
◊define-meta[featured]{true}
◊define-meta[featured-order]{3}
◊define-meta[project-kind]{creative coding}
◊define-meta[status]{experiment}

◊content-header[#:back-href "/work/" #:back-label "Work"]{Skyline Stars}

◊project-meta[#:status "experiment" #:kind "creative coding"]

◊lede{A Racket bitmap experiment: rotate a skyline image, preserve the city, and place stars inside a shaped region with weighted randomness.}

◊p{The project started as image manipulation and became a lesson in composition. Early versions rotated the image the wrong way, hid it beneath the drawing layer, or filled the sky with a hard rectangle of stars. The better result needed more than correct code: a region shaped by the skyline, greater density toward the top right, and enough variation for the stars to feel atmospheric.}

◊section-title{Technical ingredients}

◊ul{
  ◊li{Bitmap loading and drawing in Racket.}
  ◊li{Rotation with coordinate correction.}
  ◊li{Alpha-aware image composition.}
  ◊li{Weighted random distributions.}
  ◊li{Shape masks for non-rectangular star placement.}
}

◊section-title{Why I kept it}

◊p{It is small enough to finish and personal enough to care about. That makes it useful practice: the code can teach me something even when the image never needs to become a product.}
