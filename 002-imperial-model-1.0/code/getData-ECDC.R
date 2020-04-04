
getData.ECDC <- function(
    url.ECDC     = "https://opendata.ecdc.europa.eu/covid19/casedistribution/csv",
    RData.output = "COVID-19-up-to-date.RData"
    ) {

    thisFunctionName <- "getData.ECDC";
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

        #url_page <- "https://www.ecdc.europa.eu/en/publications-data/download-todays-data-geographic-distribution-covid-19-cases-worldwide"

        tryCatch(
            expr = {
                code <- download.file(url = url.ECDC, destfile = "COVID-19-up-to-date.csv");
                if (code != 0) { stop("Error downloading file") }
                },
            error = function(e) {
                stop(sprintf("Error downloading file '%s': %s, please check %s", url, e$message, url_page));
                }
            );

        d   <- read.csv("COVID-19-up-to-date.csv", stringsAsFactors = FALSE);
        d$t <- lubridate::decimal_date(as.Date(d$dateRep, format = "%d/%m/%Y"));
        d   <- d[order(d$'countriesAndTerritories', d$t, decreasing = FALSE), ];

        names(d)[names(d) == "countriesAndTerritories"] <- "Countries.and.territories";
        names(d)[names(d) == "deaths"]                  <- "Deaths";
        names(d)[names(d) == "cases"]                   <- "Cases";
        names(d)[names(d) == "dateRep"]                 <- "DateRep";

        DF.output <- d;
        remove( list = c("d") );

        DF.output[,"DateRep"] <- as.Date(
            x      = DF.output[,"DateRep"],
            format = "%d/%m/%Y"
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

