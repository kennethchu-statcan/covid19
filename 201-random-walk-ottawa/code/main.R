
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
    "getData-Ottawa.R",
    "initializePlot.R",
    "visualizeData-Ottawa.R",
    "wrapper-stan.R"
    );

for ( code.file in code.files ) {
    source(file.path(code.directory,code.file));
    }

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
data.snapshot  <- "2020-06-09.01";
data.directory <- file.path(data.directory,data.snapshot);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
options(mc.cores = parallel::detectCores());

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
set.seed(7654321);

DF.ottawa <- getData.Ottawa(
    xlsx.input.hospitalization = file.path(data.directory,"Covid19_CODOttawaResidentHospitalAdmissionsByDay_EN.xlsx"),
    xlsx.input.case.and.death  = file.path(data.directory,"COVID-19_Ottawa_case_death_daily_count_data_EN.xlsx")
    );

print( str(DF.ottawa) );

visualizeData.Ottawa(
    DF.input = DF.ottawa
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
#results.wrapper.stan <- wrapper.stan(
#    FILE.stan.model             = FILE.stan.model,
#    DF.covid19                  = DF.covid19,
#    DF.weighted.fatality.ratios = DF.weighted.fatality.ratios,
#    DF.serial.interval          = DF.serial.interval,
#    DF.covariates               = DF.covariates,
#    forecast.window             = 14,
#    DEBUG                       = FALSE # TRUE
#    );

##################################################
print( warnings() );

print( getOption('repos') );

print( .libPaths() );

print( sessionInfo() );

print( format(Sys.time(),"%Y-%m-%d %T %Z") );

stop.proc.time <- proc.time();
print( stop.proc.time - start.proc.time );

