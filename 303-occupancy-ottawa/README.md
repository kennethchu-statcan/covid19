
# Hierarchical Bayesian model for Ottawa COVID-19 hospital occupancy forecast

This analysis/forecast pipeline is an adaptation of the hierarchical model
described by Flaxman et al. in:

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

We describe our adaption below.

## Summary: our adaptation of the Flaxman et al. model for Ottawa COVID-19 hospital occupancy forecast

For the Ottawa COVID-19 hospital occupancy forecast, we constructed two separate
hierarchical Bayesian models:

*   Model 1: daily new hospital admission counts,
*   Model 2: hospital length of stay.

The desired occupancy forecast is then obtained by suitably combining
the results of the two sub-models.

The present pipeline assesses the effectiveness of our model
for hospital occupancy forecast by applying separately the model
eight times, each time with a different training data cut-off
(more precisely, eight consecutive Mondays: 2020-11-13, 2020-11-30, ... , 2021-01-11),
and examines the agreement between the actual hospital occupancy
and the model forecast in the three-week window immediately folllowing
the training data cut-off.

# Model 1: Daily new hospital admission counts (reproduction number change-point model)

The main inference target of Model 1 is
(observed) COVID-19 daily new hospital admission counts.
Model 1 stipulates probabilistic assumptions on how
(observed) daily new admission counts are related to
(unobserved) daily new infection counts (via a **random delay**) and
(unobserved) time-varying reproduction number,
treating the latter two as latent variables (or, secondary inference targets).

The following is the list of the components of the model, and their relations
among one another.

*  Observed daily COVID-19 hospital admission count

   Assumed to follow a **Negative Binomial** distribution
   (which can be regarded as Gamma-mixture of Poisson distributions),
   which is specified by two parameters:

   *  *d<sub>t</sub>*
      = mean of the Negative Binomial
      = expected number of COVID-19 hospital admission on day *t*
   *  variance of the Negative Binomial, assumed to take the form
      *d<sub>t</sub> + (d<sub>t</sub>)<sup>2</sup>/&Psi;*

*  *&Psi;* is assumed to have been sampled from
   the rectified Gaussian distribution *Normal<sup>+</sup>(0,5)*.

*  The expected number *d<sub>t</sub>* of COVID-19 hospital admissions
   on day *t* is assumed to be given by:
   <br/>
   <br/>
   <img src="https://latex.codecogs.com/svg.latex?\,d_{t}\;=\;\left(\begin{array}{c}\textnormal{expected}\\\textnormal{hospital\;admission}\\\textnormal{count\;on\;day\;$t$}\end{array}\right)\;=\;\sum_{\tau=0}^{t-1}\left(\begin{array}{c}\textnormal{expected\;number\;of\;admissions\;on\;day\it\;t}\\\textnormal{among\;individuals\;infected\;on\;day\;}0\leq\tau\leq\;t\end{array}\right)"/>
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?{\color{white}d_{t}}\;=\;\sum_{\tau=0}^{t-1}\left(\begin{array}{c}\textnormal{number\;of}\\\textnormal{infections}\\\textnormal{on\;day}\;\tau\end{array}\right)\cdot{P}\left(\begin{array}{c}\textnormal{being\;admitted\;on}\\(t-\tau)^{\textnormal{th}}\;\textnormal{day}\\\textnormal{after\;infection}\end{array}\right)"/>
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?{\color{white}d_{t}}\;=\;\sum_{\tau=0}^{t-1}\,c_{\tau}\cdot\pi_{\,t-\tau}"/>
   <br/>

   for *t* = 1, 2, ... , where
   *  *c<sub>&tau;</sub>* is the *unobserved* number
      of **new** COVID-19 infected individuals on day *&tau;*, and
   *  *&pi;<sub>&tau;</sub>* is the probability that a COVID-19 infected
      person will be admitted to hospital for COVID-19
      *&tau;* days after COVID-19 infection.

