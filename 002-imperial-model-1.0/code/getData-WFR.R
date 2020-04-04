
getData.WFR <- function(
    CSV.WFR      = NULL,
    RData.output = "input-weighted-fatality-ratios.RData"
    ) {

    thisFunctionName <- "getData.WFR";
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

        ## get CFR
        cfr.by.country <- read.csv( CSV.WFR );
        cfr.by.country$country <- as.character(cfr.by.country[,2])
        cfr.by.country$country[cfr.by.country$country == "United Kingdom"] <- "United_Kingdom"

        DF.output <- cfr.by.country;
        remove( list = c("cfr.by.country") );

        colnames(DF.output) <- gsub(
            x           = colnames(DF.output),
            pattern     = "^X$",
            replacement = "ID"
            );

        colnames(DF.output) <- gsub(
            x           = colnames(DF.output),
            pattern     = "Region.+",
            replacement = "jurisdiction"
            );

        colnames(DF.output) <- gsub(
            x           = colnames(DF.output),
            pattern     = "^X",
            replacement = "age_"
            );

        colnames(DF.output) <- gsub(
            x           = colnames(DF.output),
            pattern     = "\\.",
            replacement = "_to_"
            );

        colnames(DF.output) <- gsub(
            x           = colnames(DF.output),
            pattern     = "Oct_to_19",
            replacement = "age_10_to_19"
            );

        colnames(DF.output) <- gsub(
            x           = colnames(DF.output),
            pattern     = "age_80_to_",
            replacement = "age_80_or_above"
            );

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

