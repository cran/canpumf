## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = nzchar(Sys.getenv("COMPILE_VIG_CANPUMF"))
)

## ----setup--------------------------------------------------------------------
library(canpumf)
library(dplyr)
library(ggplot2)
options(canpumf.cache_path = Sys.getenv("COMPILE_VIG_CANPUMF"))

## -----------------------------------------------------------------------------
census_2021 <- get_pumf("Census",version="2021") 

## -----------------------------------------------------------------------------
census_2021 |>
  filter(CMA %in% c("Vancouver","Toronto","Montréal","Québec")) |>
  filter(PRIHM!="Not applicable") |>
  filter(AGEGRP!="Not available") |>
  summarise(across(matches("WEIGHT|WT\\d+"),sum),
            .by=c(CMA,AGEGRP,PRIHM)) |>
  mutate(Share=WEIGHT/sum(WEIGHT),.by=c(CMA,AGEGRP)) |>
  filter(PRIHM=="Person is primary maintainer") |>
  ggplot(aes(y=AGEGRP,x=Share,fill=CMA)) +
  geom_bar(stat="identity",position="dodge") +
  scale_x_continuous(labels=scales::percent) +
  labs(title="Age-specifc household maintainer rates",
       y="Age group",
       x="Household maintainer rate",
       caption="StatCan Census 2021 PUMF") 

## -----------------------------------------------------------------------------
census_2021 |>
  filter(CMA %in% c("Vancouver","Toronto","Montréal","Québec")) |>
  filter(PRIHM!="Not applicable") |>
  filter(AGEGRP!="Not available") |>
  summarise(across(matches("WEIGHT|WT\\d+"),sum),
            .by=c(CMA,AGEGRP,PRIHM)) |>
  collect() |>
  tidyr::pivot_longer(matches("WT\\d+"),names_to="Weights") |>
  mutate(Share=WEIGHT/sum(WEIGHT),
         Share_bsw=value/sum(value),
         .by=c(CMA,AGEGRP,Weights)) |>
  filter(PRIHM=="Person is primary maintainer") |>
  ggplot(aes(y=AGEGRP,fill=CMA)) +
  geom_bar(aes(x=Share),stat="identity",position="dodge") +
  geom_boxplot(aes(x=Share_bsw, group=interaction(CMA,AGEGRP)), fill=NA,shape=1, position="dodge") +
  scale_x_continuous(labels=scales::percent) +
  labs(title="Age-specifc household maintainer rates",
       y="Age group",
       x="Household maintainer rate (and replication weight ranges)",
       caption="StatCan Census 2021 PUMF") 

## -----------------------------------------------------------------------------
census_2021 |>
  filter(CMA %in% c("Vancouver","Toronto","Montréal","Québec")) |>
  filter(PRIHM!="Not applicable") |>
  filter(AGEGRP!="Not available") |>
  add_bootstrap_weights("WEIGHT") |>
  summarise(across(matches("WEIGHT|WT\\d+|CPBSW\\d+"),sum),
            .by=c(CMA,AGEGRP,PRIHM)) |>
  collect() |>
  tidyr::pivot_longer(matches("CPBSW\\d+"),names_to="Weights") |>
  mutate(Share=WEIGHT/sum(WEIGHT),
         Share_bsw=value/sum(value),
         .by=c(CMA,AGEGRP,Weights)) |>
  filter(PRIHM=="Person is primary maintainer") |>
  ggplot(aes(y=AGEGRP,fill=CMA)) +
  geom_bar(aes(x=Share),stat="identity",position="dodge") +
  geom_boxplot(aes(x=Share_bsw, group=interaction(CMA,AGEGRP)), fill=NA,shape=1, position="dodge") +
  scale_x_continuous(labels=scales::percent) +
  labs(title="Age-specifc household maintainer rates",
       y="Age group",
       x="Household maintainer rate (and bootstrap weight ranges)",
       caption="StatCan Census 2021 PUMF") 

## -----------------------------------------------------------------------------
census_2021 |> close_pumf()