*  Flaxman et al. assumed that each jurisdiction *m* has its own
   (weighted) *infection fatality ratio* IFR<sub>*m*</sub> (probability of COVID-19 death given COVID-19 infection).
   Conversely, in jurisdiction *m*, a COVID-19 infected individual has a probability of 1 - IFR<sub>*m*</sub>
   that he/she will not die from the disease, i.e. will recover.

   For a COVID-19 infected individual who dies from COVID-19, Flaxman et al. assumed,
   based on earlier studies, that the infection-to-death delay is the sum of two durations:
   the infection-to-(symptom-onset) delay, and the (symptom-onset)-to-death delay.
   The former is assumed -- for all jurisdictions -- to have been sampled from
   the Gamma distribution *&Gamma;(5.1,0.86)*, while the latter from *&Gamma;(18.8,0.45)*,
   where the (mean,cv)-parametrization of the Gamma distribution is used.

   In our case, we need to replace the (symptom-onset)-to-death delay with
   the (symptom-onset)-to-(hospital-admission) delay.
   For simplicity, we took this latter delay to be half of the former.

   More technically, these assumptions translate to the assumption that the parameter
   *&pi;<sub>&tau;</sub>* above is given by:
   </br>

   <img src="https://latex.codecogs.com/svg.latex?\pi_{1}\;=\;\int_{0}^{3/2}\pi(s)\,ds"/>
   </br>

   and
   </br>

   <img src="https://latex.codecogs.com/svg.latex?\pi_{\tau}\;=\;\int_{\tau-1/2}^{\tau+1/2}\pi(s)\,ds"/>
   </br>

   for *&tau;* = 2, 3, ... , where *&pi;* is the probability density
   of the of infection-to-hospitalization delay, and
   is assumed to have the form:

   <img src="https://latex.codecogs.com/svg.latex?\pi\;\sim\;\textnormal{\small{{IHR}}}_{}\cdot\left(\,\Gamma(5.1,0.86)+\dfrac{1}{2}\cdot\Gamma(18.8,0.45)\,\right)"/>

   where IHR stands for the COVID-19 *infection hospitalization rate* of Ottawa,
   and it is set to be 0.026 in our model.

*  The number *c<sub>t</sub>* of COVID-19 infected individuals newly infected
   on day *t* is assumed to satisfy the following recurrence relation:
   <br/>
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?\,c_{t}\;=\;\textnormal{number\;of\;infections\;on\;day}\;t"/>
   <br/>
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?{\color{white}c_{t}}\;=\;\left(\begin{array}{c}\textnormal{reproduction}\\\textnormal{number\;on\;day}\;t\end{array}\right)\cdot\left(\begin{array}{c}\textnormal{effective\;number\;of}\\\textnormal{infected\;individuals\;on\;day}\;t\end{array}\right)"/>
   <br/>
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?{\color{white}c_{t}}\;=\;R_{t}\;\cdot\;\sum_{\tau=0}^{t-1}\left(\begin{array}{c}\textnormal{number}\\\textnormal{of\,infections}\\\textnormal{on\;day}\;\tau\end{array}\right)\cdot\left(\begin{array}{c}\textnormal{an\;arbitrary\;new\;infection\;occurs}\\\textnormal{on}\;(t-\tau)^{th}\;\textnormal{day\;after\;infection}\end{array}\right)"/>
   <br/>
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?{\color{white}c_{t}}\;=\;R_{t}\cdot\sum_{\tau=0}^{t-1}\,c_{\tau}\cdot{g}_{t-\tau}"/>
   <br/>

   where *R<sub>t</sub>* is the COVID-19 **reproduction number** on day *t* (see below),
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?\,g_{1}\;=\;\int_{0}^{{3/2}}g(s)\,ds"/>
   <br/>

   and
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?\,g_{\tau}\;=\;\int_{\tau-1/2}^{\tau+1/2}g(s)\,ds\,,\;\;\textnormal{{for}}\;\tau\,=\,2,3,\ldots"/>
   <br/>

   where *g* is, for all jurisdictions, the probability density
   of the *serial interval distribution*.
   We remark that the discretized-to-the-day serial interval distribution
   (determined precisely by *g<sub>1</sub>*, *g<sub>2</sub>*, *g<sub>3</sub>*, ...)
   gives the probability that an infected individual will infect someone else
   on the *t*-th day after his/her original infection.

