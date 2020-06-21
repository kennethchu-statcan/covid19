
patchData <- function(
    list.covid19.data = NULL,
    min.Date          = as.Date("2019-12-31")
    ) {

    thisFunctionName <- "patchData";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(lubridate);
    require(readr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output <- list.covid19.data;

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output[["ECDC"]] <- patchData_ECDC(
        DF.input = list.output[["ECDC"]]
        );

    write.csv(
        x         = list.output[["ECDC"]],
        file      = 'tmp-covid19-ECDC-patched.csv',
        row.names = FALSE
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output[["GoCInfobase"]] <- patchData_GoCInfobase(
        DF.input = list.output[["GoCInfobase"]],
        min.Date = min.Date
        );

    write.csv(
        x         = list.output[["GoCInfobase"]],
        file      = 'tmp-covid19-GoCInfobase-patched.csv',
        row.names = FALSE
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output[["Ottawa"]] <- patchData_Ottawa(
        DF.input = list.output[["Ottawa"]],
        min.Date = min.Date
        );

    write.csv(
        x         = list.output[["Ottawa"]],
        file      = 'tmp-covid19-Ottawa-patched.csv',
        row.names = FALSE
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( list.output );

    }

###################################################
patchData_ECDC <- function(
    DF.input = NULL
    ) {

    require(dplyr);
    require(tidyr);
    require(lubridate);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- DF.input;

    cat("\nstr(DF.input)\n");
    print( str(DF.input)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    offending.jurisdiction    <- "France";
    is.offending.jurisdiction <- (DF.output[,"countriesAndTerritories"] == offending.jurisdiction);

    offending.year  <- 2020;
    offending.month <- 6;
    offending.day   <- 3;

    is.offending.year  <- (DF.output[,"year"]  == offending.year);
    is.offending.month <- (DF.output[,"month"] == offending.month);
    is.offending.day   <- (DF.output[,"day"]   == offending.day);

    is.offending.row <- ( is.offending.jurisdiction & is.offending.year & is.offending.month & is.offending.day );
    if ( 1 == sum(is.offending.row) ) {
        temp.value <- DF.output[is.offending.row,"cases"];
        print( temp.value   );
        if ( temp.value < 0 ) {
            cat("\n### patchData_ECDC(): offending row:\n");
            print( DF.output[is.offending.row,] );
            cat(paste0("\n# ~~~ replacing offending value ",temp.value," with 76\n"));
            DF.output[is.offending.row,"cases"] <- 76;
            cat("\n# ~~~ patched row:\n");
            print( DF.output[is.offending.row,] );
            }
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output[,"cases"] <- abs( DF.output[,"cases"] );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    return( DF.output );

    }

patchData_Ottawa <- function(
    DF.input = NULL,
    min.Date = NULL
    ) {

    require(dplyr);
    require(tidyr);
    require(lubridate);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.input[,"date"] <- as.Date(DF.input[,"date"]);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    colnames.input   <- colnames(DF.input);
    colnames.numeric <- c("case","death","hospitalized","admission","discharge");
    
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    unique.jurisdictions <- unique(DF.input[,"jurisdiction"]);
    unique.dates         <- unique(DF.input[,"date"]);
    unique.dates         <- seq(min(min.Date,min(unique.dates)),max(unique.dates),by=1);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    retained.colnames <- c("jurisdiction","date",colnames.numeric);
    DF.counts <- DF.input[,retained.colnames];

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.grid <- expand.grid(jurisdiction = unique.jurisdictions, date = unique.dates);
    attr(DF.grid,"out.attrs") <- NULL;

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- dplyr::full_join(
        x  = DF.grid,
        y  = DF.counts,
        by = c("jurisdiction","date")
        );

    DF.output <- as.data.frame(DF.output %>% dplyr::arrange(jurisdiction,date));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    leading.colnames <- c("date","jurisdiction");
    ordered.colnames <- c(
        leading.colnames,
        setdiff(colnames(DF.output),leading.colnames)
        );
    DF.output <- DF.output[,ordered.colnames];

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    for ( temp.colname in colnames.numeric ) {
        temp.vector <- DF.output[,temp.colname];
        temp.vector[is.na(temp.vector)] <- 0;
        DF.output[,temp.colname] <- temp.vector;
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    return( DF.output );

    }

patchData_GoCInfobase <- function(
    DF.input               = NULL,
    min.Date               = NULL,
    dateFormat.GoCInfobase = "%d-%m-%Y"
    ) {

    require(dplyr);
    require(tidyr);
    require(lubridate);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    colnames.input   <- colnames(DF.input);
    colnames.numeric <- c("numconf","numprob","numdeaths","numtotal","numtested","numrecover");

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    for ( temp.colname in colnames.numeric ) {
        if ( is.character(DF.input[,temp.colname]) ) {
            DF.input[,temp.colname] <- as.integer(gsub(
                x           = DF.input[,temp.colname],
                pattern     = '\\s+',
                replacement = ""
                ));
            }
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    unique.pruids <- unique(DF.input[,"pruid"]);
    unique.dates  <- as.Date(x = unique(DF.input[,"date"]), tryFormats = dateFormat.GoCInfobase);
    unique.dates  <- seq(min(min.Date,min(unique.dates)),max(unique.dates),by=1);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.dictionary.pruid <- unique(DF.input[,c("pruid","prname","prnameFR")]);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    retained.colnames <- c("pruid","date",colnames.numeric);
    DF.counts <- DF.input[,retained.colnames];
    DF.counts[,"Date.Obj"] <- as.Date(x = DF.counts[,"date"], tryFormats = c("%d-%m-%Y"));
    DF.counts <- DF.counts[,setdiff(colnames(DF.counts),"date")];

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.grid <- expand.grid(pruid = unique.pruids, Date.Obj = unique.dates);
    attr(DF.grid,"out.attrs") <- NULL;

    DF.grid[,"date"] <- format(x = DF.grid[,"Date.Obj"], dateFormat.GoCInfobase);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- dplyr::full_join(
        x  = DF.grid,
        y  = DF.dictionary.pruid,
        by = c("pruid")
        );

    DF.output <- dplyr::full_join(
        x  = DF.output,
        y  = DF.counts,
        by = c("pruid","Date.Obj")
        );

    DF.output <- as.data.frame(DF.output %>% dplyr::arrange(pruid,Date.Obj));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    leading.colnames <- c("pruid","prname","prnameFR","Date.Obj");
    ordered.colnames <- c(
        leading.colnames,
        setdiff(colnames(DF.output),leading.colnames)
        );
    DF.output <- DF.output[,ordered.colnames];

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    for ( temp.colname in colnames.numeric ) {
        temp.vector <- DF.output[,temp.colname];
        temp.vector[is.na(temp.vector)] <- 0;
        DF.output[,temp.colname] <- temp.vector;
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    for ( temp.pruid in unique(DF.output[,"pruid"]) ) {
        DF.temp <- DF.output[DF.output[,"pruid"] == temp.pruid,];
        for ( temp.index in 2:nrow(DF.temp) ) {
            temp.vector.zero   <- DF.temp[temp.index,  colnames.numeric];
            temp.vector.minus1 <- DF.temp[temp.index-1,colnames.numeric];
            is.a.drop <- (temp.vector.zero < temp.vector.minus1);
            temp.vector.two            <- temp.vector.zero;
            temp.vector.two[is.a.drop] <- temp.vector.minus1[is.a.drop];
            DF.temp[temp.index,colnames.numeric] <- temp.vector.two;
            }
        DF.output[DF.output[,"pruid"] == temp.pruid,] <- DF.temp;
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- DF.output[,setdiff(colnames(DF.output),"Date.Obj")];

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    return( DF.output );

    }

