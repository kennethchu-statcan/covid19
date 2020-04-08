
getData.WFR <- function(
    CSV.WFR.europe = NULL,
    CSV.WFR.canada = NULL,
    RData.output   = "input-weighted-fatality-ratios.RData"
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

        DF.WFR.europe <- getData.WFR_europe(
            CSV.input = CSV.WFR.europe
            );

        DF.WFR.canada <- getData.WFR_canada(
            CSV.input     = CSV.WFR.canada,
            DF.WFR.europe = DF.WFR.europe
            );

        cat("\nstr(DF.WFR.europe)\n");
        print( str(DF.WFR.europe)   );

        cat("\nstr(DF.WFR.canada)\n");
        print( str(DF.WFR.canada)   );

        DF.output <- rbind(
            DF.WFR.europe,
            DF.WFR.canada
            );

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if (!is.null(RData.output)) {
        saveRDS(object = DF.output, file = RData.output);
        write.csv(
            x         = DF.output,
            file      = gsub(x = RData.output,pattern="\\.RData",replacement=".csv"),
            row.names = FALSE
            );
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( DF.output );

    }

##################################################
getData.WFR_canada <- function(
    CSV.input     = NULL,
    DF.WFR.europe = NULL
    ) {

    DF.output <- read.csv( CSV.input );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "^Region.+",
        replacement = "country"
        );

    DF.output[,"country"   ] <- as.character(DF.output[,"country"   ]);
    DF.output[,"population"] <- as.integer(  DF.output[,"population"]);

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

    DF.output[,"weighted_fatality"] <- sample(
        x       = DF.WFR.europe[,"weighted_fatality"],
        size    = nrow(DF.output),
        replace = TRUE
        );

    return( DF.output );

    }

getData.WFR_europe <- function(
    CSV.input = NULL
    ) {

    DF.output <- read.csv( CSV.input );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "^Region.+",
        replacement = "country"
        );

    DF.output[,"country"] <- as.character(DF.output[,"country"]);

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

    return( DF.output );

    }

