
getData.ECDC <- function(
    list.covid19.data = NULL,
    csv.ECDC          = "raw-covid19-ECDC.csv"
    ) {

    thisFunctionName <- "getData.ECDC";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(lubridate);
    require(readr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    d <- list.covid19.data[["ECDC"]];
    d$t <- lubridate::decimal_date(as.Date(d$dateRep, format = "%d/%m/%Y"));
    d   <- d[order(d$'countriesAndTerritories', d$t, decreasing = FALSE), ];

    names(d)[names(d) == "countriesAndTerritories"] <- "jurisdiction";
    names(d)[names(d) == "dateRep"]                 <- "date";

    DF.output <- d;
    remove( list = c("d") );

    DF.output[,"date"] <- as.Date(
        x      = DF.output[,"date"],
        format = "%d/%m/%Y"
        );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "cases",
        replacement = "case"
        );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "deaths",
        replacement = "death"
        );

    DF.output <- DF.output[,c("jurisdiction","date","year","month","day","case","death")];

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    write.csv(
        x         = DF.output,
        file      = csv.ECDC,
        row.names = FALSE
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( DF.output );

    }

##################################################

