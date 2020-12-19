
getData.Ottawa <- function(
    csv.input    = NULL,
    RData.ottawa = "data-ottawa-raw.RData"
    ) {

    thisFunctionName <- "getData.Ottawa";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    require(dplyr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(RData.ottawa) ) {

        cat(paste0("\n# ",RData.ottawa," already exists; loading this file ...\n"));
        DF.output <- readRDS(file = RData.ottawa);
        cat(paste0("\n# Loading complete: ",RData.ottawa,"\n"));

    } else {

        DF.raw.ottawa <- getData.Ottawa_csv(
            input.file = csv.input
            );

        cat("\nstr(DF.raw.ottawa)\n");
        print( str(DF.raw.ottawa)   );

        DF.output <- getData.Ottawa_standardize(
            DF.input = DF.raw.ottawa
            );

        cat("\nstr(DF.output)\n");
        print( str(DF.output)   );

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    write.csv(
        x         = DF.output,
        file      = "data-ottawa-raw.csv",
        row.names = FALSE
        );

    base::saveRDS(
        file   = RData.ottawa,
        object = DF.output
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( DF.output );

    }

##################################################
getData.Ottawa_standardize.DELETEME <- function(
    DF.input              = NULL,
    list.replace.colnames = list(),
    retained.colnames     = tolower(names(list.replace.colnames))
    ) {

    DF.output <- DF.input;
    colnames(DF.output) <- tolower(colnames(DF.output));

    for ( temp.replacement in names(list.replace.colnames) ) {
        colnames(DF.output) <- gsub(
            x = colnames(DF.output),
            pattern     = list.replace.colnames[[temp.replacement]],
            replacement = temp.replacement
            );
        }

    DF.output <- DF.output[,retained.colnames];

    return( DF.output );

    }

getData.Ottawa_standardize <- function(
    DF.input = NULL
    ) {

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- DF.input;

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    # patching column name changes in Ottawa data portal that
    # occured some time between December 13 and 18.

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "^_Date$",
        replacement = "Date"
        );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "^Cumulative_Deaths_byDate_of_Death$",
        replacement = "Cumulative_Deaths_by_Date_of_Death"
        );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "^Daily_Cases_by_ReportedDate$",
        replacement = "Daily_Cases_by_Reported_Date"
        );

    cat("\ncolnames(DF.output)\n");
    print( colnames(DF.output)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    selected.colnames <- c(
        "Date",
        "Cumulative_Deaths_by_Date_of_Death",
        "Daily_Cases_by_Reported_Date",
        "Cases_Newly_Admitted_to_Hospital",
        "Cases_Currently_in_Hospital",
        "Cases_Currently_in_ICU",
        "OBJECTID"
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    missing.colnames <- setdiff(selected.colnames,colnames(DF.output));
    if ( length(missing.colnames) > 0 ) {
        cat("\ngetData.Ottawa_standardize(): missing.colnames\n");
        print( missing.colnames );
    } else {
        cat("\ngetData.Ottawa_standardize(): all expected columns are present.\n");
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- DF.output[,selected.colnames];
    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "Cumulative_Deaths_by_Date_of_Death",
        replacement = "cumulative.deaths"
        );
    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "Daily_Cases_by_Reported_Date",
        replacement = "new.cases"
        );
    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "Cases_Newly_Admitted_to_Hospital",
        replacement = "new.hospital.admissions"
        );
    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "Cases_Currently_in_Hospital",
        replacement = "occupancy.hospital"
        );
    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "Cases_Currently_in_ICU",
        replacement = "occupancy.ICU"
        );
    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "Date",
        replacement = "date"
        );
    colnames(DF.output) <- tolower(colnames(DF.output));
    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "objectid",
        replacement = "object.ID"
        );

    cat("\ncolnames(DF.output)\n");
    print( colnames(DF.output)   );

    DF.output[,'date'] <- as.Date(gsub(
        x           = DF.output[,'date'],
        pattern     = " 00:00:00",
        replacement = ""
        ));

    temp.colnames <- c(
        "cumulative.deaths",
        "new.cases",
        "new.hospital.admissions",
        "occupancy.hospital",
        "occupancy.icu"
        );

    missing.colnames <- setdiff(temp.colnames,colnames(DF.output));
    cat("\ngetData.Ottawa_standardize(): missing.colnames\n");
    print( missing.colnames );

    for ( temp.variable in temp.colnames) {
        DF.output[is.na(DF.output[,temp.variable]),temp.variable] <- 0;
        }
    return( DF.output );
    }

getData.Ottawa_add.discharge <- function(
    DF.input = NULL
    ) {

    DF.output <- DF.input;

    temp.vector <- c(DF.output[2:nrow(DF.output),"admission"],NA);
    temp.vector <- DF.output[,"hospitalized"] + temp.vector;
    DF.output[,"temp"] <- c(NA,temp.vector[1:(nrow(DF.output)-1)]);

    temp.vector <- DF.output[,"temp"] - DF.output[,"hospitalized"];
    DF.output[,"discharge"] <- temp.vector;

    DF.output <- DF.output[,c("jurisdiction","date","hospitalized","admission","discharge")];

    return( DF.output );

    }

getData.Ottawa_csv <- function(
    input.file = NULL
    ) {
    require(readr);
    DF.output <- readr::read_csv(file = input.file);
    DF.output <- as.data.frame(DF.output);
    return( DF.output );
    }
