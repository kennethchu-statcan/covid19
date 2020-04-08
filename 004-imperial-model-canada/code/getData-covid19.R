
getData.covid19 <- function(
    ECDC.file       = NULL, 
    ECDC.url        = "https://opendata.ecdc.europa.eu/covid19/casedistribution/csv",
    ECDC.RData      = "input-covid19-ECDC.RData",
    JHU.file.cases  = NULL,
    JHU.file.deaths = NULL,
    JHU.url.cases   = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv",
    JHU.url.deaths  = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv",
    JHU.RData       = "input-covid19-JHU.RData"
    ) {

    thisFunctionName <- "getData.covid19";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(lubridate);
    require(readr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.ECDC <- getData.ECDC(
        ECDC.file    = ECDC.file,
        ECDC.url     = ECDC.url,
        ECDC.RData   = ECDC.RData
        );
    print( str(    DF.ECDC) );
    print( summary(DF.ECDC) );

    DF.JHU <- getData.JHU(
        JHU.file.cases  = JHU.file.cases,
        JHU.file.deaths = JHU.file.deaths,
        JHU.url.cases   = JHU.url.cases,
        JHU.url.deaths  = JHU.url.deaths,
        JHU.RData       = JHU.RData
        );
    print( str(    DF.JHU) );
    print( summary(DF.JHU) );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    retained.columns <- setdiff(colnames(DF.ECDC),c("geoId","countryterritoryCode","popData2018","t"));
    DF.ECDC <- DF.ECDC[,retained.columns];

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    colnames(DF.JHU) <- gsub(
        x           = colnames(DF.JHU),
        pattern     = "province",
        replacement = "Countries.and.territories"
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- rbind(
        DF.ECDC,
        DF.JHU
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    #return( DF.output );
    return( DF.output );

    }

##################################################

