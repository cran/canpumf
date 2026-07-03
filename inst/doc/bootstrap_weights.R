## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = nzchar(Sys.getenv("COMPILE_VIG_CANPUMF"))
)

## ----setup, warning=FALSE-----------------------------------------------------
library(dplyr)
library(canpumf)

## -----------------------------------------------------------------------------
cis <- get_pumf("CIS", "2019")

cis_bsw <- cis |>
  add_bootstrap_weights(weight_col = "FWEIGHT", n_replicates = 200, seed = 42)

# 200 replicate columns CPBSW1 … CPBSW200 are now available
grep("^CPBSW", colnames(cis_bsw), value = TRUE) |> head()

## -----------------------------------------------------------------------------
bsw_info(cis_bsw)

## ----eval = FALSE-------------------------------------------------------------
# cis_bsw <- cis |>
#   add_bootstrap_weights(weight_col = "FWEIGHT", strata_cols = "PROV",
#                         n_replicates = 200, seed = 42)

## -----------------------------------------------------------------------------
est <- cis_bsw |>
  summarise(across(c(FWEIGHT, matches("^CPBSW[0-9]+$")), ~ sum(.x))) |>
  collect()

point_estimate      <- est$FWEIGHT
replicate_estimates <- est |> select(matches("^CPBSW[0-9]+$")) |> unlist()

# Bootstrap variance: mean squared deviation of the replicate estimates from
# the full-sample estimate; the standard error is its square root.
# Confidence intervals can be obtained by taking the appropriate quantiles.
confidence_interval <- quantile(replicate_estimates,c(0.025,0.975))
std_error <- sqrt(mean((replicate_estimates - point_estimate)^2))

c(estimate = point_estimate, se = std_error, conf=confidence_interval)

## ----eval = FALSE-------------------------------------------------------------
# # First 200 replicates …
# cis_bsw <- add_bootstrap_weights(cis, "FWEIGHT", n_replicates = 200, seed = 42)
# # … later, extend to 500: only CPBSW201 … CPBSW500 are generated.
# cis_bsw <- add_bootstrap_weights(cis, "FWEIGHT", n_replicates = 500, seed = 42)

## ----eval = FALSE-------------------------------------------------------------
# cis_bsw <- add_bootstrap_weights(cis, "PWEIGHT", n_replicates = 200,
#                                  seed = 42, overwrite = TRUE)

## ----eval = FALSE-------------------------------------------------------------
# tbl <- get_pumf("<series>", "<version>") |>
#   add_bootstrap_weights(weight_col = "<household_weight>", prefix = "HHBSW") |>
#   add_bootstrap_weights(weight_col = "<person_weight>",    prefix = "PPBSW")

## ----eval = FALSE-------------------------------------------------------------
# bsw_info(cis_bsw)                      # list stored BSW tables and replicate counts
# cis_clean <- remove_bootstrap_weights(cis_bsw, weight_col = "PWEIGHT")

