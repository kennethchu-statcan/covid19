
addDerivedData.Ottawa <- function(
    DF.input     = NULL,
    RData.ottawa = "data-ottawa-derived.RData"
    ) {

    thisFunctionName <- "addDerivedData.Ottawa";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    require(dplyr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(RData.ottawa) ) {

        cat(paste0("\n# ",RData.ottawa," already exists; loading this file ...\n"));
        DF.output <- readRDS(file = RData.ottawa);
        cat(paste0("\n# Loading complete: ",RData.ottawa,"\n"));

    } else {

        DF.output <- DF.input;
        DF.output[,'cumulative.hospital.admissions'] <- cumsum(DF.output[,'new.hospital.admissions']);
        DF.output[,'cumulative.discharges'] <- DF.output[,'cumulative.hospital.admissions'] - DF.output[,'occupancy.hospital'];
        DF.output[,'daily.discharges'] <- c(0,base::diff(DF.output[,'cumulative.discharges'], lag = 1));

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    write.csv(
        x         = DF.output,
        file      = "data-ottawa-derived.csv",
        row.names = FALSE
        );

    base::saveRDS(
        file   = RData.ottawa,
        object = DF.output
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( DF.output );

    }

##################################################
