
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

Recommendations
---------------
*  A comparison of the three data sets above suggests that using a certain "patched" version
   of the PHI data set of PHAC should be the most straightforward.

Observations on the PHI data
----------------------------
*  During the early phase of the COVID-19 pandemic, the PHI data (as downloaded on April 11, 2020)
   do not contain records for days when there were no new reported COVID-19 infections or deaths.

   For example, in the following file (as downloaded on April 11, 2020) 

   https://health-infobase.canada.ca/src/data/covidLive/covid19.csv

   the first three days with reported data for British Columbia are:
   2020-01-31, 2020-02-08 and 2020-02-16,
   whose respective reported confirmed case counts are: 1, 4 and 5.

   In particular, the above file (again, as downloaded on April 11, 2020) contains no records
   for British Columbia for 2020-02-01 through 2020-02-07,
   during which presumably there were neither reported new COVID-19 confirmed cases nor deaths.

   Hence, one needs to take this into account when generating the daily COVID-19 new infection
   and death counts based on the above PHI data file (of cumulative counts).

Comparison between the PHI and CSSE data:
-----------------------------------------
Both sources report cumulative COVID-19 case and death count time series for Canada.
A comparison in tabular form can be viewed here:

https://github.com/kennethchu-statcan/covid19/blob/master/004-diagnostics/supplementary/diagnostics-compare-JHU-GoCInfobase-raw.csv

*  The two data sources appear to agree well with each other, though not perfectly.

*  Generally, the CSSE data appear to lag behind the PHI data for a small number of days.
   Otherwise, the two sources agree very well.

*  During the early phase of the COVID-19 pandemic in Canada, the PHI data 
*&Psi;* is assumed to have been sampled from
   the rectified Gaussian distribution *Normal<sup>+</sup>(0,5)*.

*  The expected number *d<sub>m,t</sub>* of COVID-19 deaths
   for country *m* on day *t* is assumed to be given by:

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;d_{m,t}\;=\;\sum_{\tau=0}^{t-1}\,c_{m,\tau}\cdot\pi_{m,t-\tau}"/>

   for *t* = 1, 2, ... , where
   *  *c<sub>m,&tau;</sub>* is the *unobserved* number of **new** COVID-19 infected individuals
      in country *m*, on day *&tau;*, and
   *  *&pi;<sub>m,&tau;</sub>* is the probability, for country *m*,
      that a COVID-19 infected person will die *&tau;* days after COVID-19 infection.

*  Flaxman et al. assumed that each country *m* has its own 
   (weighted) *infection fatality ratio* IFR<sub>*m*</sub> (probability of COVID-19 death given COVID-19 infection).
   Conversely, in country *m*, a COVID-19 infected individual has a probability of 1 - IFR<sub>*m*</sub>
   that he/she will not die from the disease, i.e. will recover.

   For a COVID-19 infected individual who dies from COVID-19, Flaxman et al. assumed,
   based on earlier studies, that the infection-to-death time is the sum of two durations:
   the infection-to-(onset-of-symptom) time, and the (onset-of-symptom)-to-death time.
   The former is assumed -- for all countries -- to have been sampled from
   the Gamma distribution *&Gamma;(5.1,0.86)*, while the latter from *&Gamma;(18.8,0.45)*.

   More technically, these assumptions translate to the assumption that the parameter
   *&pi;<sub>m,&tau;</sub>* above is given by:

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;\pi_{m,1}\;=\;\int_{0}^{3/2}\pi_{m}(s)\,ds"/>

   and

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;\pi_{m,\tau}\;=\;\int_{\tau-1/2}^{\tau+1/2}\pi_{m}(s)\,ds"/>

   for *&tau;* = 2, 3, ... , where *&pi;<sub>m</sub>* is the probability density
   of the of infection-to-death time of country *m*, and is assumed to have the form:

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;\pi_{m}\;\sim\;\textnormal{\small{IFR}}_{m}\cdot\left(\,\Gamma(5.1,0.86)+\Gamma(18.8,0.45)\,\right)"/>

   where IFR<sub>*m*</sub> stands for the *weighted infection fatality ratio* of country *m*,
   whose definition/estimation is described in the original paper by Flaxman et al. cited above,
   as well as in

   https://www.thelancet.com/journals/laninf/article/PIIS1473-3099(20)30243-7

*  The number *c<sub>m,t</sub>* of COVID-19 infected individuals
   newly infected on day *t* for country *m* is assumed to satisfy
   the following recurrence relation:

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;c_{m,t}\;=\;R_{m,t}\cdot\sum_{\tau=0}^{t-1}\,c_{m,\tau}\cdot{g}_{t-\tau}"/>

   where *R<sub>m,t</sub>* is the COVID-19 **reproduction number** of country *m*
   on day *t* (see below),

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;g_{1}\;=\;\int_{0}^{3/2}g(s)\,ds"/>

   and

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;g_{\tau}\;=\;\int_{\tau-1/2}^{\tau+1/2}g(s)\,ds"/>

   for *&tau;* = 2, 3, ... , where *g* is, for all countries, the probability density
   of the *serial interval distribution*.
   We remark that the discretized-to-the-day serial interval distribution
   (determined precisely by *g<sub>1</sub>*, *g<sub>2</sub>*, *g<sub>3</sub>*, ...)
   gives the probability that an infected individual will infect someone else
   on the *t*-th day after his/her original infection.

