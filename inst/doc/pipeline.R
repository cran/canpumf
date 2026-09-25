## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = FALSE)

## ----pipeline-diagram, echo=FALSE, out.width="100%", fig.alt="canpumf pipeline: get_pumf dispatches LFS vs. the three-stage pipeline (locate/download, parse metadata, build DuckDB), then registers provenance and returns a lazy tbl. In stage 2, nine parsers feed merge_metadata(), except the user-guide frequency dictionary, which instead goes through a cross-check that repairs truncated labels before the canonical CSVs are written."----
# The diagram is rendered to a static image (SVG for HTML, PNG for PDF) via
# Graphviz so it renders identically and reliably in every output format,
# without relying on JavaScript htmlwidgets (which never render in PDF).
dot <- '
digraph pipeline {
  graph [rankdir = TB, fontname = "Helvetica", nodesep = 0.30, ranksep = 0.40, compound = true];
  node  [fontname = "Helvetica", fontsize = 10, style = "filled", fillcolor = "#eef3f8", color = "#5b7da3", margin = "0.09,0.05"];
  edge  [fontname = "Helvetica", fontsize = 9, color = "#666666", arrowsize = 0.7];

  A    [label = "get_pumf(series, version, lang)", shape = box, style = "filled,rounded", fillcolor = "#d9ead3"];
  LFS  [label = "series == LFS?", shape = diamond, fillcolor = "#fce8b2"];
  LFSP [label = "lfs_get_pumf()", shape = box, style = "filled,rounded", fillcolor = "#d9ead3"];

  A   -> LFS;
  LFS -> LFSP [label = "yes"];
  LFS -> CHK  [label = "no", lhead = cluster_s1];

  subgraph cluster_s1 {
    label = "Stage 1  —  locate / download";
    labeljust = "l"; fontname = "Helvetica-Bold"; fontsize = 11;
    style = "rounded,filled"; fillcolor = "#fbfdff"; color = "#9fb6cc";
    CHK  [label = "version dir exists?", shape = diamond, fillcolor = "#fce8b2"];
    COL  [label = "look up collection URL", shape = box];
    EFT  [label = "EFT-only?", shape = diamond, fillcolor = "#fce8b2"];
    ERR  [label = "stop: deposit zip manually", shape = box, fillcolor = "#f4cccc"];
    DL   [label = "download zip", shape = box];
    UZ   [label = "robust_unzip()", shape = box];
    EXTR [label = "zip already extracted?", shape = diamond, fillcolor = "#fce8b2"];

    CHK  -> EXTR [label = "yes, not refresh"];
    CHK  -> COL  [label = "no / refresh"];
    COL  -> EFT;
    EFT  -> ERR  [label = "yes"];
    EFT  -> DL   [label = "no"];
    DL   -> UZ;
    UZ   -> EXTR;
    EXTR -> UZ   [label = "no"];
  }

  subgraph cluster_s2 {
    label = "Stage 2  —  parse metadata";
    labeljust = "l"; fontname = "Helvetica-Bold"; fontsize = 11;
    style = "rounded,filled"; fillcolor = "#fbfdff"; color = "#9fb6cc";
    MC   [label = "metadata already exists?", shape = diamond, fillcolor = "#fce8b2"];
    DF   [label = "detect_formats()", shape = box];
    P1   [label = "LFS codebook.csv", shape = box];
    P2   [label = "CPSS variables.csv", shape = box];
    P3   [label = "SAS cards (.lay + .lbe)", shape = box];
    P4   [label = "SPSS split (vare/vale/_i)", shape = box];
    P5   [label = "SPSS mono (.sps / SPSS.txt / .xmf)", shape = box];
    P6   [label = "SPSS .sav", shape = box];
    P7   [label = "PDF Dictionary", shape = box];
    P8   [label = "PDF frequency codebook", shape = box];
    P9   [label = "PDF user-guide frequency dictionary", shape = box];
    MRG  [label = "merge_metadata()", shape = box];
    XC   [label = "guide describes this file?\n(frequencies or positions)",
          shape = diamond, fillcolor = "#fce8b2"];
    RP   [label = "repair truncated labels\n+ pdf_validation.csv / label_repairs.csv",
          shape = box];
    WR   [label = "write variables.csv / codes.csv / layout.csv", shape = box];

    MC -> DF [label = "no / refresh"];
    DF -> P1; DF -> P2; DF -> P3; DF -> P4; DF -> P5; DF -> P6; DF -> P7; DF -> P8;
    P1 -> MRG; P2 -> MRG; P3 -> MRG; P4 -> MRG; P5 -> MRG; P6 -> MRG; P7 -> MRG; P8 -> MRG;
    MRG -> WR;

    // Parser 9 bypasses the merge: the command file stays authoritative and the
    // guide is only ever used to repair it, after the cross-check accepts it.
    DF -> P9;
    P9 -> XC;
    MRG -> XC [style = dashed];
    XC -> RP [label = "yes"];
    RP -> WR;
  }

  EXTR -> MC [label = "yes", lhead = cluster_s2];

  subgraph cluster_s3 {
    label = "Stage 3  —  build DuckDB";
    labeljust = "l"; fontname = "Helvetica-Bold"; fontsize = 11;
    style = "rounded,filled"; fillcolor = "#fbfdff"; color = "#9fb6cc";
    TB   [label = "table already in DuckDB?", shape = diamond, fillcolor = "#fce8b2"];
    FF   [label = "find data file", shape = box];
    FWF  [label = "layout.csv exists\nand file not .csv?", shape = diamond, fillcolor = "#fce8b2"];
    RFW  [label = "read_fwf", shape = box];
    RCS  [label = "read_csv", shape = box];
    JNK  [label = "drop trailing junk rows", shape = box];
    FX   [label = "apply data fixups\n(str_pad, rename, cols_swap, force_*)", shape = box];
    BSW  [label = "BSW mask in registry?", shape = diamond, fillcolor = "#fce8b2"];
    RBW  [label = "join bootstrap weights", shape = box];
    NC   [label = "numeric conversion\n(missing ranges + na_values)", shape = box];
    CL   [label = "code labels to factors", shape = box];
    WD   [label = "write DuckDB table", shape = box];
    EN   [label = "enforce ENUM / force_* types", shape = box];
    OD   [label = "open read-only connection", shape = box];

    TB  -> FF  [label = "no / refresh"];
    FF  -> FWF;
    FWF -> RFW [label = "yes (FWF)"];
    FWF -> RCS [label = "no (CSV)"];
    RFW -> JNK; RCS -> JNK;
    JNK -> FX;
    FX  -> BSW;
    BSW -> RBW [label = "yes"];
    BSW -> NC  [label = "no"];
    RBW -> NC;
    NC  -> CL;
    CL  -> WD;
    WD  -> EN;
    EN  -> OD;
  }

  WR -> TB  [lhead = cluster_s3];
  MC -> TB  [label = "yes, not refresh"];
  TB -> OD  [label = "yes, not refresh"];

  REG [label = "register provenance (series, version, lang)", shape = box, style = "filled,rounded", fillcolor = "#d9ead3"];
  TBL [label = "return lazy dplyr::tbl()", shape = box, style = "filled,rounded", fillcolor = "#d9ead3"];
  OD  -> REG;
  REG -> TBL;
}
'

have_render <- requireNamespace("DiagrammeR", quietly = TRUE) &&
  requireNamespace("DiagrammeRsvg", quietly = TRUE)

if (have_render) {
  svg <- DiagrammeRsvg::export_svg(DiagrammeR::grViz(dot))
  if (knitr::is_latex_output()) {
    if (requireNamespace("rsvg", quietly = TRUE)) {
      png <- knitr::fig_path(".png")
      dir.create(dirname(png), recursive = TRUE, showWarnings = FALSE)
      rsvg::rsvg_png(charToRaw(svg), png, width = 1800)
      knitr::include_graphics(png)
    } else {
      message("Install rsvg to render the pipeline diagram in PDF output.")
    }
  } else {
    svg_file <- knitr::fig_path(".svg")
    dir.create(dirname(svg_file), recursive = TRUE, showWarnings = FALSE)
    writeLines(svg, svg_file)
    knitr::include_graphics(svg_file)
  }
} else {
  cat("Install DiagrammeR and DiagrammeRsvg to render this diagram.")
}

