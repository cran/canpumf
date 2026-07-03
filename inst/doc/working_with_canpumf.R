## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = nzchar(Sys.getenv("COMPILE_VIG_CANPUMF"))
)

## ----setup--------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
library(canpumf)
options(canpumf.cache_path = Sys.getenv("COMPILE_VIG_CANPUMF"))

## -----------------------------------------------------------------------------
chs_pumf <- get_pumf("CHS","2018") 

chs_pumf |> 
  select(1:5) |>
  head(10)

## -----------------------------------------------------------------------------
chs_pumf <- chs_pumf |>
  label_pumf_columns()

chs_pumf |> 
  select(1:5) |>
  head(10)

## -----------------------------------------------------------------------------
renter_chs_pumf <- chs_pumf |>
  filter((Tenure == "No" & 
            `Previous accommodations - when move to current dwelling occurred` == "10 or more years ago + Always lived here") | 
           (`Previous accommodations - when move to current dwelling occurred` != "10 or more years ago + Always lived here" & 
              `Previous accommodations - tenure`== "Rent it"))

## ----fig-yvr-renters-forced-moves, fig.alt="Vancouver renters forced to move"----
plot_data <- renter_chs_pumf |> 
  filter(`Geographic grouping`=="Vancouver") |>
  group_by(`Previous accommodations - when move to current dwelling occurred`,
           `Previous accommodations - forced to move`) |>
  summarise(value=sum(`Household weight`),.groups = "drop") |>
  mutate(share=value/sum(value)) |>
  filter(`Previous accommodations - forced to move`=="Yes",
         !grepl("10",`Previous accommodations - when move to current dwelling occurred`))


ggplot(plot_data,aes(x=`Previous accommodations - when move to current dwelling occurred`,y=share)) +
  geom_bar(stat="identity",fill="brown") +
  coord_flip() +
  scale_y_continuous(labels=scales::percent) +
  labs(title="Vancouver renters forced to move",
       x="When move to current dwelling occurred",
       y="Share of current renters",
       caption="StatCan CHS PUMF 2018")

## ----fig-yvr-renters-forced-moves-bootstrap, fig.alt="Vancouver renters forced to move with bootstrap weights"----
plot_data <- renter_chs_pumf |>
  add_bootstrap_weights(weight_col = "Household weight", seed=42) |>
  filter(`Geographic grouping`=="Vancouver") |>
  summarise(across(matches("CPBSW\\d+|Household weight"),sum),
            .by=c(`Previous accommodations - when move to current dwelling occurred`,
                  `Previous accommodations - forced to move`)) |>
  collect() |>
  pivot_longer(matches("CPBSW\\d+|Household weight"),names_to="weights") |>
  group_by(weights) |>
  mutate(share=value/sum(value)) |>
  filter(`Previous accommodations - forced to move`=="Yes",
         !grepl("10",`Previous accommodations - when move to current dwelling occurred`))


ggplot(plot_data,aes(x=`Previous accommodations - when move to current dwelling occurred`,y=share)) +
  geom_boxplot(fill="brown") +
  coord_flip() +
  scale_y_continuous(labels=scales::percent) +
  labs(title="Vancouver renters forced to move",
       x="When move to current dwelling occurred",
       y="Share of current renters",
       caption="StatCan CHS PUMF 2018")

## ----fig-yvr-renters-forced-moves-previous-location, fig.alt="Vancouver renters forced to move by previous location"----
plot_data <- renter_chs_pumf |>
  add_bootstrap_weights(weight_col = "Household weight", seed=42) |>
  filter(`Geographic grouping`=="Vancouver") |>
  summarise(across(matches("CPBSW\\d+|Household weight"),sum),
            .by=c(`Previous accommodations - when move to current dwelling occurred`,
                  `Previous accommodations - location of previous dwelling`,
                  `Previous accommodations - forced to move`)) |>
  collect() |>
  pivot_longer(matches("CPBSW\\d+|Household weight"),names_to="weights") |>
  group_by(`Previous accommodations - location of previous dwelling`,
           weights) |>
  mutate(share=value/sum(value)) |>
  filter(`Previous accommodations - forced to move`=="Yes",
         !grepl("10",`Previous accommodations - when move to current dwelling occurred`)) |>
  mutate(`Location of previous dwelling` = gsub("\\.\\.\\..+$","",`Previous accommodations - location of previous dwelling`))


ggplot(plot_data,aes(x=`Previous accommodations - when move to current dwelling occurred`,
                     fill=`Location of previous dwelling`,
                     y=share)) +
  geom_boxplot(position="dodge") +
  coord_flip() +
  scale_y_continuous(labels=scales::percent) +
  labs(title="Vancouver renters forced to move",
       x="When move to current dwelling occurred",
       y="Share of current renters",
       caption="StatCan CHS PUMF 2018")

## ----fig-renters-forced-moves, fig.alt="Renters forced to move"---------------
plot_data <- renter_chs_pumf |>
  collect() |>
  add_bootstrap_weights(weight_col = "Household weight", seed=42) |>
  filter(`Geographic grouping` %in% c("Vancouver","Toronto","Montréal","Calgary","Ottawa-Gatineau","Winnipeg")) |>
  group_by(`Previous accommodations - when move to current dwelling occurred`,
           `Previous accommodations - location of previous dwelling`,
           `Geographic grouping`,
           `Previous accommodations - forced to move`) |>
  summarise(across(matches("CPBSW\\d+|Household weight"),sum),.groups="drop") |>
  pivot_longer(matches("CPBSW\\d+|Household weight"),names_to="weights") |>
  group_by(`Previous accommodations - location of previous dwelling`,
           `Geographic grouping`,
           weights) |>
  mutate(share=value/sum(value)) |>
  filter(`Previous accommodations - forced to move`=="Yes",
         !grepl("10",`Previous accommodations - when move to current dwelling occurred`)) |>
  mutate(`Location of previous dwelling` = gsub("\\/town.+$","",`Previous accommodations - location of previous dwelling`))


ggplot(plot_data,aes(x=`Previous accommodations - when move to current dwelling occurred`,
                     fill=`Location of previous dwelling`,
                     y=share)) +
  geom_boxplot(position="dodge") +
  coord_flip() +
  facet_wrap("`Geographic grouping`") +
  theme(legend.position = "bottom") +
  scale_y_continuous(labels=scales::percent) +
  labs(title="Renters forced to move",
       subtitle="(based on households currently renting that did not move in past 5 years or\nhouseholds that moved in past 5 years that rented their previous dweling)",
       x="When move to current dwelling occurred",
       y="Share of current renters",
       caption="StatCan CHS PUMF 2018")

