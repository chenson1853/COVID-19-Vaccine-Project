# 06 Modeling (all-county and stratified by GOP vote share)
#-----------------------------
library(tidyverse)
library(car)
library(readxl)
library(broom)
library(writexl)


data_dir <- "data"
out_dir  <- "outputs"
dir.create(out_dir, showWarnings = FALSE)

# load data analysis dataset (manually corrected values documented in ReadMe)

ModelVaxData<-read_xlsx(file.path(data_dir, "ModelVaxData_corrected.xlsx"))

#-----------------------------
# 07 All-county models
#-----------------------------

model_simple<-lm(Both_Doses_Pct~GOP_Pct_2020, data = ModelVaxData)
summary(model_simple)

model_multiple<-lm(Both_Doses_Pct~GOP_Pct_2020+BachnAbove+OBESITY_AdjPrev, data = ModelVaxData)
summary(model_multiple)
vif(model_multiple)

pdf(file.path(out_dir, "diag_model_multi.pdf"))
plot(model_multi)
dev.off()

#-----------------------------
# 08 Models stratified by 2020 GOP vote share
#-----------------------------

# stratify counties by 2020 GOP vote share (>= 55, < 55)

GOPData<-ModelVaxData%>%filter(GOP_Pct_2020 >= 55)
DemData<-ModelVaxData%>%filter(GOP_Pct_2020 < 55)

#-----------------------------
# Run models on stratified data
#-----------------------------

# model for counties with >= 55% GOP vote share

model_gop<-lm(Both_Doses_Pct~GOP_Pct_2020+BachnAbove+Age_Adj_LackofHealthCoverage+PovertyRateSr,
             data = GOPData)
summary(model_gop)
vif(model_gop)

# model for counties with < 55% GOP vote share

model_dem<-lm(Both_Doses_Pct~GOP_Pct_2020+BlackPct+MedianIncome+Age_Adj_LackofHealthCoverage,
             data= DemData)
summary(model_dem)
vif(model_dem)

pdf(file.path(out_dir, "diag_model_gop.pdf"))
plot(model_gop)
dev.off()

pdf(file.path(out_dir, "diag_model_dem.pdf"))
plot(model_dem)
dev.off()

#-----------------------------
# 09 Export coefficient tables
#-----------------------------

results <- bind_rows(
  tidy(model_simple) %>% mutate(model = "simple"),
  tidy(model_multiple)  %>% mutate(model = "multiple"),
  tidy(model_gop)    %>% mutate(model = "gop_stratum"),
  tidy(model_dem)    %>% mutate(model = "dem_stratum")
)

write_xlsx(results, file.path(out_dir, "model_coefficients.xlsx"))

#-----------------------------
# 10 Select figures
#-----------------------------

# choropleth of Both_Dose_Pct by county

library(usmap)
MapVaxData<-MasterVaxData%>%rename(fips = FIPS)
vaxmap<-
  plot_usmap(data_year = 2021, color = 'lightgrey', linewidth = 0.1, regions = 'counties', data = MapVaxData, values = 'Both_Doses_Pct')+
  scale_fill_gradient2(labels = scales::label_percent(scale = 1), breaks = c(20,40, 60), high = 'darkblue', low = 'white')+
  labs(fill = 'Percent Fully Vaccinated Against COVID-19')+
  theme(legend.position = 'top')+
  guides(fill = guide_colorbar(barwidth = unit(7, 'cm')))
ggsave(file.path(out_dir, 'full_vax_by_county.png'), vaxmap, width = 8, height = 5)

# Scatterplot of Both_Dose_Pct vs. GOP_Pct_2020

vaxscatter<-
  ggplot(data = ModelVaxData, aes(x = GOP_Pct_2020, y = Both_Doses_Pct))+
  geom_point(color = 'darkslategrey', alpha = 0.7)+
  geom_smooth(se = FALSE, color = 'skyblue', method = 'lm', linewidth = 1.2)+
  labs(y = 'Percent Fully Vaccinated Against COVID-19', x = 'Percent of Votes Won by GOP in 2020', title = 'U.S. County COVID-19 Vaccination Rate by Support of GOP')+
  theme_light()+
  theme(plot.title = element_text(hjust = 0.5, size = 14),
        axis.title = element_text(size = 12))
ggsave(file.path(out_dir, 'scatterplot vax vs gop voteshare'), vaxscatter, width = 8, height = 5)