*  Lastly, our change-point model assumes that the COVID-19 reproduction number
   *R<sub>t</sub>* has the following form:

   <img src="https://latex.codecogs.com/svg.latex?\,R_{t}\;=\;R_{0}\cdot\exp\!\left(\;\sum^{{4}}_{k=1}\;{\alpha}_{k}\cdot{I}_{\{t\,-\,\gamma_{k}\}}\right)"/>
   <br/>

   where

   *   *&gamma;<sub>k</sub>* is
       the (random, unobserved) time of occurrence of
       the *k*-th change-point in the COVID-19
       time-varying reproduction number for jurisdiction *m*,
       with the following priors:
       </br>

       <img src="https://latex.codecogs.com/svg.latex?\,\gamma_{1}\;\sim\;\textnormal{\small{Uniform}}([\,2020/03/01\,,2020/03/28\,])"/>
       </br>

       <img src="https://latex.codecogs.com/svg.latex?\,\gamma_{2}\;\sim\;\textnormal{\small{Uniform}}([\,2020/07/05\,,2020/08/01\,])"/>
       </br>

       <img src="https://latex.codecogs.com/svg.latex?\,\gamma_{3}\;\sim\;\textnormal{\small{Uniform}}([\,2020/0{9}/0{6}\,,2020/10/03\,])"/>
       </br>

       <img src="https://latex.codecogs.com/svg.latex?\,\gamma_{4}\;\sim\;\textnormal{\small{Uniform}}([\,2020/11/01\,,\textnormal{maxChgPt4}\,])"/>
       </br>

       where **maxChgPt4** is last day of data availability less 14 days.

   *   *&alpha;<sub>k</sub>*
       is the (random, unobserved) log-linear change (''step size'')
       in reproduction number at the *k*-th change-point for jurisdiction *m*,
       with the following priors:
       </br>

       <img src="https://latex.codecogs.com/svg.latex?\,\alpha_{1}\;\sim\;\textnormal{\small{Uniform}}([-\log(4),0])\,"/>
       </br>

       <img src="https://latex.codecogs.com/svg.latex?\,\alpha_{2}\;\sim\;\textnormal{\small{Uniform}}([0,\log(1.5)])\,"/>
       </br>

       <img src="https://latex.codecogs.com/svg.latex?\,\alpha_{3}\;\sim\;\textnormal{\small{Uniform}}([-\log({1}{.}{5}),0])\,"/>
       </br>

       <img src="https://latex.codecogs.com/svg.latex?\,\alpha_{4}\;\sim\;\textnormal{\small{Uniform}}([-\log(1.1),\log(1.1)])"/>
       </br>

   *   *I(t-&gamma;<sub>k</sub>)* is the binary indicator variable,
       which indicates whether time *t* is
       before (*I(t-&gamma;<sub>k</sub>) = 0*) or
       after (*I(t-&gamma;<sub>k</sub>) = 1*)
       the *k*-th change-point.

   *   *R<sub>0</sub>* is the jurisdiction-specific initial reproduction number,
       assumed to follow:
       </br>

       <img src="https://latex.codecogs.com/svg.latex?\,R_{{0}}\;\sim\;\textnormal{\small{Normal}}(2.4,\vert\,\kappa\,\vert),\;\textnormal{\small{with}}\;\;\kappa\,\sim\,\textnormal{\small{Normal}}(0,0.5)"/>
       </br>

       where *&kappa;* is also a jurisdiction-independent (random, unobserved) parameter.


# Model 2: Ottawa COVID-19 hospital length of stay

