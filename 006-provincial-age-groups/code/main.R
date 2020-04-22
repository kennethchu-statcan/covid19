
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
    "getData-provincial.R",
    "getData-raw.R"
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
data.snapshot  <- "2020-04-22.01";
data.directory <- file.path(data.directory,data.snapshot);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
set.seed(7654321);

DF.raw.Census2016.age.sex <- getData.raw(
    csv.Census2016.age.sex = file.path(data.directory,'98-400-X2016001_English_CSV_data.csv')
    );

print( str(DF.raw.Census2016.age.sex) );

list.Census2016.age.sex <- getData.provincial(
    DF.input = DF.raw.Census2016.age.sex
    );

print( str(list.Census2016.age.sex) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
write.csv(
    x         = list.Census2016.age.sex[['bin.size.1']],
    file      = "canada-census2016-age-groups-binsize-1.csv",
    row.names = FALSE
    );

write.csv(
    x         = list.Census2016.age.sex[['bin.size.5']],
    file      = "canada-census2016-age-groups-binsize-5.csv",
    row.names = FALSE
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

##################################################
print( warnings() );

print( getOption('repos') );

print( .libPaths() );

print( sessionInfo() );

print( format(Sys.time(),"%Y-%m-%d %T %Z") );

stop.proc.time <- proc.time();
print( stop.proc.time - start.proc.time );

