#!/bin/bash

wget https://opendata.ecdc.europa.eu/covid19/casedistribution/csv
wget https://health-infobase.canada.ca/src/data/covidLive/covid19.csv
wget https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv
wget https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv raw-covid19-JHU-deaths.csv

mv csv                                      raw-covid19-ECDC.csv
mv covid19.csv                              raw-covid19-GoCInfobase.csv
mv time_series_covid19_confirmed_global.csv raw-covid19-JHU-cases.csv
mv time_series_covid19_deaths_global.csv    raw-covid19-JHU-deaths.csv

chmod ugo-wx raw-covid19-*

cp DRAFT-Public-Health-Measures-Data-Canada-V0.2.csv interventions-canada.csv
chmod ugo-wx interventions-*.csv

