
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
    "eight-schools.R",
    "getData-covariates.R",
    "getData-ECDC.R",
    "getData-serial-interval.R",
    "getData-WFR.R"
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
data.snapshot  <- "imperial-data-1.0";
data.directory <- file.path(data.directory,data.snapshot);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
countries <- c(
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
    "Switzerland"
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
set.seed(7654321);

options(mc.cores = parallel::detectCores());

file.copy(
    from = file.path(  code.directory,'eight-schools.stan'),
    to   = file.path(output.directory,'eight-schools.stan')
    );

#fitted.model <- eight.schools(
#    FILE.stan = file.path(output.directory,'eight-schools.stan')
#    );
#
#print( str(fitted.model) );

DF.ECDC <- getData.ECDC();
print( str(    DF.ECDC) );
print( summary(DF.ECDC) );

DF.weighted.fatality.ratios <- getData.WFR(
    CSV.WFR = file.path(data.directory,"weighted_fatality.csv"),
    );
print( str(    DF.weighted.fatality.ratios) );
print( summary(DF.weighted.fatality.ratios) );

DF.serial.interval <- getData.serial.interval(
    CSV.serial.interval = file.path(data.directory,"serial_interval.csv"),
    );
print( str(    DF.serial.interval) );
print( summary(DF.serial.interval) );

DF.covariates <- getData.covariates(
    CSV.covariates     = file.path(data.directory,"interventions.csv"),
    retained.countries = countries
    );
print( str(    DF.covariates) );
print( summary(DF.covariates) );
print(         DF.covariates  );

##################################################
print( warnings() );

print( getOption('repos') );

print( .libPaths() );

print( sessionInfo() );

print( format(Sys.time(),"%Y-%m-%d %T %Z") );

stop.proc.time <- proc.time();
print( stop.proc.time - start.proc.time );

