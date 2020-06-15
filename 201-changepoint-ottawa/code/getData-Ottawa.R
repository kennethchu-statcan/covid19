
getData.Ottawa <- function(
    xlsx.input.hospitalization = NULL,
    xlsx.input.case.and.death  = NULL,
    RData.ottawa               = "ottawa.RData"
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

        DF.hospitalization <- getData.Ottawa_raw(
            input.file  = xlsx.input.hospitalization,
            output.file = "raw-ottawa-hospitalization.csv"
            )

        DF.case <- getData.Ottawa_raw(
            input.file  = xlsx.input.case.and.death,
            input.sheet = "DailyCOVID-19OttCases",
            output.file = "raw-ottawa-case.csv"
            )

        DF.death <- getData.Ottawa_raw(
            input.file  = xlsx.input.case.and.death,
            input.sheet = "DailyCOVID-19OttDeaths",
            output.file = "raw-ottawa-death.csv"
            )

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.hospitalization <- getData.Ottawa_standardize(
            DF.input = DF.hospitalization,
            list.replace.colnames = list(
                jurisdiction = "patient phu",
                date         = "date",
                hospitalized = "hospitalized confirmed covid-19 patients \\(ottawa residents\\)",
                admission    = "new admissions for covid-19 \\(ottawa residents\\)"
                )
            );

        DF.hospitalization <- getData.Ottawa_add.discharge(
            DF.input = DF.hospitalization
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.case <- getData.Ottawa_standardize(
            DF.input = DF.case,
            list.replace.colnames = list(
                jurisdiction = "phu of person with covid-19",
                date         = "earliest of onset, test or reported date",
                case         = "daily total"
                )
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.death <- getData.Ottawa_standardize(
            DF.input = DF.death,
            list.replace.colnames = list(
                jurisdiction = "phu of person with covid-19 who died",
                date         = "date of death",
                death        = "daily total number of deaths"
                )
            );

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(DF.hospitalization)\n");
    print( str(DF.hospitalization)   );

    cat("\nstr(DF.case)\n");
    print( str(DF.case)   );

    cat("\nstr(DF.death)\n");
    print( str(DF.death)   );

    my.jurisdictions <- unique(c(
        unique(DF.hospitalization[,"jurisdiction"]),
        unique(DF.case[,           "jurisdiction"]),
        unique(DF.death[,          "jurisdiction"])
        ));

    my.dates <- seq(
        from = min(min(DF.hospitalization[,"date"]),min(DF.case[,"date"]),min(DF.death[,"date"])),
        to   = max(max(DF.hospitalization[,"date"]),max(DF.case[,"date"]),max(DF.death[,"date"])),
        by   = "day"
        );

    DF.output <- expand.grid(
        date         = my.dates,
        jurisdiction = my.jurisdictions
        );

    DF.output <- dplyr::left_join(
        x  = DF.output,
        y  = DF.case,
        by = c("jurisdiction","date")
        );

    DF.output <- dplyr::left_join(
        x  = DF.output,
        y  = DF.death,
        by = c("jurisdiction","date")
        );

    DF.output <- dplyr::left_join(
        x  = DF.output,
        y  = DF.hospitalization,
        by = c("jurisdiction","date")
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    for ( temp.colname in setdiff(colnames(DF.output),"date") ) {
        DF.output[is.na(DF.output[,temp.colname]),temp.colname] <- 0;
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    base::saveRDS(
        file   = RData.ottawa,
        object = DF.output
        );

    write.csv(
        x         = DF.output,
        file      = "preprocessed-ottawa.csv",
        row.names = FALSE
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( DF.output );

    }

##################################################
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

getData.Ottawa_raw <- function(
    input.file  = NULL,
    input.sheet = NULL,
    output.file = NULL
    ) {
    require(readxl);
    DF.output <- readxl::read_excel(path = input.file, sheet = input.sheet);
    DF.output <- as.data.frame(DF.output);
    write.csv(
        x         = DF.output,
        file      = output.file,
        row.names = FALSE
        );
    return( DF.output );
    }

getData.Ottawa_standardize <- function(
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

