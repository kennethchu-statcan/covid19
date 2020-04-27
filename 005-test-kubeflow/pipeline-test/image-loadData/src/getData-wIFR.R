
getData.wIFR <- function(
    csv.wIFR.europe = NULL,
    csv.wIFR.canada = NULL,
    seed.wIFR       = 7654321,
    csv.output      = "input-wIFR.csv"
    ) {

    thisFunctionName <- "getData.wIFR";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(lubridate);
    require(readr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.wIFR.europe <- getData.wIFR_europe(
        csv.input = csv.wIFR.europe
        );

    DF.wIFR.canada <- getData.wIFR_canada(
        csv.input      = csv.wIFR.canada,
        DF.wIFR.europe = DF.wIFR.europe,
        seed.wIFR      = seed.wIFR
        );

    cat("\nstr(DF.wIFR.europe)\n");
    print( str(DF.wIFR.europe)   );

    cat("\nstr(DF.wIFR.canada)\n");
    print( str(DF.wIFR.canada)   );

    DF.output <- rbind(
        DF.wIFR.europe,
        DF.wIFR.canada
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    write.csv(
        x         = DF.output,
        file      = csv.output,
        row.names = FALSE
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( DF.output );

    }

##################################################
getData.wIFR_canada <- function(
    csv.input      = NULL,
    DF.wIFR.europe = NULL,
    seed.wIFR      = NULL
    ) {

    DF.output <- read.csv( csv.input );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "^Region.+",
        replacement = "jurisdiction"
        );

    DF.output[,"jurisdiction"] <- as.character(DF.output[,"jurisdiction"]);
    DF.output[,"population"  ] <- as.integer(  DF.output[,"population"  ]);

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "^X$",
        replacement = "ID"
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

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    set.seed( seed.wIFR );

    #DF.output[,"weighted_fatality"] <- sample(
    #    x       = DF.wIFR.europe[,"weighted_fatality"],
    #    size    = nrow(DF.output),
    #    replace = TRUE
    #    );

    DF.output[,"weighted_fatality"] <- runif(
        n   = nrow(DF.output),
        min = 0.8 * min(DF.wIFR.europe[,"weighted_fatality"]),
        max = 1.2 * max(DF.wIFR.europe[,"weighted_fatality"])
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    return( DF.output );

    }

getData.wIFR_europe <- function(
    csv.input = NULL
    ) {

    DF.output <- read.csv( csv.input );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "^Region.+",
        replacement = "jurisdiction"
        );

    DF.output[,"jurisdiction"] <- as.character(DF.output[,"jurisdiction"]);

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "^X$",
        replacement = "ID"
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

