#!/bin/bash

wget https://www.arcgis.com/sharing/rest/content/items/df277546e2904acfaf1a61cacb5b5d3c/data
mv    data  Covid19_CODOttawaResidentHospitalAdmissionsByDay_EN.xlsx
chmod ugo-w Covid19_CODOttawaResidentHospitalAdmissionsByDay_EN.xlsx

wget https://www.arcgis.com/sharing/rest/content/items/f1b9672ed3244410acb34019544df6be/data
mv    data  COVID-19_Ottawa_case_death_daily_count_data_EN.xlsx
chmod ugo-w COVID-19_Ottawa_case_death_daily_count_data_EN.xlsx

