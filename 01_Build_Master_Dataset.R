# 01 Load Data
# -----------------------------
library(tidyverse)
library(readxl)
library(writexl)

data_dir<- 'data'
out_dir<- 'outputs'

CovidVax<-read_xlsx(file.path(data_dir, "COVID-19_Vaccinations_in_the_United_States,County_20250911.xlsx"))
HealthData<-read_xlsx(file.path(data_dir, "Health2024.xlsx"))
RuralUrban<-read_xlsx(file.path(data_dir, "Ruralurbancontinuumcodes2023.xlsx"))
Election<-read_xlsx(file.path(data_dir, "countypres_2000-2024.xlsx"))
AgeSex<-read_xlsx(file.path(data_dir, "AgeSexCounty.xlsx"))
insurance<-read_xlsx(file.path(data_dir, "Insurance.xlsx"))
CountyDemoACS<-read_xlsx(file.path(data_dir, "County_Demo_Data_censusACS.xlsx"))
#-----------------------------
# 02 Build Master Dataset
# Spine = CovidVax
# ----------------------------

MasterVaxData<- CovidVax
# (Optional) Drop unused columns early if desired

MasterVaxData<-MasterVaxData %>%
  left_join(CountyDemoACS, by = 'FIPS')%>%
  left_join(HealthData, by = 'FIPS')%>%
  left_join(RuralUrban, by = 'FIPS')%>%
  left_join(AgeSex, by = 'FIPS')%>%
  left_join(insurance, by = 'FIPS')


# ----------------------------
# 03 Election features
# ----------------------------

election_2020 <- Election %>%
  filter(year == 2020, party == 'REPUBLICAN') %>%
  group_by(state, county_fips, totalvotes) %>%
  summarise(gopvotes = sum(candidatevotes), .groups = "drop") %>%
  mutate(GOP_Pct_2020 = 100 * gopvotes / totalvotes) %>%
  select(state, county_fips, GOP_Pct_2020)

election_2024 <- Election %>%
  filter(year == 2024, party == 'REPUBLICAN') %>%
  group_by(state, county_fips, totalvotes) %>%
  summarise(gopvotes = sum(candidatevotes), .groups = "drop") %>%
  mutate(GOP_Pct_2024 = 100 * gopvotes / totalvotes) %>%
  select(state, county_fips, GOP_Pct_2024)

Election_All <- left_join(election_2020, election_2024, by = c("state", "county_fips")) %>%
  rename(FIPS = county_fips)

MasterVaxData <- MasterVaxData %>%
  left_join(Election_All, by = "FIPS")

MasterVaxData<-MasterVaxData%>%select(FIPS, County.x, State.y, Both_Doses_Pct, 
                                      WhiteNonHispPct, BlackPct, HispanicPct, 
                                      BachnAbove, MedianIncome, PovertyRateSr, 
                                      OBESITY_AdjPrev, Age_Adj_LackofHealthCoverage,
                                      GOP_Pct_2020, GOP_Pct_2024)%>%
  rename(County = County.x, State = State.y)

#-----------------------------
# 04 Check for missingness
#-----------------------------

na_counts <- colSums(is.na(MasterVaxData))
# write_xlsx(as.data.frame(na_counts), file.path(out_dir, "na_counts.xlsx"))  # optional
# write_xlsx(MasterVaxData, file.path(out_dir, "MasterVaxData.xlsx"))
print(na_counts)

#-----------------------------
# 05 Build modeling dataset
#-----------------------------

ModelVaxData<-MasterVaxData%>%filter(!is.na(Both_Doses_Pct))
ModelVaxData<-ModelVaxData%>%filter(!is.na(State))
colSums(is.na(ModelVaxData))