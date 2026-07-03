## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment  = "#>",
  eval     = nzchar(Sys.getenv("COMPILE_VIG_CANPUMF"))
)

## ----setup--------------------------------------------------------------------
library(canpumf)
library(dplyr)

## ----cache-path, eval = FALSE-------------------------------------------------
# options(canpumf.cache_path = "~/data/pumf.data")

## ----deposit, eval = FALSE----------------------------------------------------
# dir.create("~/data/pumf.data/CHS/2025", recursive = TRUE)
# file.copy("~/Downloads/2025.zip", "~/data/pumf.data/CHS/2025/")

## ----inherit, eval = FALSE----------------------------------------------------
# # Suppose CHS/2025 has just been released and is not in the registry yet.
# tbl <- get_pumf("CHS", "2025")
# #> No CHS/2025 registry entry; inheriting config from CHS/2022. Verify the new
# #> release matches (file layout, codes, BSW join) and add an explicit entry if
# #> it differs.

## ----try-it, eval = FALSE-----------------------------------------------------
# tbl <- get_pumf("CHS", "2025")
# tbl |> label_pumf_columns() |> head() |> collect()

## ----inspect, eval = FALSE----------------------------------------------------
# vdir <- file.path(getOption("canpumf.cache_path"), "NEWSURVEY", "2025")
# list.files(vdir, recursive = TRUE)

## ----meta, eval = FALSE-------------------------------------------------------
# meta <- pumf_metadata("NEWSURVEY", "2025")
# str(meta$variables)   # one row per variable: name, label_en, label_fr, type, ...
# str(meta$codes)       # one row per code value: name, val, label_en, label_fr
# str(meta$layout)      # fixed-width column ranges (absent for CSV data)

## ----template, eval = FALSE---------------------------------------------------
# pumf_registry("CHS", "2022")   # inspect a known entry
# list_pumf_registry()           # see everything that is registered

## ----entry, eval = FALSE------------------------------------------------------
# entry <- pumf_registry_entry(
#   file_mask     = "PUMF_NEWSURVEY_\\d{4}\\.txt",  # generic year from the start
#   bsw_file_mask = "bsw_flatfile\\.txt",
#   bsw_join_key  = "CASEID"
# )
# 
# # Re-parse with the candidate config until the metadata looks right:
# meta <- pumf_metadata("NEWSURVEY", "2025", registry = entry, refresh = TRUE)

## ----fixups, eval = FALSE-----------------------------------------------------
# entry <- pumf_registry_entry(
#   file_mask   = "PUMF_NEWSURVEY_\\d{4}\\.txt",
#   data_fixups = list(
#     force_numeric  = "INCOME",
#     force_character = "GEOCODE"
#   )
# )

## ----build, eval = FALSE------------------------------------------------------
# tbl <- get_pumf("NEWSURVEY", "2025", registry = entry, refresh = TRUE)
# 
# tbl |> label_pumf_columns() |> head() |> collect()   # spot-check labels
# tbl |> count() |> collect()                           # row count sanity check
# bsw_info(tbl)                                         # confirm weights joined

## ----promote, eval = FALSE----------------------------------------------------
# # In R/registry.R, inside the .pumf_registry list:
# newsurvey.2025  = .make_entry("NEWSURVEY", "2025",
#   file_mask     = "PUMF_NEWSURVEY_\\d{4}\\.txt",   # keep the generic year
#   bsw_file_mask = "bsw_flatfile\\.txt",
#   bsw_join_key  = "CASEID")