Model 2 assumes that the Ottawa COVID-19 hospital length of stay follows
a Gamma distribution.
The main inference targets are thus simply
the shape and rate parameters of the family of Gamma distributions.
The observed data are the daily hospital admission counts and
daily discharge/death counts (derived from admission and midnight census counts).
The probabilistic assumptions of Model 2 stipulates the random delay
between hospital admission and discharge/death.

Observed variables:

*  The expected number *d<sub>t</sub>* of COVID-19 hospital admissions
   on day *t* is assumed to be given by:
   <br/>
   <br/>
   <img src="https://latex.codecogs.com/svg.latex?\,A_{t}\;:=\;\textnormal{number\;of\;COVID-19\;hospital\;admissions\;on\;day\;$t$}"/>
   <br/>
   <img src="https://latex.codecogs.com/svg.latex?\,C_{t}\;:=\;\textnormal{COVID-19\;hospital\;mid-night\;census\;count\;on\;day\;$t$}"/>
   <br/>

*  Unobserved (but unambiguously derivable) variables:
   <br/>
   <br/>
   <img src="https://latex.codecogs.com/svg.latex?\,{D}_{t}\;:=\;\textnormal{number\;of\;COVID-19\;discharges{/}deaths\;on\;day\;$t$}"/>
   <br/>

Deterministic relation among *A<sub>t</sub>*, *C<sub>t</sub>* and *D<sub>t</sub>*
(from which *D<sub>t</sub>* can be derived from *A<sub>t</sub>* and *C<sub>t</sub>*):
   <br/>
   <br/>
   <img src="https://latex.codecogs.com/svg.latex?\,C_{t}\;=\;\sum^{t}_{\tau=0}\,A_{\tau}\;-\;\sum^{t}_{\tau=0}\,D_{\tau}"/>
   <br/>

