
Comparative diagnostics of three sources of COVID-19 case and death count time series data for Canada
=====================================================================================================

This comparative analysis was performed in order to inform us of which of the following three data sources
could be used as the primary data source for modelling the effects on physical distancing measures
on COVID-19 transmissibility:

*  Public Health Infobase (PHI), Public Health Agency of Canada (PHAC):

   https://health-infobase.canada.ca/src/data/covidLive/covid19.csv

*  European Centre of Disease Prevention and Control (ECDC) open data portal:

   https://opendata.ecdc.europa.eu/covid19/casedistribution/csv

*  Center for Systems Science and Engineering (CSSE), Johns Hopkins University:

   https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv

   https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv

Recommendation
--------------
A comparison of the three data sets above suggests that
using a certain "patched" (see below) version
of the PHI data set of PHAC should be the most straightforward.

Key observation on the PHI data (of cumulative counts)
------------------------------------------------------
The PHI data (as downloaded on April 11, 2020) do not contain records
for days when there were no new reported COVID-19 cases or deaths
(e.g. for days during the early phase of the COVID-19 pandemic).

For example:

*  In the following file (as downloaded on April 11, 2020) 

   https://health-infobase.canada.ca/src/data/covidLive/covid19.csv

   the first three days with reported data for British Columbia are:
   2020-01-31, 2020-02-08 and 2020-02-16,
   whose respective reported confirmed case counts are: 1, 4 and 5.

   In particular, the above file (again, as downloaded on April 11, 2020) contains no records
   for British Columbia for 2020-02-01 through 2020-02-07,
   during which period presumably there were neither new reported COVID-19 confirmed cases
   nor new reported COVID-19 deaths.

*  The above data file (as downloaded on April 11, 2020)
   contains no records at all for 2020-03-10 for all provinces.

Hence, we need to take this into account when generating
the daily COVID-19 new infection and death counts
based on the above PHI data file (of cumulative counts).

"Patched" PHI data (of cumulative counts)
-----------------------------------------
The "patched" PHI data can be viewed here:

https://github.com/kennethchu-statcan/covid19/blob/master/004-diagnostics/supplementary/raw-covid19-GoCInfobase-patched.csv

The unaltered PHI data (as downloaded on April 11, 2020) have been "patched" in precisely two ways for downstream analysis:

*  Records corresponding to days for which there were no new reported cases or deaths have been explictly added,
   by repeating the cumulative counts of the preceding day whenever necessary.

*  The data file has been extended backward in time to 2019-12-31 by prepending zeros.
   This is done to match the starting day of the time series downloaded from the ECDC
   (for the European countries studied in Flaxman et al.).

Comparison between the CSSE and (patched) PHI data:
---------------------------------------------------
Both sources report cumulative COVID-19 case and death count time series for Canada.
A comparison in tabular form can be viewed here:

https://github.com/kennethchu-statcan/covid19/blob/master/004-diagnostics/supplementary/diagnostics-compare-JHU-GoCInfobase-patched.csv

*  The two data sources appear to agree well with each other, though not perfectly.

*  Generally, the CSSE data appear to lag behind the PHI data for a small number of days.
   Otherwise, the two sources agree very well.

Comment on the ECDC data for Canada:
------------------------------------
The ECDC data for Canada contain data only at the national level, and cannot be used
for analysis at the provincial level.

