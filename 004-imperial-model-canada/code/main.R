
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
    "geom-stepribbon.R",
    "getData-covariates.R",
    "getData-covid19.R",
    "getData-ECDC.R",
    "getData-GoCInfobase.R",
    "getData-JHU.R",
    "getData-serial-interval.R",
    "getData-WFR.R",
    "plot-3-panel.R",
    "plot-forecast.R",
    "wrapper-stan.R"
    );

for ( code.file in code.files ) {
    source(file.path(code.directory,code.file));
    }

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
require(rstan);
require(data.table);
require(lubridate);
require(gdata);
require(EnvStats);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
#data.snapshot <- "imperial-data-1.0";
#data.snapshot  <- "2020-04-05.01";
data.snapshot  <- "2020-04-07.01";
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
    "CA",
    "BC",
    "AB",
    "SK",
    "MB",
    "ON",
    "QC",
    "NB",
    "NL",
    "NS",
    "PE",
    "YK",
    "NT",
    "NV"
    );

StanModel <- 'base';

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
options(mc.cores = parallel::detectCores());

FILE.stan.model.0 <- file.path(  code.directory,paste0(StanModel,'.stan'));
FILE.stan.model   <- file.path(output.directory,paste0(StanModel,'.stan'));

file.copy(
    from = FILE.stan.model.0,
    to   = FILE.stan.model
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
set.seed(7654321);

DF.GoCInfobase <- getData.GoCInfobase();

print( str(DF.GoCInfobase) );

print( summary(DF.GoCInfobase) );

DF.covid19 <- getData.covid19(
    retained.jurisdictions = jurisdictions,
    ECDC.file              = file.path(data.directory,"input-covid19-ECDC.csv"),
    JHU.file.cases         = file.path(data.directory,"input-covid19-JHU-cases.csv" ),
    JHU.file.deaths        = file.path(data.directory,"input-covid19-JHU-deaths.csv" )
    );

print( str(DF.covid19) );

print( summary(DF.covid19) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
#DF.weighted.fatality.ratios <- getData.WFR(
#    CSV.WFR.europe = file.path(data.directory,"weighted-fatality-europe.csv"),
#    CSV.WFR.canada = file.path(data.directory,"weighted-fatality-canada.csv")
#    );

#print( str(DF.weighted.fatality.ratios) );

#print( summary(DF.weighted.fatality.ratios) );

#DF.covariates <- getData.covariates(
#    CSV.covariates.europe = file.path(data.directory,"interventions-europe.csv"),
#    CSV.covariates.canada = file.path(data.directory,"interventions-canada.csv"),
#    retained.countries    = countries
#    );

#print( str(DF.covariates) );

#print( summary(DF.covariates) );

#cat("\nDF.covariates\n");
#print( DF.covariates   );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
#DF.serial.interval <- getData.serial.interval(
#    CSV.serial.interval = file.path(data.directory,"serial-interval.csv")
#    );

#print( str(DF.serial.interval) );

#print( summary(DF.serial.interval) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
#results.wrapper.stan <- wrapper.stan(
#    StanModel                   = StanModel,
#    FILE.stan.model             = FILE.stan.model,
#    DF.ECDC                     = DF.ECDC,
#    DF.weighted.fatality.ratios = DF.weighted.fatality.ratios,
#    DF.serial.interval          = DF.serial.interval,
#    DF.covariates               = DF.covariates,
#    forecast.window             = 30,
#    DEBUG                       = TRUE # FALSE # TRUE
#    );

##################################################
print( warnings() );

print( getOption('repos') );

print( .libPaths() );

print( sessionInfo() );

print( format(Sys.time(),"%Y-%m-%d %T %Z") );

stop.proc.time <- proc.time();
print( stop.proc.time - start.proc.time );

