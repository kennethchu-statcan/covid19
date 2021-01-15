
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
    "getData-IHR.R",
    "getData-Ottawa.R",
    "getData-Ottawa-cases-deaths.R",
    "getData-serial-interval.R",
    "getData-raw.R",
    "getForecast-occupancy.R",
    "get-moving-stddev.R",
    "initializePlot.R",
    "patchData-Ottawa.R",
    "patchData.R",
    "plot-3-panel.R",
    "plot-forecast.R",
    "plot-stepsize-vs-chgpt.R",
    "visualizeData-Ottawa.R",
    "visualizeForecast-occupancy.R",
    "visualizeModel-change-point.R",
    "visualizeModel-length-of-stay.R",
    "wrapper-stan-length-of-stay.R",
    "wrapper-stan-change-point.R"
    );

for ( code.file in code.files ) {
    source(file.path(code.directory,code.file));
    }

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# set.seed(1234567);
# set.seed(7777777);
# set.seed(8888888);
set.seed(7654321);

data.snapshot <- "2021-01-06.01";

options(mc.cores = parallel::detectCores());

n.iterations.chgpt <- 1000;
n.warmup.chgpt     <-  500;
n.iterations.LoS   <- 1000;
n.warmup.LoS       <-  500;
period.thinning    <-    4;
sampler.control    <- list(adapt_delta = 0.90, max_treedepth = 10);

is.macOS <- grepl(x = sessionInfo()[['platform']], pattern = 'apple', ignore.case = TRUE);
n.chains <- ifelse(test = is.macOS, yes = 4, no = getOption("mc.cores"));

DEBUG <- TRUE;
if ( DEBUG ) {
    n.iterations.chgpt <- ifelse(test = is.macOS, yes = 40, no = 200);
    n.warmup.chgpt     <- ifelse(test = is.macOS, yes = 20, no = 100);
    n.iterations.LoS   <- ifelse(test = is.macOS, yes = 40, no = 200);
    n.warmup.LoS       <- ifelse(test = is.macOS, yes = 20, no = 100);
    period.thinning    <- 1;
    sampler.control    <- NULL;
    }

buffer.period         <- 14;
forecast.window       <- 21;
threshold.stuck.chain <-  0.05;

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
DF.IHR <- getData.IHR(
    csv.IHR = file.path(data.directory,data.snapshot,"infection-hospitalization-rate.csv")
    );
print( str(DF.IHR) );
print( summary(DF.IHR) );

DF.serial.interval <- getData.serial.interval(
    csv.serial.interval = file.path(data.directory,data.snapshot,"serial-interval.csv")
    );
print( str(DF.serial.interval) );
print( summary(DF.serial.interval) );
print( sum(DF.serial.interval[,"fit"]) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
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
    pattern     = "new.cases",
    replacement = "cases"
    );

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
DF.ottawa <- DF.ottawa[,c("jurisdiction","date","cases","admissions","discharges","cumulative.admissions","occupancy")];

print( str(DF.ottawa) );
print( summary(DF.ottawa) );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
DF.ottawa.01 <- DF.ottawa;
DF.ottawa.01[,'jurisdiction'] <- rep('Ottawa1',nrow(DF.ottawa.01));
DF.complete <- rbind( DF.ottawa , DF.ottawa.01 );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
cut.off.dates <- c(
    "2020-11-23",
    "2020-11-30",
    "2020-12-07",
    "2020-12-14",
    "2020-12-21",
    "2020-12-28",
    "2021-01-04",
    "2021-01-11"
    );
cut.off.dates <- sort(x = cut.off.dates, decreasing = TRUE);

for ( cut.off.date in cut.off.dates ) {

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    temp.directory <- normalizePath(file.path(output.directory,paste0("cutoff-",cut.off.date)));
    if ( !dir.exists(temp.directory) ) { dir.create(path = temp.directory, recursive = TRUE); }
    setwd(temp.directory);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.cut.off <- DF.complete[DF.complete[,'date'] <= as.Date(cut.off.date),];

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    results.stan.change.point <- wrapper.stan.change.point(
        StanModel          = 'change-point',
        FILE.stan.model    = file.path(code.directory,'change-point.stan'),
        DF.input           = DF.cut.off,
        DF.IHR             = DF.IHR,
        DF.serial.interval = DF.serial.interval,
        buffer.period      = buffer.period,
        forecast.window    = forecast.window,
        n.chains           = n.chains,
        n.iterations       = n.iterations.chgpt,
        n.warmup           = n.warmup.chgpt,
        period.thinning    = period.thinning,
        sampler.control    = sampler.control
        );

    visualizeModel.change.point(
        list.input      = results.stan.change.point,
        forecast.window = forecast.window
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    results.stan.LoS <- wrapper.stan.length.of.stay(
        StanModel       = 'length-of-stay',
        FILE.stan.model = file.path(code.directory,'length-of-stay.stan'),
        DF.input        = DF.cut.off,
        n.chains        = n.chains,
        n.iterations    = n.iterations.LoS,
        n.warmup        = n.warmup.LoS,
        period.thinning = period.thinning,
        sampler.control = sampler.control
        );

    visualizeModel.length.of.stay(
        list.input = results.stan.LoS
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.forecast.occupancy <- getForecast.occupancy(
        results.stan.change.point = results.stan.change.point,
        results.stan.LoS          = results.stan.LoS
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    visualizeForecast.occupancy(
        DF.complete               = DF.complete,
        results.stan.change.point = results.stan.change.point,
        results.stan.LoS          = results.stan.LoS,
        list.forecast.occupancy   = list.forecast.occupancy,
        forecast.window           = forecast.window
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    dashboard.files <- c(
        "dashboard-change-point",
        "dashboard-length-of-stay",
        "dashboard-occupancy-forecast"
        );

    for ( dashboard.file in dashboard.files ) {
        rmarkdown::render(
            input         = file.path(code.directory,paste0(dashboard.file,".Rmd")),
            output_format = flexdashboard::flex_dashboard(theme = "cerulean"), # darkly
            output_file   = file.path(temp.directory,paste0(dashboard.file,".html"))
            );
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    setwd( output.directory );

    }

##################################################
print( warnings() );

print( getOption('repos') );

print( .libPaths() );

print( sessionInfo() );

print( format(Sys.time(),"%Y-%m-%d %T %Z") );

stop.proc.time <- proc.time();
print( stop.proc.time - start.proc.time );
