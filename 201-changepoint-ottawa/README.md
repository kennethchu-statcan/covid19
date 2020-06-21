
Hierarchical Bayesian change-point model for estimation of COVID-19 time-varying reproduction number based on death count time series
=====================================================================================================================================

This analysis pipeline is an adaptation of the hierarchical model described by Flaxman et al. in:

https://www.imperial.ac.uk/mrc-global-infectious-disease-analysis/covid-19/report-13-europe-npi-impact/

or directly:

https://www.imperial.ac.uk/media/imperial-college/medicine/mrc-gida/2020-03-30-COVID19-Report-13.pdf

The authors:

*  sought to estimate the effect of the various COVID-19 (social distancing)
   intervention measures on the jurisdiction-specific time-varying
   reproduction number *R<sub>m,t</sub>*,
   for jurisdiction *m*, as a function of time *t* (in days),

*  proceeded by fitting a hierarchical Bayesian model to the COVID-19 death count
   time series from the following eleven European jurisdictions:
   Austria,
   Belgium,
   Denmark,
   France,
   Germany,
   Italy,
   Norway,
   Spain,
   Sweden,
   Switzerland, and
   the United Kingdom

*  generated COVID-19 death count forecast using the fitted model.

The authors have very kindly made available their code here:

https://github.com/ImperialCollegeLondon/covid19model/releases/tag/v1.0

We were able to reproduce the results of the above article
(based on data available up to March 28, 2020, with a 7-day death count forecast window).

Change-point model
------------------
We have modified the original model of Flaxman et al. in an attempt to develop a model
that could detect significant changes in the COVID-19 time-varying reproduction numbers
for a given collection of jurisdictions, based on the COVID-19 death count time series
for these jurisdictions.

Recall that one of the key objectives of the original Flaxman et al. model was to estimate
the effects of social distancing measures on COVID-19 transmissibility (more precisely,
time-varying reproduction number).
In their model, for ech given jurisdiction, its time-varying reproduction number results
from the multiplicative effects of the different types of social distancing measures
on the initial reproduction number, as these measures are imposed in time.
Note in particular that the Flaxman et al. model assumes that the time-varying reproduction
number is piecewise constant in time.
We modified the Flaxman et al. model by replacing the social distancing effects with
a change-point model instead, so as to estimate the timing of change points in the
(still piecewise constant) time-varying reproduction number, and the
magnitudes of change at these change points.

In addition, we have also included slight modifications in order to:

*  use data up June 21, 2020 for the 11 European jurisdictions
*  included the following four Canadian provinces in the analysis: Alberta, British Columbia, Ontario, Québec
*  included the following one Canadian city in the analysis: Ottawa (data up to June 8, 2020)

General assumed structure of hierarchical models
------------------------------------------------
*  The mechanism that generated the actual observed data belongs to a certain parametric family
   of related mechanisms (probability distributions).
   This parametric family of distributions is parametrized by a (finite) number of parameters.
*  These parameters are themselves considered **unobserved** random quantities, which had been
   sampled from their own respective pobability distributions,
   which in turn have their own (hyper)parameters.
*  This may go on for several "layers", hence the nomenclature *hierarchical models*.
*  (Bayesian) inference in this context refers to estimating posterior distributions
   (or sometimes, more easily computable derived quantities)
   for the (hyper)parameters based on observed data, and prior probabilistic assumptions.

Brief description of the hierarchical structure of the model of Flaxman et al.
------------------------------------------------------------------------------
*  Observed COVID-19 death count, for given (jurisdiction,day)

   Assumed to follow a **Negative Binomial** distribution
   (which can be regarded as Gamma-mixture of Poisson distributions),
   which is specified by two parameters:

   *  *d<sub>m,t</sub>*
      = mean of the Negative Binomial
      = expected number of COVID-19 deaths for jurisdiction *m* on day *t*
   *  variance of the Negative Binomial, which the authors assumed to have the form
      *d<sub>m,t</sub> + (d<sub>m,t</sub>)<sup>2</sup>/&Psi;*

*  *&Psi;* is assumed to have been sampled from
   the rectified Gaussian distribution *Normal<sup>+</sup>(0,5)*.

*  The expected number *d<sub>m,t</sub>* of COVID-19 deaths
   for jurisdiction *m* on day *t* is assumed to be given by:

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;d_{m,t}\;=\;\sum_{\tau=0}^{t-1}\,c_{m,\tau}\cdot\pi_{m,t-\tau}"/>

   for *t* = 1, 2, ... , where
   *  *c<sub>m,&tau;</sub>* is the *unobserved* number of **new** COVID-19 infected individuals
      in jurisdiction *m*, on day *&tau;*, and
   *  *&pi;<sub>m,&tau;</sub>* is the probability, for jurisdiction *m*,
      that a COVID-19 infected person will die *&tau;* days after COVID-19 infection.

