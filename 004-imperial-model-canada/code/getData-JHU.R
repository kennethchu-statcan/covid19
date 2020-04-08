
getData.JHU <- function(
    JHU.file.cases  = NULL, 
    JHU.file.deaths = NULL, 
    JHU.url.cases   = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv",
    JHU.url.deaths  = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv",
    JHU.RData       = "input-covid19-JHU.RData"
    ) {

    thisFunctionName <- "getData.JHU";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(dplyr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(JHU.RData) ) {

        cat(paste0("\n### ",JHU.RData," already exists; loading this file ...\n"));

        DF.output <- readRDS(file = JHU.RData);

        cat(paste0("\n### Finished loading raw data.\n"));

    } else {

        DF.JHU.cases <- getData.JHU_download(
            input.file  = JHU.file.cases,
            target.url  = JHU.url.cases,
            output.file = "input-covid19-JHU-cases.csv"
            )

        DF.JHU.deaths <- getData.JHU_download(
            input.file  = JHU.file.deaths,
            target.url  = JHU.url.deaths,
            output.file = "input-covid19-JHU-deaths.csv"
            )

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.JHU.cases <- getData.JHU_reformat(
        DF.input      = DF.JHU.cases,
        colname.value = "Cases"
        );

    DF.JHU.deaths <- getData.JHU_reformat(
        DF.input      = DF.JHU.deaths,
        colname.value = "Deaths"
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- dplyr::full_join(
        x  = DF.JHU.cases,
        y  = DF.JHU.deaths,
        by = c("province","date")
        );

    DF.output <- as.data.frame(DF.output);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- getData.JHU_standardize.output(
        DF.input = DF.output
        );

    #cat("\nstr(DF.output)\n");
    #print( str(DF.output)   );

    #cat("\nsummary(DF.output)\n");
    #print( summary(DF.output)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( DF.output );

    }

##################################################
getData.JHU_standardize.output <- function(
    DF.input = NULL
    ) {

    DF.output <- DF.input;

    DF.output[,"date"] <- gsub(
        x           = DF.output[,"date"],
        pattern     = "\\.",
        replacement = "-"
        );

    DF.output[,"day"  ] <- DF.output[,"date"];
    DF.output[,"month"] <- DF.output[,"date"];
    DF.output[,"year" ] <- DF.output[,"date"];

    DF.output[,"year"] <- gsub(
        x           = DF.output[,"year"],
        pattern     = "^[0-9]{1,2}-[0-9]{1,2}-",
        replacement = ""
        );
    DF.output[,"year"] <- paste0("20",DF.output[,"year"]);
    DF.output[,"year"] <- as.integer(DF.output[,"year"]);

    DF.output[,"month"] <- gsub(
        x           = DF.output[,"month"],
        pattern     = "-[0-9]{1,2}-[0-9]{1,2}$",
        replacement = ""
        );
    DF.output[,"month"] <- as.integer(DF.output[,"month"]);

    DF.output[,"day"] <- gsub(
        x           = DF.output[,"day"],
        pattern     = "^[0-9]{1,2}-",
        replacement = ""
        );
    DF.output[,"day"] <- gsub(
        x           = DF.output[,"day"],
        pattern     = "-[0-9]{1,2}$",
        replacement = ""
        );
    DF.output[,"day"] <- as.integer(DF.output[,"day"]);

    DF.output[,"DateRep"] <- as.Date(paste(
        DF.output[,"year"],
        DF.output[,"month"],
        DF.output[,"day"],
        sep="-"
        ));

    DF.output <- DF.output[,c("DateRep","day","month","year","Cases","Deaths","province")];
    DF.output <- DF.output %>% dplyr::arrange(province,DateRep);
    DF.output <- as.data.frame(DF.output);

    DF.output <- DF.output[DF.output[,"province"] != "Grand Princess",  ];
    DF.output <- DF.output[DF.output[,"province"] != "Diamond Princess",];
    DF.output <- DF.output[DF.output[,"province"] != "Recovered",       ];

    DF.dictionary <- data.frame(
        province.short = c('BC','AB','SK','MB','ON','QC','NB','NL','NS','PE','YK','NT'),
        province.long  = c(
            "British Columbia",
            "Alberta",
            "Saskatchewan",
            "Manitoba",
            "Ontario",
            "Quebec",
            "New Brunswick",
            "Newfoundland and Labrador",
            "Nova Scotia",
            "Prince Edward Island",
            "Yukon",
            "Northwest Territories"    
            )
        );

    cat("\nDF.dictionary\n");
    print( DF.dictionary   );

    for ( i in 1:nrow(DF.dictionary)) {
        DF.output[,"province"] <- gsub(
            x           = DF.output[,"province"],
            pattern     = DF.dictionary[i,"province.long"],
            replacement = DF.dictionary[i,"province.short"]
            );
        }

    return( DF.output );

    }

getData.JHU_download <- function(
    input.file  = NULL,
    target.url  = NULL,
    output.file = NULL
    ) {
    if ( !is.null(input.file) ) {
        DF.output <- read.csv(input.file, stringsAsFactors = FALSE);
    } else {
        tryCatch(
            expr = {
                code <- download.file(url = target.url, destfile = output.file);
                 if (code != 0) { stop("Error downloading file") }
                },
            error = function(e) {
                stop(sprintf("Error downloading file '%s': %s, please check %s", url, e$message, url_page));
                }
            );
        DF.output <- read.csv(output.file, stringsAsFactors = FALSE);
        } 
    return( DF.output );
    }

getData.JHU_reformat <- function(
    DF.input      = NULL,
    colname.value = NULL
    ) {

    require(tidyr);

    DF.output <- DF.input;
    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "^X",
        replacement = ""
        );

    DF.output <- DF.output[DF.output[,"Country.Region"] == "Canada",];

    retained.columns <- setdiff( colnames(DF.output) , c("Lat","Long","Country.Region") );
    DF.output <- DF.output[,retained.columns];

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "Province\\.State",
        replacement = "province"
        );

    DF.output <- DF.output %>% tidyr::gather(
        key   = "date",
        value = "colname_temp",
        -province
        );

    DF.output <- as.data.frame(DF.output);

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "colname_temp",
        replacement = colname.value
        );

    return( DF.output );

    }

