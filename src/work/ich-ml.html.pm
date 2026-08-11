#lang pollen

◊define-meta[title]{Intracranial Hemorrhage Detection and Segmentation}
◊define-meta[description]{A medical-imaging research project exploring hemorrhage segmentation and multi-label classification from CT scans.}
◊define-meta[section]{work}
◊define-meta[kind]{project}
◊define-meta[date]{2026-05-09}
◊define-meta[tags]{machine-learning, medical-imaging, computer-vision}
◊define-meta[draft]{false}
◊define-meta[featured]{true}
◊define-meta[featured-order]{1}
◊define-meta[project-kind]{machine learning}
◊define-meta[status]{research project}

◊content-header[#:back-href "/work/" #:back-label "Work"]{Intracranial Hemorrhage Detection and Segmentation}

◊project-meta[#:status "research project" #:kind "machine learning"]

◊lede{A CT-imaging project exploring whether segmentation can serve both as an output and as a useful feature source for hemorrhage classification.}

◊p{The work combines medical-image preprocessing, multiple CT window representations, contour-based skull stripping, annotation parsing, U-Net segmentation, classification models, and ablation studies. It is a research system, not a clinical diagnostic tool.}

◊section-title{What the project explored}

◊ul{
  ◊li{Preprocessing with bone, brain, max-contrast, and subdural-style CT windows.}
  ◊li{Mask generation from polygon annotations.}
  ◊li{U-Net-style encoder and decoder models for segmentation.}
  ◊li{Multi-label classification across hemorrhage subtypes.}
  ◊li{Ablations comparing segmentation hints, symmetry hints, bounding boxes, and baseline configurations.}
  ◊li{Evaluation with Dice, IoU, F1, AUC, and Hamming loss.}
}

◊section-title{What I learned}

◊p{Medical-imaging models can look more successful than they are when the dataset is imbalanced. A model may learn common classes while missing rare but important ones. The project pushed me to look past a working training loop and pay attention to per-class metrics, failure cases, and whether the evaluation actually supports the claim being made.}
