
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
    "getData-raw.R",
    "patchData.R"
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
#data.snapshot  <- "2020-04-07.01";
#data.snapshot  <- "2020-04-11.01";
data.snapshot  <- "2020-04-11.02";
data.directory <- file.path(data.directory,data.snapshot);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
set.seed(7654321);

list.raw.data <- getData.raw(
    csv.ECDC        = file.path(data.directory,'raw-covid19-ECDC.csv'),
    csv.JHU.cases   = file.path(data.directory,'raw-covid19-JHU-cases.csv'),
    csv.JHU.deaths  = file.path(data.directory,'raw-covid19-JHU-deaths.csv'),
    csv.GoCInfobase = file.path(data.directory,'raw-covid19-GoCInfobase.csv')
    );

print( names(list.raw.data) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
DF.cross.check.JHU.GoCInfobase <- cross.check.JHU.GoCInfobase(
    list.covid19.data = list.raw.data,
    csv.output        = "diagnostics-compare-JHU-GoCInfobase-raw.csv"
    );
print(str(DF.cross.check.JHU.GoCInfobase));

DF.cross.check.JHU.ECDC <- cross.check.JHU.ECDC(
    list.covid19.data = list.raw.data,
    csv.output        = "diagnostics-compare-JHU-ECDC-raw.csv"
    );
print(str(DF.cross.check.JHU.ECDC));

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
list.patched.data <- patchData(
    list.covid19.data = list.raw.data
    );

print( names(list.patched.data) );

print( str(list.patched.data[['GoCInfobase']]) );

# print( list.patched.data[['GoCInfobase']] );

DF.cross.check.JHU.GoCInfobase <- cross.check.JHU.GoCInfobase(
    list.covid19.data = list.patched.data,
    csv.output        = "diagnostics-compare-JHU-GoCInfobase-patched.csv"
    );
print(str(DF.cross.check.JHU.GoCInfobase));

##################################################
print( warnings() );

print( getOption('repos') );

print( .libPaths() );

print( sessionInfo() );

print( format(Sys.time(),"%Y-%m-%d %T %Z") );

stop.proc.time <- proc.time();
print( stop.proc.time - start.proc.time );