*  Flaxman et al. assumed that each jurisdiction *m* has its own
   (weighted) *infection fatality ratio* IFR<sub>*m*</sub> (probability of COVID-19 death given COVID-19 infection).
   Conversely, in jurisdiction *m*, a COVID-19 infected individual has a probability of 1 - IFR<sub>*m*</sub>
   that he/she will not die from the disease, i.e. will recover.

   For a COVID-19 infected individual who dies from COVID-19, Flaxman et al. assumed,
   based on earlier studies, that the infection-to-death time is the sum of two durations:
   the infection-to-(onset-of-symptom) time, and the (onset-of-symptom)-to-death time.
   The former is assumed -- for all jurisdictions -- to have been sampled from
   the Gamma distribution *&Gamma;(5.1,0.86)*, while the latter from *&Gamma;(18.8,0.45)*.

   More technically, these assumptions translate to the assumption that the parameter
   *&pi;<sub>m,&tau;</sub>* above is given by:

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;\pi_{m,1}\;=\;\int_{0}^{3/2}\pi_{m}(s)\,ds"/>

   and

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;\pi_{m,\tau}\;=\;\int_{\tau-1/2}^{\tau+1/2}\pi_{m}(s)\,ds"/>

   for *&tau;* = 2, 3, ... , where *&pi;<sub>m</sub>* is the probability density
   of the of infection-to-death time of jurisdiction *m*, and is assumed to have the form:

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;\pi_{m}\;\sim\;\textnormal{\small{IFR}}_{m}\cdot\left(\,\Gamma(5.1,0.86)+\Gamma(18.8,0.45)\,\right)"/>

   where IFR<sub>*m*</sub> stands for the *weighted infection fatality ratio* of jurisdiction *m*,
   whose definition/estimation is described in the original paper by Flaxman et al. cited above,
   as well as in

   https://www.thelancet.com/journals/laninf/article/PIIS1473-3099(20)30243-7

*  The number *c<sub>m,t</sub>* of COVID-19 infected individuals
   newly infected on day *t* for jurisdiction *m* is assumed to satisfy
   the following recurrence relation:

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;c_{m,t}\;=\;R_{m,t}\cdot\sum_{\tau=0}^{t-1}\,c_{m,\tau}\cdot{g}_{t-\tau}"/>

   where *R<sub>m,t</sub>* is the COVID-19 **reproduction number** of jurisdiction *m*
   on day *t* (see below),

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;g_{1}\;=\;\int_{0}^{3/2}g(s)\,ds"/>

   and

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;g_{\tau}\;=\;\int_{\tau-1/2}^{\tau+1/2}g(s)\,ds"/>

   for *&tau;* = 2, 3, ... , where *g* is, for all jurisdictions, the probability density
   of the *serial interval distribution*.
   We remark that the discretized-to-the-day serial interval distribution
   (determined precisely by *g<sub>1</sub>*, *g<sub>2</sub>*, *g<sub>3</sub>*, ...)
   gives the probability that an infected individual will infect someone else
   on the *t*-th day after his/her original infection.

*  Lastly, Flaxman et al. assumed that the COVID-19 reproduction number
   *R<sub>m,t</sub>* has the following form:

   <img src="https://latex.codecogs.com/svg.latex?\Large&space;R_{m,t}\;=\;R_{m,0}\cdot\exp\!\left(\;\sum^{3}_{k=1}\alpha_{m,k}\cdot{I}_{\{t\,-\,\gamma_{m,k}\}}\,\right)"/>

   where

   *   *&gamma;<sub>m,k</sub>* is the time of occurrence of
       the (random, unobserved) *k*-th change-point in the COVID-19
       time-varying reproduction number for jurisdiction *m*.

   *   *&alpha;<sub>m,k</sub>*
       is the (random, unobserved) log-linear change (''step size'')
       in reproduction number at the *k*-th change-point for jurisdiction *m*.

       <img src="https://latex.codecogs.com/svg.latex?\Large&space;\alpha_{m,1},\,\alpha_{m,2}\;\sim\;\textnormal{\small{Uniform}}([-\log(4),\log(4)]),\;\textnormal{\small{for\;each}}\;\,m"/>

       <img src="https://latex.codecogs.com/svg.latex?\Large&space;\alpha_{m,3}\;\sim\;\textnormal{\small{Uniform}}(()-\infty,\infty)),\;\textnormal{\small{for\;each}}\;\,m"/>

   *   *I(t-&gamma;<sub>m,k</sub>)* is the binary indicator variable,
       for jurisdiction *m*,
       which indicates whether time *t* is
       before (*I(t-&gamma;<sub>m,k</sub>) = 0*) or
       after (*I(t-&gamma;<sub>m,k</sub>) = 1*)
       the *k*-th change-point of jurisdiction *m*.

   *   *R<sub>m,0</sub>* is the jurisdiction-specific initial reproduction number,
       assumed to follow:

       <img src="https://latex.codecogs.com/svg.latex?\Large&space;R_{m,0}\;\sim\;\textnormal{\small{Normal}}(2.4,\vert\,\kappa\,\vert),\;\textnormal{\small{with}}\;\;\kappa\,\sim\,\textnormal{\small{Normal}}(0,0.5)"/>

       where *&kappa;* is also a jurisdiction-independent (random, unobserved) parameter.

