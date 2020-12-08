#!/bin/bash

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# download ECDC data
wget https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-2020-06-21.xlsx
wget https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide.xlsx

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# download Canadian data
wget https://health-infobase.canada.ca/src/data/covidLive/covid19.csv

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# download data from Johhs Hopkins University
wget https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv
wget https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
mv COVID-19-geographic-disbtribution-worldwide.xlsx raw-covid19-ECDC.xlsx
mv covid19.csv                                      raw-covid19-GoCInfobase.csv
mv time_series_covid19_confirmed_global.csv         raw-covid19-JHU-cases.csv
mv time_series_covid19_deaths_global.csv            raw-covid19-JHU-deaths.csv

chmod ugo-wx raw-covid19-*

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# download Ottawa data
wget https://opendata.arcgis.com/datasets/6bfe7832017546e5b30c5cc6a201091b_0.csv
mv 6bfe7832017546e5b30c5cc6a201091b_0.csv raw-covid19-Ottawa.csv
chmod ugo-w raw-covid19-Ottawa.csv

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# wget https://opendata.arcgis.com/datasets/cf9abb0165b34220be8f26790576a5e7_0/FeatureServer/0/query?outFields=*&where=1%3D1 -O raw-covid19-Ottawa-cases-and-deaths.json
# sleep 2
# mv    qu*   raw-covid19-Ottawa-cases-deaths.json
# chmod ugo-w raw-covid19-Ottawa-cases-deaths.json
#
# wget https://opendata.arcgis.com/datasets/02c99319ef44488e85cd4f96f5061f20_0.csv
# mv 02c99319ef44488e85cd4f96f5061f20_0.csv raw-covid19-Ottawa-hospitalizations.csv
# chmod ugo-w raw-covid19-Ottawa-hospitalizations.csv
#
# wget https://opendata.arcgis.com/datasets/cf9abb0165b34220be8f26790576a5e7_0.csv
# mv cf9abb0165b34220be8f26790576a5e7_0.csv raw-covid19-Ottawa-cases-deaths.csv
# chmod ugo-w raw-covid19-Ottawa-cases-deaths.csv

#cp ../2020-06-09.01/COVID-19_Ottawa_case_death_daily_count_data_EN.xlsx .
#chmod ugo-w COVID-19_Ottawa_case_death_daily_count_data_EN.xlsx

#cp ../2020-06-09.01/Covid19_CODOttawaResidentHospitalAdmissionsByDay_EN.xlsx .
#chmod ugo-w Covid19_CODOttawaResidentHospitalAdmissionsByDay_EN.xlsx
