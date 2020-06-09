
getData.Ottawa <- function(
    xlsx.input.hospitalization = NULL,
    xlsx.input.case.and.death  = NULL,
    RData.ottawa               = "ottawa.RData"
    ) {

    thisFunctionName <- "getData.Ottawa";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

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
                date = "earliest of onset, test or reported date",
                case = "daily total"
                )
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.death <- getData.Ottawa_standardize(
            DF.input = DF.death,
            list.replace.colnames = list(
                date  = "date of death",
                death = "daily total number of deaths"
                )
            );

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(DF.case)\n");
    print( str(DF.case)   );

    cat("\nstr(DF.death)\n");
    print( str(DF.death)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- DF.hospitalization;

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

    DF.output <- DF.output[,c("date","hospitalized","admission","discharge")];

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
    retained.colnames     = unique(tolower(c("date",names(list.replace.colnames))))
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

getData.Ottawa_standardize.DELETEME <- function(
    DF.input = NULL
    ) {

    DF.output <- DF.input;

    colnames(DF.output) <- gsub(
        x = colnames(DF.output),
        pattern     = "Hospitalized confirmed COVID-19 patients \\(Ottawa residents\\)",
        replacement = "hospitalized"
        );

    colnames(DF.output) <- gsub(
        x = colnames(DF.output),
        pattern     = "New admissions for COVID-19 \\(Ottawa residents\\)",
        replacement = "admission"
        );

    colnames(DF.output) <- tolower(colnames(DF.output));

    DF.output <- DF.output[,c("date","hospitalized","admission")];

    return( DF.output );

    }

