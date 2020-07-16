
command.arguments <- commandArgs(trailingOnly = TRUE);
data.directory    <- normalizePath(command.arguments[1]);
code.directory    <- normalizePath(command.arguments[2]);
output.directory  <- normalizePath(command.arguments[3]);

# add custom library using .libPaths()
print( data.directory   );
print( code.directory   );
print( output.directory );
print( format(Sys.time(),"%Y-%m-%d %T %Z") );

start.proc.time <- proc.time();

# set working directory to output directory
setwd( output.directory );

##################################################
# source supporting R code
code.files <- c(
    "cross-check.R",
    "geom-stepribbon.R",
    "getData-covid19.R",
    "getData-ECDC.R",
    "getData-GoCInfobase.R",
    "getData-Ottawa.R",
    "getData-serial-interval.R",
    "getData-raw.R",
    "getData-wIFR.R",
    "initializePlot.R",
    "patchData.R",
    "plot-3-panel.R",
    "plot-forecast.R",
    "plot-stepsize-vs-chgpt.R",
    "visualizeData-Ottawa.R",
    "wrapper-stan.R"
    );

for ( code.file in code.files ) {
    source(file.path(code.directory,code.file));
    }

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
#data.snapshot <- "2020-06-09.01";
#data.snapshot <- "2020-06-15.01";
#data.snapshot <- "2020-05-10.01";
#data.snapshot <- "2020-06-16.01.DELETEME";
#data.snapshot <- "2020-06-21.01";
data.snapshot  <- "2020-07-16.01";
data.directory <- file.path(data.directory,data.snapshot);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
jurisdictions <- c(
    "Denmark",
    "Italy",
    "Germany",
    "Spain",
    "United_Kingdom",
    "France",
    "Norway",
    "Belgium",
    "Austria",
    "Sweden",
    "Switzerland",
    "BC",
    "AB",
    "ON",
    "QC",
    "Ottawa"
    );

# jurisdictions <- c("Italy","Germany","Spain","United_Kingdom","France","BC","AB","ON","QC","Ottawa");

StanModel <- 'change-point';

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
options(mc.cores = parallel::detectCores());

FILE.stan.model.0 <- file.path(  code.directory,paste0(StanModel,'.stan'));
FILE.stan.model   <- file.path(output.directory,paste0(StanModel,'.stan'));

file.copy(
    from = FILE.stan.model.0,
    to   = FILE.stan.model
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
#set.seed(7654321);
#set.seed(1234567);
set.seed(7777777);

DF.ottawa <- getData.Ottawa(
    csv.input.hospitalization = file.path(data.directory,"raw-covid19-Ottawa-hospitalizations.csv"),
    jsn.input.case.and.death  = file.path(data.directory,"raw-covid19-Ottawa-cases-deaths.json")
    );
print( str(DF.ottawa) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
quit(save="no");
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

list.raw.data <- getData.raw(
    xlsx.ECDC                  = file.path(data.directory,'raw-covid19-ECDC.xlsx'),
    csv.JHU.cases              = file.path(data.directory,'raw-covid19-JHU-cases.csv'),
    csv.JHU.deaths             = file.path(data.directory,'raw-covid19-JHU-deaths.csv'),
    csv.GoCInfobase            = file.path(data.directory,'raw-covid19-GoCInfobase.csv'),
    csv.Ottawa.hospitalization = file.path(data.directory,"raw-covid19-Ottawa-hospitalizations.csv"),
    jsn.Ottawa.case.and.death  = file.path(data.directory,"raw-covid19-Ottawa-cases-deaths.json")
    );
print( names(list.raw.data) );

list.patched.data <- patchData(
    list.covid19.data = list.raw.data
    );
print( names(list.patched.data) );
print( str(list.patched.data[['GoCInfobase']]) );

DF.cross.check.JHU.GoCInfobase <- cross.check.JHU.GoCInfobase(
    list.covid19.data = list.patched.data,
    csv.output        = "diagnostics-compare-JHU-GoCInfobase-patched.csv"
    );
print(str(DF.cross.check.JHU.GoCInfobase));

DF.covid19 <- getData.covid19(
    retained.jurisdictions = jurisdictions,
    list.covid19.data      = list.patched.data
    );
print( str(DF.covid19) );
print( summary(DF.covid19) );

print( unique( DF.covid19[,"jurisdiction"] ) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
DF.fatality.rates <- getData.wIFR(
    csv.wIFR.europe = file.path(data.directory,"weighted-fatality-europe.csv"),
    csv.wIFR.canada = file.path(data.directory,"weighted-fatality-canada.csv")
    );
print( str(DF.fatality.rates) );
print( summary(DF.fatality.rates) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
DF.serial.interval <- getData.serial.interval(
    csv.serial.interval = file.path(data.directory,"serial-interval.csv")
    );

print( str(DF.serial.interval) );
print( summary(DF.serial.interval) );
print( sum(DF.serial.interval[,"fit"]) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
results.wrapper.stan <- wrapper.stan(
    StanModel          = StanModel,
    FILE.stan.model    = FILE.stan.model,
    DF.covid19         = DF.covid19,
    DF.fatality.rates  = DF.fatality.rates,
    DF.serial.interval = DF.serial.interval,
    forecast.window    = 14,
    DEBUG              = FALSE # TRUE
    );

##################################################
print( warnings() );

print( getOption('repos') );

print( .libPaths() );

print( sessionInfo() );

print( format(Sys.time(),"%Y-%m-%d %T %Z") );

stop.proc.time <- proc.time();
print( stop.proc.time - start.proc.time );