Requirements
------------
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
cd <LOCAL CLONED REPOSITORY>/201-changepoint-ottawa/
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
`<LOCAL CLONED REPOSITORY>/201-changepoint-ottawa/output/`
if it does not already exist, followed by execution of the pipeline.
All output and log files will be saved to the output folder.
See below for information about the contents of the output folder.

Input files
-----------
All required input data and metadata files are located in
`<LOCAL CLONED REPOSITORY>/000-data/2020-05-10.01/`.

*   __raw-covid19-ECDC.csv__

    COVID-19 case and death count time series for the eleven European jurisdictions
    considered by Flaxman et al.
    It was downloaded on May 10, 2020 from
    the European Centre for Disease Prevention and Control open-data URL:

    https://opendata.ecdc.europa.eu/covid19/casedistribution/csv

*   __raw-covid19-GoCInfobase.csv__

    COVID-19 case and death count time series for the Canadian provinces and territories.
    It was downloaded on May 10, 2020 from the following URL of PHAC:

    https://health-infobase.canada.ca/src/data/covidLive/covid19.csv

*   __interventions-europe.csv__

    This CSV file contains the COVID-19 intervention histories
    (social distancing measures and the dates they were instituted)
    of the eleven European jurisdictions.

    It is a simplified version of the original one supplied
    by Flaxman et al, in the sense that data not directly used
    by the model have been removed.

*   __interventions-canada.csv__

    The counterpart of interventions-europe.csv for the Canadian provinces

*   __weighted-fatality-europe.csv__

    This CSV file contains the estimates of the
    _weighted infection fatality ratio_ (wIFR)
    for the eleven Europe jurisdictions.
    These are fixed jurisdiction-specific parameters used by the model
    of Flaxman et al.

    The *infection fatality ratio* refers to the conditional probability
    of COVID-19 death given COVID-19 infection.
    The weighting refers to the adjustment required when generating
    these estimates in order to mitigate the severe and
    demography/age-dependent COVID-19 underreporting.
    The estimation procedure of the weighted infection fatality
    ratios is described in this article:

    https://www.thelancet.com/journals/laninf/article/PIIS1473-3099(20)30243-7/fulltext

*   __weighted-fatality-canada.csv__

    The counterpart of weighted-fatality-europe.csv for the Canadian provinces

    However, we are still in the process of estimating
    the weighted infection fatality ratios
    for the Canadian provinces.
    As a result, this input parameter file currently contains NULL values.
    For the time being, this file is populated at run-time via donor imputation
    using the European jurisdictions as donor pool.

    The current (temporary) imputed wIFR values for the Canadian provinces can be seen here:

    https://github.com/kennethchu-statcan/covid19/blob/master/201-changepoint-ottawa/supplementary/input-wIFR.csv

*   __ages.csv__

    This CSV file contains the estimates of the sizes of different age groups
    in the respective populations of the eleven European jurisdictions.

*   __serial-interval.csv__

    This CSV file contains the assumed (discrete) *serial interval distribution*
    used by the model of Flaxman et al.
    Given a duration *t* (in days), the serial interval distribution gives
    the probability that an infected individual will infect someone else
    on the *t*-th day after his/her original infection.

Main output files
-----------------

*  __output-change-point-covars-R0.png__

   <img src="./supplementary/output-change-point-covars-R0.png" width="500">

   Posterior means and 90% credible intervals of the
   jurisdiction-specific initial COVID-19 reproduction numbers.

