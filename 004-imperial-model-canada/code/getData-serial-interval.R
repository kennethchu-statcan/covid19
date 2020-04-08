
getData.serial.interval <- function(
    CSV.serial.interval = NULL,
    RData.output        = "input-serial-interval.RData"
    ) {

    thisFunctionName <- "getData.serial.interval";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(lubridate);
    require(readr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(RData.output) ) {

        cat(paste0("\n### ",RData.output," already exists; loading this file ...\n"));

        DF.output <- readRDS(file = RData.output);

        cat(paste0("\n### Finished loading raw data.\n"));

    } else {

        DF.output <- read.csv( CSV.serial.interval );

        if (!is.null(RData.output)) {
            saveRDS(object = DF.output, file = RData.output);
            }

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( DF.output );

    }

##################################################