*  Lastly, Flaxman et al. assumed that the COVID-19 reproduction number
   *R<sub>m,t</sub>* has the following form:

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;R_{m,t}\;=\;R_{m,0}\cdot\exp\!\left(\,-\,\sum^{K}_{k=1}\alpha_{k}\cdot{I}_{m,k,t}\,\right)"/>

   where
   
   *   *I<sub>m,k,t</sub>* is the (observed) binary indicator variable for country *m*,
       intervention measure *k*, and day *t*.

   *   *&alpha;<sub>k</sub>*
       -- assumed to have been sampled from *&Gamma;(0.5,1)* --
       is the (random, unobserved) country-independent
       log-linear effect size parameter due to intervention measure *k*,

   *   *R<sub>m,0</sub>* is the country-specific initial reproduction number,
       assumed to follow:

       <img src="https://latex.codecogs.com/svg.latex?\Large&space;R_{m,0}\;\sim\;\textnormal{\small{Normal}}(2.4,\vert\,\kappa\,\vert),\;\textnormal{\small{with}}\;\;\kappa\,\sim\,\textnormal{\small{Normal}}(0,0.5)"/>

       where *&kappa;* is also a country-independent (random, unobserved) parameter.

Requirements
------------
*  Internet connection (to download up-to-date COVID-19 data)
*  R v3.6.2
*  R packages: gdata, EnvStats, ggplot2, tidyr, dplyr, rstan, data.table, lubridate, gdata,
   matrixStats, scales, gridExtra, ggpubr, bayesplot, cowplot, readr

How to execute the pipeline
---------------------------
Clone this repository by running the following at the command line:

```
git clone https://github.com/kennethchu-statcan/covid19.git
```

Change directory to the folder of this pipeline in the local cloned repository:

```
cd <LOCAL CLONED REPOSITORY>/003-imperial-model-1.0/
```

If you are using a Linux or macOS computer, execute the following shell script (in order to run the full pipeline):

```
.\run-main.sh
```

If you are using a Windows computer, execute the following batch script at the Command Prompt instead (NOT tested):

```
.\run-main.bat
```

This will trigger the creation of the output folder
`<LOCAL CLONED REPOSITORY>/003-imperial-model-1.0/output/`
if it does not already exist, followed by execution of the pipeline.
All output and log files will be saved to the output folder.
See below for information about the contents of the output folder.

Input files
-----------
Up-to-date COVID-19 death count time series for different countries are downloaded
by the pipeline at run-time at the following
European Centre for Disease Prevention and Control open-data URL:

https://opendata.ecdc.europa.eu/covid19/casedistribution/csv

Other input files are located in
`<LOCAL CLONED REPOSITORY>/000-data/2020-04-05.01/`.

* __interventions.csv__

    This CSV file contains the COVID-19 intervention histories 
    (social distancing measures and the dates they were instituted)
    of eleven European countries.
    
    It is a simplified version of the original one supplied
    by Flaxman et al, in the sense that data not directly used
    by the model have been removed.

* __weighted\_fatality.csv__

    This CSV file contains the estimates of the
    _weighted infection fatality ratio_
    for the eleven Europe countries.
    These are fixed country-specific parameters used by the model
    of Flaxman et al.

    The *infection fatality ratio* refers to the conditional probability
    of COVID-19 death given COVID-19 infection.
    The weighting refers to the adjustment required when generating
    these estimates in order to mitigate the severe and
    demography/age-dependent COVID-19 underreporting.
    The estimation procedure of the weighted infection fatality
    ratios is described in this article:

    https://www.thelancet.com/journals/laninf/article/PIIS1473-3099(20)30243-7/fulltext

* __ages.csv__

    This CSV file contains the estimates of the sizes of different age groups
    in the respective populations of the eleven European countries.

* __serial\_interval.csv__

    This CSV file contains the assumed (discrete) *serial interval distribution*
    used by the model of Flaxman et al.
    Given a duration *t* (in days), the serial interval distribution gives
    the probability that an infected individual will infect someone else
    on the *t*-th day after his/her original infection.

Main output files
-----------------

*  __output-base-3-panel-Italy.png__

   ![three-panel plot, Italy](./supplementary/output-base-3-panel-Italy.png)

   The left-most panel shows the number of confirmed COVID-19 infections by day,
   as well as the 50% and 95% credible intervals across time
   for the total number of infections as estimated by the model
   of Flaxman et al., based on the given data.

   The middle panel shows the equivalent for the number of deaths.

   The right-most panel shows the 50% and 95% credible intervals through time
   of the *reproduction number* *R<sub>t</sub>* at time *t*,
   annotated by the institution times of the various intervention measures.

   Similarly for the rest of the countries.

*  __output-base-forecast-Italy.png__

   <img src="./supplementary/output-base-forecast-Italy.png" width="750">

   Histogram, for Italy, of
   the (log-transformed) number of COVID-19 deaths by day,
   overlaid with the corresponding posterior means and 95% credible intervals
   across time for the forecast of the number of COVID-19 deaths.

*  Similarly for the rest of the countries.

*  __output-base-covars-alpha.png__

   <img src="./supplementary/output-base-covars-alpha.png" width="500">

   Posterior means and 90% credible intervals of the (country-independent)
   effect size parameters:

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;\exp\!\left(\,-\,\alpha_{k}\,\right)"/>

   Note that the above plot suggests that lockdown has the strongest
   reduction effect on the reproduction number among the intervention
   measures considered.

*  __output-base-covars-mu.png__

   <img src="./supplementary/output-base-covars-mu.png" width="500">

   Posterior means and 90% credible intervals of the
   country-specific initial COVID-19 reproduction numbers.

*  __output-base-covars-final-rt.png__

   <img src="./supplementary/output-base-covars-final-rt.png" width="500">

   Posterior means and 90% credible intervals of the
   country-specific final COVID-19 reproduction numbers.

