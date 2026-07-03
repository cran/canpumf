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
list_canpumf_collection() |> 
  filter(Acronym=="LFS")

## -----------------------------------------------------------------------------
lfs_2022 <- get_pumf("LFS","2022")

lfs_2022 |>
  select(1:5) |>
  head(10)

## -----------------------------------------------------------------------------
lfs_2022 <- lfs_2022 |> label_pumf_columns()

## -----------------------------------------------------------------------------
lfs_2022_02_data <- lfs_2022 |> 
  filter(`Survey month`==2) |>
  collect() |>
  add_bootstrap_weights(weight_col = "Standard final weight", seed = 42)

## -----------------------------------------------------------------------------
data <- lfs_2022_02_data |>
  filter(substr(`Five-year age group of respondent`,0,2) %in% seq(20,60,5)) |>
  filter(`Labour force status`!="Not in labour force") |>
  summarise(across(matches("Standard final weight|CPBSW\\d+"),sum),
            .by=c(`Labour force status`,`Five-year age group of respondent`,`Gender of respondent`,
                  `Marital status of respondent`)) |>
  pivot_longer(matches("Standard final weight|CPBSW\\d+"),names_to="Weight",values_to="Count") |>
  group_by(`Five-year age group of respondent`,`Gender of respondent`,
           `Marital status of respondent`, Weight) |>
  mutate(Share=ifelse(Count==0,0,Count/sum(Count))) |>
  ungroup()

data_age_adjusted <- data %>%
  left_join((.) |> 
              summarize(Count=sum(Count),
                        .by=c(`Five-year age group of respondent`,`Gender of respondent`,Weight)) |>
              mutate(P_age__gender=Count/sum(Count),
                     .by=c(`Gender of respondent`,Weight)) |>
              select(`Gender of respondent`,`Five-year age group of respondent`,Weight,P_age__gender),
            by=c("Gender of respondent","Five-year age group of respondent","Weight")) |>
  summarise(age_adjusted=sum(Share*P_age__gender),
            .by=c(`Gender of respondent`,`Labour force status`,`Marital status of respondent`, Weight))
  
data_age_adjusted |>
  filter(`Labour force status`=="Unemployed") |>
  ggplot(aes(x=age_adjusted, y=`Marital status of respondent`, fill=`Gender of respondent`)) +
  geom_boxplot() +
  geom_point(shape=21,data=~filter(.,Weight=="Standard final weight"),position=position_dodge(width=0.75)) +
  scale_x_continuous(labels=scales::percent) +
  labs(title="Unemployment rates of 20 to 64 year olds in February 2022",
       x="Age-adjusted unemployment rate",
       caption="StatCan LFS PUMF 2022-02")

## -----------------------------------------------------------------------------
data2 <- lfs_2022_02_data |>
  filter(substr(`Five-year age group of respondent`,0,2) %in% seq(20,60,5)) |>
  summarise(across(matches("Standard final weight|CPBSW\\d+"),sum),
            .by=c(`Labour force status`, `Five-year age group of respondent`,
                  `Gender of respondent`, `Marital status of respondent`)) |>
  pivot_longer(matches("Standard final weight|CPBSW\\d+"),names_to="Weight",values_to="Count") |>
  mutate(Share=ifelse(Count==0,0,Count/sum(Count)),
         .by=c(`Five-year age group of respondent`,`Gender of respondent`,
               `Marital status of respondent`, Weight)) 

data_age_adjusted2 <- data2 %>%
  left_join((.) |> 
              summarize(Count=sum(Count),
                        .by=c(`Five-year age group of respondent`,`Gender of respondent`,Weight)) |>
              mutate(P_age__sex=Count/sum(Count),
                     .by=c(`Gender of respondent`,Weight)) |>
              select(`Gender of respondent`,`Five-year age group of respondent`,Weight,P_age__sex),
            by=c("Gender of respondent","Five-year age group of respondent","Weight")) |>
  summarise(age_adjusted=sum(Share*P_age__sex),
            .by=c(`Gender of respondent`,`Labour force status`,`Marital status of respondent`, Weight))
  
data_age_adjusted2 |>
  filter(`Labour force status`=="Not in labour force") |>
  ggplot(aes(x=1-age_adjusted, y=`Marital status of respondent`, fill=`Gender of respondent`)) +
  geom_boxplot() +
  geom_point(shape=21,data=~filter(.,Weight=="Standard final weight"),position=position_dodge(width=0.75)) +
  scale_x_continuous(labels=scales::percent) +
  labs(title="Labour force participation rates of 20 to 64 year olds in February 2022",
       x="Age-adjusted participation rate",
       caption="StatCan LFS PUMF 2022-02")

## -----------------------------------------------------------------------------
data_age_adjusted2 |>
  filter(`Labour force status`=="Employed, at work") |>
  ggplot(aes(x=age_adjusted, y=`Marital status of respondent`, fill=`Gender of respondent`)) +
  geom_boxplot() +
  geom_point(shape=21,data=~filter(.,Weight=="Standard final weight"),position=position_dodge(width=0.75)) +
  scale_x_continuous(labels=scales::percent) +
  labs(title="Share of 20 to 64 year olds working in February 2022",
       x="Age-adjusted share at work",
       caption="StatCan LFS PUMF 2022-02")

## -----------------------------------------------------------------------------
lfs_2022 |> close_pumf()

## -----------------------------------------------------------------------------
lfs_pumf <- get_pumf("LFS", refresh="auto")

## -----------------------------------------------------------------------------
unemployment_stats <- lfs_pumf |> 
  filter(LFSSTAT !="Not in labour force") |>
  filter(AGE_12 %in% c("25 to 29 years","30 to 34 years", "35 to 39 years")) |>
  mutate(jd=case_when(is.na(DURJLESS) ~ "Not applicable",
                      DURJLESS<12 ~ "Less than one year",
                      TRUE ~ "One year or more")) |>
  add_lfs_SURVDATE() |>
  summarize(Count=sum(FINALWT),.by=c(SURVDATE,jd,AGE_12)) |>
  mutate(Share=Count/sum(Count),.by=c(SURVDATE,AGE_12)) |>
  filter(jd!="Not applicable")


unemployment_stats |>
  ggplot(aes(x=SURVDATE,y=Share,colour=AGE_12)) +
  geom_line() +
  facet_wrap(~jd) +
  scale_y_continuous(labels=scales::percent_format()) +
  labs(title="Unemployment by duration of unemployment",
       y="Unemployment rate",x=NULL,
       colour="Age group",
       caption="StatCan LFS (PUMF)")

## -----------------------------------------------------------------------------
microbenchmark::microbenchmark(collect(unemployment_stats)) |> 
  boxplot()

## -----------------------------------------------------------------------------
lfs_pumf |> 
  filter(LFSSTAT !="Not in labour force") |>
  add_lfs_SURVDATE() |>
  add_lfs_GENDER_SEX() |>
  summarise(Count=sum(FINALWT),.by=c(SURVDATE,LFSSTAT,GENDER_SEX)) |>
  mutate(Share=Count/sum(Count),.by=c(SURVDATE,GENDER_SEX)) |>
  filter(LFSSTAT=="Unemployed") |>
  ggplot(aes(x=SURVDATE,y=Share,colour=GENDER_SEX)) +
  geom_line() +
  scale_y_continuous(labels=scales::percent_format()) +
  labs(title="Unemployment sex/gender",
       y="Unemployment rate",x=NULL,
       colour="Gender",
       caption="StatCan LFS (PUMF)")

## -----------------------------------------------------------------------------
lfs_pumf |> close_pumf()