*  __output-change-point-covars-final-rt.png__

   <img src="./supplementary/output-change-point-covars-final-rt.png" width="500">

   Posterior means and 90% credible intervals of the
   jurisdiction-specific final COVID-19 reproduction numbers.

*  __output-change-point-3-panel-Italy.png__

   ![three-panel plot, Italy](./supplementary/output-change-point-3-panel-Italy.png)

   The top panel shows the number of new confirmed COVID-19 infections by day,
   as well as the 50% and 95% credible intervals across time
   for the daily number of new infections as estimated by the change-point
   model, based on the given data.

   The middle panel shows the equivalent for the number of deaths.

   The bottom panel shows the 50% and 95% credible intervals through time
   of the *reproduction number* *R<sub>t</sub>* at time *t*,
   annotated by the institution times of the various intervention measures.

*  __output-change-point-stepsize-vs-chgpt-Italy.png__

   <img src="./supplementary/output-change-point-stepsize-vs-chgpt-Italy.png" width="900">

*  __output-change-point-forecast-Italy.png__

   <img src="./supplementary/output-change-point-forecast-Italy.png" width="750">

   Histogram, for Italy, of
   the (log-transformed) number of COVID-19 deaths by day,
   overlaid with the corresponding posterior means and 95% credible intervals
   across time for the forecast of the number of COVID-19 deaths.

*  Similarly for the rest of the jurisdictions:

   *  __output-change-point-3-panel-AB.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-AB.png)

   *  __output-change-point-3-panel-BC.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-BC.png)

   *  __output-change-point-3-panel-ON.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-ON.png)

   *  __output-change-point-3-panel-QC.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-QC.png)

   *  __output-change-point-3-panel-Austria.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-Austria.png)

   *  __output-change-point-3-panel-Belgium.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-Belgium.png)

   *  __output-change-point-3-panel-Denmark.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-Denmark.png)

   *  __output-change-point-3-panel-France.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-France.png)

   *  __output-change-point-3-panel-Germany.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-Germany.png)

   *  __output-change-point-3-panel-Italy.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-Italy.png)

   *  __output-change-point-3-panel-Norway.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-Norway.png)

   *  __output-change-point-3-panel-Spain.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-Spain.png)

   *  __output-change-point-3-panel-Sweden.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-Sweden.png)

   *  __output-change-point-3-panel-Switzerland.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-Switzerland.png)

   *  __output-change-point-3-panel-United_Kingdom.png__

   ![three-panel plot](./supplementary/output-change-point-3-panel-United_Kingdom.png)

   *  __output-change-point-forecast-AB.png__

   <img src="./supplementary/output-change-point-forecast-AB.png" width="750">

   *  __output-change-point-forecast-BC.png__

   <img src="./supplementary/output-change-point-forecast-BC.png" width="750">

   *  __output-change-point-forecast-ON.png__

   <img src="./supplementary/output-change-point-forecast-ON.png" width="750">

   *  __output-change-point-forecast-QC.png__

   <img src="./supplementary/output-change-point-forecast-QC.png" width="750">

   *  __output-change-point-forecast-Austria.png__

   <img src="./supplementary/output-change-point-forecast-Austria.png" width="750">

   *  __output-change-point-forecast-Belgium.png__

   <img src="./supplementary/output-change-point-forecast-Belgium.png" width="750">

   *  __output-change-point-forecast-Denmark.png__

   <img src="./supplementary/output-change-point-forecast-Denmark.png" width="750">

   *  __output-change-point-forecast-France.png__

   <img src="./supplementary/output-change-point-forecast-France.png" width="750">

   *  __output-change-point-forecast-Germany.png__

   <img src="./supplementary/output-change-point-forecast-Germany.png" width="750">

   *  __output-change-point-forecast-Italy.png__

   <img src="./supplementary/output-change-point-forecast-Italy.png" width="750">

   *  __output-change-point-forecast-Norway.png__

   <img src="./supplementary/output-change-point-forecast-Norway.png" width="750">

   *  __output-change-point-forecast-Spain.png__

   <img src="./supplementary/output-change-point-forecast-Spain.png" width="750">

   *  __output-change-point-forecast-Sweden.png__

   <img src="./supplementary/output-change-point-forecast-Sweden.png" width="750">

   *  __output-change-point-forecast-Switzerland.png__

   <img src="./supplementary/output-change-point-forecast-Switzerland.png" width="750">

   *  __output-change-point-forecast-United_Kingdom.png__

   <img src="./supplementary/output-change-point-forecast-United_Kingdom.png" width="750">
