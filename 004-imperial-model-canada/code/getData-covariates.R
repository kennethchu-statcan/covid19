
getData.covariates <- function(
    CSV.covariates     = NULL,
    RData.output       = "input-covariates.RData",
    nrows.to.read      = 11,
    retained.countries = NULL,
    retained.columns   = c(
        "Country",
        "schools_universities",
        "travel_restrictions",
        "public_events",
        "sport",
        "lockdown",
        "social_distancing_encouraged",
        "self_isolating_if_ill"
        )
    ) {

    thisFunctionName <- "getData.covariates";
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

        covariates <- read.csv(
            file  = CSV.covariates,
            nrows = nrows.to.read,
            stringsAsFactors = FALSE
            );

        covariates <- covariates[,retained.columns];

        date.colnames <- setdiff(colnames(covariates),"Country");
        for ( temp.colname in date.colnames ) {
            covariates[,temp.colname] <- as.Date(
                x      = covariates[,temp.colname],
                format = "%Y-%m-%d"
                );
            }

        # making all covariates that happen after lockdown to have same date as lockdown
        date.colnames <- setdiff(colnames(covariates),c("Country","lockdown"));
        for ( temp.colname in date.colnames ) {
            is.after.lockdown <- (covariates[,temp.colname] > covariates[,"lockdown"]);
            covariates[is.after.lockdown,temp.colname] <- covariates[is.after.lockdown,"lockdown"];
            }

#        covariates$schools_universities[covariates$schools_universities > covariates$lockdown] <- covariates$lockdown[covariates$schools_universities > covariates$lockdown]
#        covariates$travel_restrictions[covariates$travel_restrictions > covariates$lockdown] <- covariates$lockdown[covariates$travel_restrictions > covariates$lockdown]
#        covariates$public_events[covariates$public_events > covariates$lockdown] <- covariates$lockdown[covariates$public_events > covariates$lockdown]
#        covariates$sport[covariates$sport > covariates$lockdown] <- covariates$lockdown[covariates$sport > covariates$lockdown]
#        covariates$social_distancing_encouraged[covariates$social_distancing_encouraged > covariates$lockdown] <- covariates$lockdown[covariates$social_distancing_encouraged > covariates$lockdown]
#        covariates$self_isolating_if_ill[covariates$self_isolating_if_ill > covariates$lockdown] <- covariates$lockdown[covariates$self_isolating_if_ill > covariates$lockdown]

        DF.output <- covariates;
        remove( list = c("covariates") );

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

