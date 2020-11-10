
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
    "getData-Ottawa-cases-deaths.R",
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
set.seed(1234567);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
data.snapshot <- "2020-06-21.01";

DF.fatality.rates <- getData.wIFR(
    csv.wIFR.europe = file.path(data.directory,data.snapshot,"weighted-fatality-europe.csv"),
    csv.wIFR.canada = file.path(data.directory,data.snapshot,"weighted-fatality-canada.csv")
    );
print( str(DF.fatality.rates) );
print( summary(DF.fatality.rates) );

DF.serial.interval <- getData.serial.interval(
    csv.serial.interval = file.path(data.directory,data.snapshot,"serial-interval.csv")
    );
print( str(DF.serial.interval) );
print( summary(DF.serial.interval) );
print( sum(DF.serial.interval[,"fit"]) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
data.snapshot <- "2020-11-04.01";

DF.ottawa <- getData.Ottawa(
    csv.input = file.path(data.directory,data.snapshot,"raw-covid19-Ottawa.csv")
    );
DF.ottawa.plot <- DF.ottawa;

print( str(DF.ottawa) );
print( summary(DF.ottawa) );

colnames(DF.ottawa) <-gsub(
    x           = colnames(DF.ottawa),
    pattern     = "new.cases",
    replacement = "case"
    );

colnames(DF.ottawa) <-gsub(
    x           = colnames(DF.ottawa),
    pattern     = "new.hospital.admissions",
    replacement = "death"
    );

DF.ottawa[,'jurisdiction'] <- rep('Ottawa',nrow(DF.ottawa));
DF.ottawa <- DF.ottawa[,c("jurisdiction","date","case","death")];

print( str(DF.ottawa) );
print( summary(DF.ottawa) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
DF.ontario <- DF.ottawa;
DF.ontario[,'jurisdiction'] <- rep('ON',nrow(DF.ontario));
DF.dummy <- rbind(DF.ottawa,DF.ontario);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
results.wrapper.stan <- wrapper.stan(
    StanModel          = StanModel,
    FILE.stan.model    = FILE.stan.model,
    DF.covid19         = DF.dummy, # DF.ottawa, # DF.covid19,
    DF.fatality.rates  = DF.fatality.rates,
    DF.serial.interval = DF.serial.interval,
    forecast.window    = 14,
    DEBUG              = TRUE # FALSE
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
dashboard.files <- c(
    "dashboard-hospitalization"
    );

for ( dashboard.file in dashboard.files ) {
    rmarkdown::render(
        input         = file.path(code.directory,paste0(dashboard.file,".Rmd")),
        output_format = flexdashboard::flex_dashboard(theme = "cerulean"), # darkly
        output_file   = file.path(output.directory,paste0(dashboard.file,".html"))
        );
    }

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

##################################################
print( warnings() );

print( getOption('repos') );

print( .libPaths() );

print( sessionInfo() );

print( format(Sys.time(),"%Y-%m-%d %T %Z") );

stop.proc.time <- proc.time();
print( stop.proc.time - start.proc.time );
