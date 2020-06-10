
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
    "getData-serial-interval.R",
    "getData-wIFR.R",
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
StanModel <- 'random-walk';

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

DF.ottawa <- getData.Ottawa(
    xlsx.input.hospitalization = file.path(data.directory,"Covid19_CODOttawaResidentHospitalAdmissionsByDay_EN.xlsx"),
    xlsx.input.case.and.death  = file.path(data.directory,"COVID-19_Ottawa_case_death_daily_count_data_EN.xlsx")
    );

print( str(DF.ottawa) );

visualizeData.Ottawa(
    DF.input = DF.ottawa
    );

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
DF.ontario <- DF.ottawa;
DF.ontario[,"jurisdiction"] <- "Ontario";

DF.covid19 <- rbind(DF.ottawa,DF.ontario);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
results.wrapper.stan <- wrapper.stan(
    StanModel          = StanModel,
    FILE.stan.model    = FILE.stan.model,
    DF.covid19         = DF.covid19,
    DF.fatality.rates  = DF.fatality.rates,
    DF.serial.interval = DF.serial.interval,
    forecast.window    = 14,
    DEBUG              = TRUE
    );

##################################################
print( warnings() );

print( getOption('repos') );

print( .libPaths() );

print( sessionInfo() );

print( format(Sys.time(),"%Y-%m-%d %T %Z") );

stop.proc.time <- proc.time();
print( stop.proc.time - start.proc.time );

