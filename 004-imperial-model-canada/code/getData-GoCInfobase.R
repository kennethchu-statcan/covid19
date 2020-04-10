
getData.GoCInfobase <- function(
    GoCInfobase.file  = NULL, 
    GoCInfobase.url   = "https://health-infobase.canada.ca/src/data/covidLive/covid19.csv",
    GoCInfobase.RData = "input-covid19-GoCInfobase.RData"
    ) {

    thisFunctionName <- "getData.GoCInfobase";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(dplyr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(GoCInfobase.RData) ) {

        cat(paste0("\n### ",GoCInfobase.RData," already exists; loading this file ...\n"));
        DF.output <- readRDS(file = GoCInfobase.RData);
        cat(paste0("\n### Finished loading raw data.\n"));

    } else {

        DF.GoCInfobase <- getData.GoCInfobase_download(
            input.file  = GoCInfobase.file,
            target.url  = GoCInfobase.url,
            output.file = gsub(x = GoCInfobase.RData, pattern = "\\.RData", replacement = "-raw.csv")
            )

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.GoCInfobase.cases <- getData.GoCInfobase_widen(
        DF.input      = DF.GoCInfobase,
        colname.value = "numconf"
        );

    DF.GoCInfobase.deaths <- getData.GoCInfobase_widen(
        DF.input      = DF.GoCInfobase,
        colname.value = "numdeaths"
        );

    cat("\nstr(DF.GoCInfobase.cases)\n");
    print( str(DF.GoCInfobase.cases)   );

    cat("\nstr(DF.GoCInfobase.deaths)\n");
    print( str(DF.GoCInfobase.deaths)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.GoCInfobase.cases <- getData.GoCInfobase_undo.cumulative.sum(
        DF.input = DF.GoCInfobase.cases
        );

    DF.GoCInfobase.deaths <- getData.GoCInfobase_undo.cumulative.sum(
        DF.input = DF.GoCInfobase.deaths
        );

    cat("\nstr(DF.GoCInfobase.cases)\n");
    print( str(DF.GoCInfobase.cases)   );

    cat("\nstr(DF.GoCInfobase.deaths)\n");
    print( str(DF.GoCInfobase.deaths)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.GoCInfobase.cases <- getData.GoCInfobase_elongate(
        DF.input      = DF.GoCInfobase.cases,
        colname.value = "cases"
        );

    DF.GoCInfobase.deaths <- getData.GoCInfobase_elongate(
        DF.input      = DF.GoCInfobase.deaths,
        colname.value = "deaths"
        );

    cat("\nstr(DF.GoCInfobase.cases)\n");
    print( str(DF.GoCInfobase.cases)   );

    cat("\nstr(DF.GoCInfobase.deaths)\n");
    print( str(DF.GoCInfobase.deaths)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- dplyr::full_join(
        x  = DF.GoCInfobase.cases,
        y  = DF.GoCInfobase.deaths,
        by = c("jurisdiction","date")
        );

    DF.output <- as.data.frame(DF.output);

    cat("\nstr(DF.output)\n");
    print( str(DF.output)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- getData.GoCInfobase_standardize.output(
        DF.input = DF.output
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if (!is.null(GoCInfobase.RData)) {
        saveRDS(object = DF.output, file = GoCInfobase.RData);
        write.csv(
            x         = DF.output,
            file      = gsub(x = GoCInfobase.RData, pattern = "\\.RData", replacement = ".csv"),
            row.names = FALSE
            );
        }
    
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( DF.output );

    }

##################################################
getData.GoCInfobase_elongate <- function(
    DF.input      = NULL,
    colname.value = NULL
    ) {
    require(tidyr);
    DF.output <- DF.input;
    DF.output <- DF.output %>% tidyr::gather(
        key   = "date",
        value = "colname_temp",
        -jurisdiction
        );
    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "colname_temp",
        replacement = colname.value
        );
    return( DF.output );
    }

getData.GoCInfobase_widen <- function(
    DF.input      = NULL,
    colname.value = NULL
    ) {

    require(tidyr);

    retained.colnames <- c("prname","date",colname.value);
    DF.output <- DF.input[,retained.colnames];

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "prname",
        replacement = "jurisdiction"
        );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = colname.value,
        replacement = "colname.temp"
        );

    DF.output[,"date"] <- as.character(as.Date(
        x          = DF.output[,"date"],
        tryFormats = c("%d-%m-%Y")
        ));

    DF.output <- DF.output %>% tidyr::spread(
        key   = "date",
        value = "colname.temp"
        );

    DF.output <- as.data.frame(DF.output);

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "colname.temp",
        replacement = colname.value
        );

    return( DF.output );

    }

getData.GoCInfobase_undo.cumulative.sum <- function(
    DF.input = NULL
    ) {

    DF.output <- DF.input;

    colnames.non.count <- "jurisdiction";
    colnames.count     <- setdiff(colnames(DF.output),colnames.non.count);

    DF.count <- DF.output[,colnames.count];
    colnames.DF.count <- colnames(DF.count);

    for ( i in 1:nrow(DF.count) ) {
        temp.vector <- DF.count[i,];
        temp.vector[is.na(temp.vector)] <- 0;
        DF.count[i,] <- temp.vector;
        }

    rightward.shift.1 <- cbind(
        rep(0,nrow(DF.count)),
        DF.count[,1:(ncol(DF.count)-1)]
        );

    DF.count <- as.data.frame(DF.count);
    colnames(DF.count) <- colnames.DF.count;

    DF.output <- cbind(
        jurisdiction = as.character(DF.output[,colnames.non.count]),
        DF.count
        );

    DF.output[,"jurisdiction"] <- as.character(DF.output[,"jurisdiction"]);

    return( DF.output );

    }

getData.GoCInfobase_standardize.output <- function(
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
        pattern     = "-[0-9]{1,2}-[0-9]{1,2}$",
        replacement = ""
        );
    DF.output[,"year"] <- as.integer(DF.output[,"year"]);

    DF.output[,"month"] <- gsub(
        x           = DF.output[,"month"],
        pattern     = "^[0-9]{1,4}-",
        replacement = ""
        );
    DF.output[,"month"] <- gsub(
        x           = DF.output[,"month"],
        pattern     = "-[0-9]{1,2}$",
        replacement = ""
        );
    DF.output[,"month"] <- as.integer(DF.output[,"month"]);

    DF.output[,"day"] <- gsub(
        x           = DF.output[,"day"],
        pattern     = "^[0-9]{1,4}-[0-9]{1,2}-",
        replacement = ""
        );
    DF.output[,"day"] <- as.integer(DF.output[,"day"]);

    DF.output[,"DateRep"] <- as.Date(paste(
        DF.output[,"year"],
        DF.output[,"month"],
        DF.output[,"day"],
        sep="-"
        ));

    DF.output <- DF.output[,c("DateRep","day","month","year","cases","deaths","jurisdiction")];
    DF.output <- DF.output %>% dplyr::arrange(jurisdiction,DateRep);
    DF.output <- as.data.frame(DF.output);

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

    DF.output <- DF.output[DF.output[,"jurisdiction"] %in% DF.dictionary[,"province.long"],  ];

    for ( i in 1:nrow(DF.dictionary)) {
        DF.output[,"jurisdiction"] <- gsub(
            x           = DF.output[,"jurisdiction"],
            pattern     = DF.dictionary[i,"province.long"],
            replacement = DF.dictionary[i,"province.short"]
            );
        }

    return( DF.output );

    }

getData.GoCInfobase_download <- function(
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
                stop(sprintf("Error downloading file '%s': %s", target.url, e$message));
                }
            );
        DF.output <- read.csv(output.file, stringsAsFactors = FALSE);
        } 
    return( DF.output );
    }

