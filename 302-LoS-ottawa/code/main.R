
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
    "addDerivedData-Ottawa.R",
    "cross-check.R",
    "examine-Weibull.R",
    "examine-Gamma.R",
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
    "patchData-Ottawa.R",
    "patchData.R",
    "plot-3-panel.R",
    "plot-forecast.R",
    "plot-stepsize-vs-chgpt.R",
    "visualizeData-Ottawa.R",
    "wrapper-stan-length-of-stay.R",
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

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
options(mc.cores = parallel::detectCores());

n.chains <- ifelse(
    test = grepl(x = sessionInfo()[['platform']], pattern = 'apple', ignore.case = TRUE),
    yes  = 4,
    no   = getOption("mc.cores")
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
data.snapshot <- "2020-12-06.01";

DF.ottawa <- getData.Ottawa(
    csv.input = file.path(data.directory,data.snapshot,"raw-covid19-Ottawa.csv")
    );

DF.ottawa <- patchData.Ottawa(     DF.input = DF.ottawa);
DF.ottawa <- addDerivedData.Ottawa(DF.input = DF.ottawa);

print( str(DF.ottawa) );
print( summary(DF.ottawa) );

DF.ottawa.plot <- DF.ottawa;

print( str(DF.ottawa) );
print( summary(DF.ottawa) );

colnames(DF.ottawa) <-gsub(
    x           = colnames(DF.ottawa),
    pattern     = "new.hospital.admissions",
    replacement = "admissions"
    );

colnames(DF.ottawa) <-gsub(
    x           = colnames(DF.ottawa),
    pattern     = "daily.discharges",
    replacement = "discharges"
    );

colnames(DF.ottawa) <-gsub(
    x           = colnames(DF.ottawa),
    pattern     = "cumulative.hospital.admissions",
    replacement = "cumulative.admissions"
    );

colnames(DF.ottawa) <-gsub(
    x           = colnames(DF.ottawa),
    pattern     = "occupancy.hospital",
    replacement = "occupancy"
    );

DF.ottawa[,'jurisdiction'] <- rep('Ottawa',nrow(DF.ottawa));
DF.ottawa <- DF.ottawa[,c("jurisdiction","date","admissions","discharges","cumulative.admissions","occupancy")];

print( str(DF.ottawa) );
print( summary(DF.ottawa) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
DF.ontario <- DF.ottawa;
DF.ontario[,'jurisdiction'] <- rep('ON',nrow(DF.ontario));
DF.dummy <- rbind(DF.ottawa,DF.ontario);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# results.stan.changepoint <- wrapper.stan(
#     StanModel          = 'change-point',
#     FILE.stan.model    = FILE.stan.model,
#     DF.covid19         = DF.dummy, # DF.ottawa, # DF.covid19,
#     DF.fatality.rates  = DF.fatality.rates,
#     DF.serial.interval = DF.serial.interval,
#     forecast.window    = 14,
#     DEBUG              = FALSE # TRUE
#     );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
results.stan.LoS <- wrapper.stan.length.of.stay(
    StanModel       = 'length-of-stay',
    FILE.stan.model = file.path(code.directory,'length-of-stay.stan'),
    DF.input        = DF.dummy,
    n.chains        = n.chains,
    DEBUG           = TRUE # FALSE
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
dashboard.file <- "dashboard-length-of-stay";
rmarkdown::render(
    input         = file.path(code.directory,paste0(dashboard.file,".Rmd")),
    output_format = flexdashboard::flex_dashboard(theme = "cerulean"), # darkly
    output_file   = file.path(output.directory,paste0(dashboard.file,".html"))
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
