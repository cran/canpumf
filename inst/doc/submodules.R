## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = nzchar(Sys.getenv("COMPILE_VIG_CANPUMF"))
)

## ----setup--------------------------------------------------------------------
library(dplyr)
library(canpumf)
options(canpumf.cache_path = Sys.getenv("COMPILE_VIG_CANPUMF"))

## -----------------------------------------------------------------------------
main <- get_pumf("GSS", "Cycle 16 (2002)")  # primary module (MAIN), carries WGHT_PER
#> GSS/Cycle 16 (2002) is a multi-module survey; you loaded the primary module. Other linked modules: CG4, CG6, CR.
#> Open one on the same connection with pumf_module(), e.g.:
#>   cg4 <- pumf_module(main, "CG4")

main |> select(1:5) |> head()

## -----------------------------------------------------------------------------
cg4 <- pumf_module(main, "CG4")   # the caregiving module
#> GSS/Cycle 16 (2002) modules join on 'RECID' (e.g. dplyr::inner_join(main, CG4, by = "RECID")).

cg4 |> select(1:5) |> head()

## -----------------------------------------------------------------------------
joined <- cg4 |>
  inner_join(
    main |> select(RECID, WGHT_PER),
    by = "RECID"
  )

joined |>
  summarise(weighted_n = sum(WGHT_PER, na.rm = TRUE)) |>
  collect()

## -----------------------------------------------------------------------------
shs   <- get_pumf("SHS", "2017")          # Interview (primary)
diary <- pumf_module(shs, "Diary")        # one row per purchase, same connection

diary |>
  inner_join(shs |> select(CASEID), by = "CASEID") |>
  tally() |>
  collect()

## -----------------------------------------------------------------------------
close_pumf(main)
close_pumf(shs)

## -----------------------------------------------------------------------------
con<-get_pumf_connection("SHS", "2017") 

DBI::dbListTables(con)

## -----------------------------------------------------------------------------
close_pumf(con)

