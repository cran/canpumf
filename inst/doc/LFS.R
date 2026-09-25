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

## -----------------------------------------------------------------------------
lfs_hist_1995_06 <- get_pumf("LFS_HIST", "1995-06")  # one month
lfs_hist_1995_06 |> 
  count(LFSSTAT, wt = FWEIGHT) |>
  collect()

## -----------------------------------------------------------------------------
lfs_hist <- get_pumf("LFS_HIST", refresh = "auto")

## -----------------------------------------------------------------------------
lfs_tl <- get_lfs_timeline(refresh = "auto")
pumf_var_labels(lfs_tl)

## -----------------------------------------------------------------------------
lf_monthly <- lfs_tl |>
  filter(LFSSTAT != "Not in labour force") |>
  add_lfs_SURVDATE() |>
  summarise(labour_force = sum(FINALWT),
            unemployed = sum(FINALWT[LFSSTAT == "Unemployed"], na.rm = TRUE),
            .by = c(SURVDATE, GENDER_SEX)) |>
  mutate(rate = unemployed / labour_force) |>
  collect()

lf_monthly |>
  ggplot(aes(x = SURVDATE, y = rate, colour = GENDER_SEX)) +
  geom_line(alpha = 0.3) +
  geom_smooth(method = "loess", span = 0.05, se = FALSE, linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2006-01-01"), linetype = "dashed") +
  scale_y_continuous(labels = scales::percent) +
  labs(title = "Unemployment rate by gender/sex, 1976 onward",
       subtitle = "Monthly, not seasonally adjusted; dashed line: LFS_HIST to LFS",
       x = NULL, y = "Unemployment rate", colour = NULL,
       caption = "StatCan LFS PUMF (1976-2005 via Borealis/ODESI)")

## -----------------------------------------------------------------------------
core_age <- c("25 to 29 years", "30 to 34 years", "35 to 39 years", "40 to 44 years",
              "45 to 49 years", "50 to 54 years")

participation <- lfs_tl |>
  filter(AGE_12 %in% core_age) |>
  summarise(population = sum(FINALWT),
            labour_force = sum(FINALWT[LFSSTAT != "Not in labour force"], na.rm = TRUE),
            .by = c(SURVYEAR, GENDER_SEX)) |>
  mutate(rate = labour_force / population) |>
  collect()

participation |>
  ggplot(aes(x = SURVYEAR, y = rate, colour = GENDER_SEX)) +
  geom_line() +
  scale_y_continuous(labels = scales::percent) +
  labs(title = "Labour force participation of 25 to 54 year olds",
       subtitle = "Pooled monthly samples of each year",
       x = NULL, y = "Participation rate", colour = NULL,
       caption = "StatCan LFS PUMF (1976-2005 via Borealis/ODESI)")

## -----------------------------------------------------------------------------
lfs_tl |>
  filter(LFSSTAT %in% c("Employed, at work", "Employed, absent from work"),
         !is.na(HRLYEARN)) |>
  summarise(wage = sum(HRLYEARN * FINALWT) / sum(FINALWT),
            .by = c(SURVYEAR, CMA)) |>
  collect() |>
  ggplot(aes(x = SURVYEAR, y = wage, colour = CMA)) +
  geom_line() +
  scale_y_continuous(labels = scales::dollar) +
  labs(title = "Average usual hourly wage of employees",
       subtitle = "Nominal dollars",
       x = NULL, y = NULL, colour = NULL,
       caption = "StatCan LFS PUMF (1997-2005 via Borealis/ODESI)")

## -----------------------------------------------------------------------------
close_pumf(lfs_tl)
close_pumf(lfs_hist)
close_pumf(lfs_hist_1995_06)