Likelihood assumptions:

   <img src="https://latex.codecogs.com/svg.latex?\,{D}_{t}\;\sim\;\textnormal{NegativeBinomial}\!\left(\,d_{t}\,,\,d_{t}+{\dfrac{d_{t}^{2}}{\psi}}\,\right)"/>
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?\,d_{t}\;=\;\left(\begin{array}{c}\textnormal{expected\;number\;of}\\\textnormal{dis{ch}arges{/}deaths}\\\textnormal{on\;day\;$t$}\end{array}\right)\;=\;\sum_{\tau=0}^{t-1}\left(\begin{array}{c}\textnormal{expected\;number\;of\;discharges{/}deaths\;on\;day\it\;t}\\\textnormal{among\;COVID{-}19\;patients\;admitted\;on\;day\;}0\leq\tau\leq\;t\end{array}\right)"/>
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?{\color{white}d_{t}}\;=\;\sum_{\tau=0}^{t-1}\left(\begin{array}{c}\textnormal{number\;of}\\\textnormal{admissions}\\\textnormal{on\;day}\;\tau\end{array}\right)\cdot\left(\begin{array}{c}\textnormal{proportion\;of}\\\textnormal{discharge{/}death}\\\textnormal{after\;$(t-\tau)$\;days}\end{array}\right)"/>
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?{\color{white}d_{t}}\;=\;\sum_{\tau=0}^{t-1}\,A_{\tau}\cdot\pi_{\,t-\tau}"/>
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?\pi_{\tau}\;:=\;P\!\left(\left.\begin{array}{c}\textnormal{discharge{/}death}\\\textnormal{on\;the\;$\tau^{\textnormal{th}}$\;day}\\\textnormal{after\;admission}\end{array}\right\vert\begin{array}{c}\textnormal{COVID-19}\\\textnormal{hospital}\\\textnormal{admission}\end{array}\right)\;=\;\left\{\begin{array}{ll}{\;\;}\int_{0}^{3{/}2}\;\,f_{{\textnormal{Gamma}}}(s;\alpha,\beta)\,d{s},&\textnormal{for}\;\tau=1\,\\{\,}\\\int_{\tau-1{/}2}^{\tau+1{/}2}\,f_{\textnormal{Gamma}}(s;\alpha,\beta)\,d{s},&\textnormal{for}\;{\tau=2,3,\ldots}\end{array}\right."/>
   <br/>

Prior distribution assumptions:

<img src="https://latex.codecogs.com/svg.latex?\alpha\;=\;\dfrac{1}{\mu\cdot\nu}"/>
<br/>

<img src="https://latex.codecogs.com/svg.latex?\beta\;=\;\dfrac{\alpha}{\mu}\;=\;\dfrac{1}{\mu^{2}\cdot\nu}"/>
<br/>

<img src="https://latex.codecogs.com/svg.latex?\mu\;\sim\;\textnormal{Uniform}([2,50])"/>
<br/>

<img src="https://latex.codecogs.com/svg.latex?\nu\;\sim\;\textnormal{Uniform}([0.1,2])"/>
<br/>

Note that
![](https://latex.codecogs.com/svg.latex?{\color{white}.}(\mu,\nu){\color{white}.})
gives the (mean,cv)-parametrization of the family of Gamma distributions,
instead of the more standard (shape,rate)-parametrization.
We find it intuitively easier to impose prior distributions
in terms of the (mean,cv)-parametrization.

#  Ottawa COVID-19 hospital occupancy forecast

   We now describe how the expected hospital occupancy forecast
   ![](https://latex.codecogs.com/svg.latex?{\color{white}.}\widehat{C}_{t}{\color{white}.})
   can be obtained from the estimates and forecasts from Model 1 and Model 2:
   <br/>

   <img src="https://latex.codecogs.com/svg.latex?\,\widehat{C}_{t}\;=\;\sum_{\tau=0}^{t}\,A_{\tau}{\;}{-}{\;}\sum_{\tau=0}^{t}\,D_{\tau}\;=\;\left(\,{\sum_{\tau=0}^{t_{*}}\,A_{\tau}}\,-{\sum_{\tau=t_{*}+1}^{t}\,\widehat{A}_{\tau}}\,\right)\,-\,\left(\,{\sum_{\tau=0}^{t_{*}}\,D_{\tau}}\,-{\sum_{\tau=t_{*}+1}^{t}\widehat{D}_{\tau}}\,\right)"/>

   <img src="https://latex.codecogs.com/svg.latex?\,{\color{white}\widehat{C}_{t}}\;=\;\left(\,{\sum_{\tau=0}^{t_{*}}\,A_{\tau}}\,-{\sum_{\tau=t_{*}+1}^{t}\,\widehat{A}_{\tau}}\,\right)\,-\,\left(\,{\sum_{\tau=0}^{t_{*}}\,D_{\tau}}\,-{\sum_{\tau=t_{*}+1}^{t}\widehat{D}_{\tau}}\,\right)"/>

   <img src="https://latex.codecogs.com/svg.latex?\,{\color{white}\widehat{C}_{t}}\;=\;{C_{t_{*}}}\;+\;\left(\,{\sum_{\tau=t_{*}}^{t}\,\widehat{A}_{\tau}}\,-{\sum_{\tau=t_{*}+1}^{t}\widehat{D}_{\tau}}\,\right)"/>

   where
   ![](https://latex.codecogs.com/svg.latex?{\color{white}.}t_{*}{\color{white}.})
   denotes last day of data availability (training data cut-off), and
   <br/>
   <br/>
   <img src="https://latex.codecogs.com/svg.latex?\,\widehat{D}_{t}\;=\;\sum_{\tau=0}^{t-1}\;A_{\tau}\cdot\widehat{\pi}_{t-\tau}"/>

   <img src="https://latex.codecogs.com/svg.latex?\,{\color{white}\widehat{D}_{t}}\;=\;\sum_{\tau=0}^{t_{*}}\;A_{\tau}\cdot\widehat{\pi}_{t-\tau}\;+\;\sum_{\tau=t_{*}+1}^{t-1}\;\widehat{A}_{\tau}\cdot\widehat{\pi}_{t-\tau}"/>

# What the pipeline does

# Requirements

*  R (statistical computing software)

*  R packages: bayesplot, cowplot, data.table dplyr, EnvStats, gdata, ggplot2,
   ggpubr, gridExtra, lubridate, matrixStats, readr, readxl, RColorBrewer,
   rstan, scales, tidyr

*  Tested on:
   *  R version v4.0.3, Ubuntu 20.04.1 LTS, x86_64-conda-linux-gnu (64-bit)
   *  R version v4.0.2, macOS 10.16, x86_64-apple-darwin17.0 (64-bit)

# How to execute the pipeline

Clone this repository by running the following at the command line:

```
git clone https://github.com/kennethchu-statcan/covid19.git
```

Change directory to the folder of this pipeline in the local cloned repository:

```
cd <LOCAL CLONED REPOSITORY>/303-occupancy-ottawa/
```

If you are using a Linux or macOS computer, execute the following shell script
(in order to run the full pipeline):

```
.\run-main.sh
```

This will trigger the creation of the output folder
`<LOCAL CLONED REPOSITORY>/303-changepoint-ottawa/output/`
if it does not already exist, followed by execution of the pipeline.
All output and log files will be saved to the output folder.
See below for information about the contents of the output folder.

# Input files

All required input data and metadata files are located in
`<LOCAL CLONED REPOSITORY>/000-data/2021-01-15.01/`.

*   __raw-covid19-Ottawa.csv__

    Ottawa COVID-19 open data (including daily new confirmed case counts,
    daily new hospital admission counts, daily hospital midnight census counts).

    Downloadable at: https://opendata.arcgis.com/datasets/6bfe7832017546e5b30c5cc6a201091b_0.csv

    See the following download script to examine how the data file was retrieved:

    `<LOCAL CLONED REPOSITORY>/000-data/2021-01-15.01/run-wget.sh`

*   __infection-hospitalization-rate.csv__

    This CSV file contains the estimates of the infection hospitalization rate
    (IHR) for Ottawa, estimated to be 0.026 at time of implementation
    of the present model.

*   __serial-interval.csv__

    This CSV file contains the assumed (discrete) *serial interval distribution*
    used by the model of Flaxman et al.
    Given a duration *t* (in days), the serial interval distribution gives
    the probability that an infected individual will infect someone else
    on the *t*-th day after his/her original infection.

# Main output files

*  __`<LOCAL CLONED REPOSITORY>/303-changepoint-ottawa/output/cutoff-2021-01-11/plot-occupancy-cowplot-01-Ottawa.png`__

   <img src="./supplementary/cutoff-2021-01-11/plot-occupancy-cowplot-01-Ottawa.png" width="900">

   Top panel: The vertical red bars illustrate the observed
   Ottawa COVID-19 daily **new hospital admission counts**.
   The dark blue ribbon indicates the 95% credibility
   interval of the estimated *expected*
   Ottawa COVID-19 daily new hospital admission counts,
   while the light blue indicates the 50% credibility interval.
   The vertical dashed line towards the right indicates the training data
   cut-off, which is 2021-01-11 in the plot above.
   The light orange ribbon indicates the 95% credibility interval of the
   **forecast** expected daily new hospital admissions,
   while the dark orange indicates the 50% credibility interval.

   Middle panel: The vertical black bars illustrate the observed
   Ottawa COVID-19 daily hospital **discharges/deaths**.
   The cyan ribbon indicates the 95% credibility
   interval of the estimated *expected*
   Ottawa COVID-19 daily hospital discharges/deaths,
   while the red line indicates the posterior median.
   The light orange ribbon indicates the 95% credibility interval of the
   forecast expected
   Ottawa COVID-19 daily hospital discharges/deaths,
   while the dark orange indicates the 50% credibility interval.

   Bottom panel: Similar to middle panel, but for
   Ottawa COVID-19 daily hospital **midnight census counts**.

*  __`<LOCAL CLONED REPOSITORY>/303-changepoint-ottawa/output/cutoff-2021-01-11/plot-occupancy-cowplot-01-Ottawa1.png`__

   <img src="./supplementary/cutoff-2021-01-11/plot-occupancy-cowplot-01-Ottawa1.png" width="900">

   This plot illustrates the results of a replicate run
   (which we call **Ottawa1**).
   The purpose of the replication here is to provide minimal assessment
   of the stability of the model with respect to random initializations
   of the MCMC inference procedure.

*  __`<LOCAL CLONED REPOSITORY>/303-changepoint-ottawa/output/cutoff-2021-**-**/plot-occupancy-cowplot-01-Ottawa.png`__

   Counterparts of the preceding plots for the other training data cut-off
   dates (8 consecutive Mondays):
   2020-11-23, 2020-11-30, ... , 2021-01-11.

*  __`<LOCAL CLONED REPOSITORY>/303-changepoint-ottawa/output/cutoff-2021-01-11/plot-ChgPt-cowplot-Ottawa.png`__

   <img src="./supplementary/cutoff-2021-01-11/plot-ChgPt-cowplot-Ottawa.png" width="900">

   Main output graphic of Model 1.

   First panel (from top):
   The vertical red bars illustrate the observed
   Ottawa COVID-19 daily **new confirmed case counts**.
   (Note that the true infection counts are unknown.)
   The dark blue ribbon indicates the 95% credibility interval
   of the estimated *expected*
   Ottawa COVID-19 daily true new infection counts,
   while the light blue indicates the 50% credibility interval.
   The vertical dashed line towards the right indicates the training data
   cut-off, which is 2021-01-11 in the plot above.

   Second panel:
   The vertical red bars illustrate the observed
   Ottawa COVID-19 daily **new hospital admission counts**.
   The dark blue ribbon indicates the 95% credibility
   interval of the estimated *expected*
   Ottawa COVID-19 daily new hospital admission counts,
   while the light blue indicates the 50% credibility interval.
   The light orange ribbon indicates the 95% credibility interval of the
   **forecast** expected daily new hospital admissions,
   while the dark orange indicates the 50% credibility interval.

   Third panel:
   The light green ribbon indicates the 95% credibility interval of the
   expected daily reproduction number,
   while the dark green indicates the 50% credibility interval.

   Fourth panel:
   The daily reproduction number in Model 1 is modelled via a
   change point model, with four change points.
   This panel illustrates the posterior distributions of the occurrence
   times, change directions and change magnitudes of the four change points.

*  __`<LOCAL CLONED REPOSITORY>/303-changepoint-ottawa/output/cutoff-2021-01-11/plot-LoS-expected-cowplot-Ottawa1.png`__

   <img src="./supplementary/cutoff-2021-01-11/plot-LoS-expected-cowplot-Ottawa1.png" width="900">

   Main output graphic of Model 2.

   First panel (from top):
   The vertical black bars illustrate the observed
   Ottawa COVID-19 daily hospital **new admission counts**.

   Second panel:
   The vertical black bars illustrate the observed
   Ottawa COVID-19 daily hospital **discharges/deaths**.
   The cyan ribbon indicates the 95% credibility
   interval of the estimated *expected*
   Ottawa COVID-19 daily hospital discharges/deaths,
   while the red line indicates the posterior median.

   Bottom panel: Similar to second panel, but for
   Ottawa COVID-19 daily hospital **midnight census counts**.

*  __`<LOCAL CLONED REPOSITORY>/303-changepoint-ottawa/output/cutoff-2021-01-11/plot-LoS-scatter-mu-cv-Ottawa.png`__

   <img src="./supplementary/cutoff-2021-01-11/plot-LoS-scatter-mu-cv-Ottawa.png" width="900">

   (Joint) posterior distribution of the model parameters of Model 2.
   For ease of interpretation, we illustrate the posterior distribution
   with respect to the (mean,cv)-parametrization
   of the family of Gamma distributions,
   instead of the more standard (shape,rate)-parametrization,
   though the latter is the one used during computations.
