
patchData.Ottawa <- function(
    DF.input     = NULL,
    RData.ottawa = "data-ottawa-patched.RData"
    ) {

    thisFunctionName <- "patchData.Ottawa";
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

        if ( DF.output[1,'new.hospital.admissions'] < DF.output[1,'occupancy.hospital'] ) {
            DF.output[1,'new.hospital.admissions'] <- DF.output[1,'occupancy.hospital'];
            }

        cat("\nstr(DF.output)\n");
        print( str(DF.output)   );

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    write.csv(
        x         = DF.output,
        file      = "data-ottawa-patched.csv",
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
