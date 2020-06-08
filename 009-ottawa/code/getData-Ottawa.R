
getData.Ottawa <- function(
    xlsx.input   = NULL,
    RData.ottawa = "ottawa.RData"
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

        DF.ottawa <- getData.Ottawa_raw(
            input.file  = xlsx.input,
            output.file = "raw-ottawa.csv"
            )

        DF.ottawa <- getData.Ottawa_standardize(
            DF.input = DF.ottawa
            );

        DF.ottawa <- getData.Ottawa_add.discharge(
            DF.input = DF.ottawa
            );

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- DF.ottawa;

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
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
getData.Ottawa_add.discharge <- function(
    DF.input = NULL
    ) {

    DF.output <- DF.input;

    temp.vector <- c(DF.output[2:nrow(DF.output),"admission"],NA);
    temp.vector <- DF.output[,"hospitalized"] + temp.vector;
    DF.output[,"temp"] <- c(NA,temp.vector[1:(nrow(DF.output)-1)]);

    temp.vector <- DF.output[,"temp"] - DF.output[,"hospitalized"];
    #DF.output[,"discharge"] <- c(temp.vector[2:nrow(DF.output)],0);
    DF.output[,"discharge"] <- temp.vector;

    DF.output <- DF.output[,c("date","hospitalized","admission","discharge")];

    return( DF.output );

    }

getData.Ottawa_raw <- function(
    input.file  = NULL,
    output.file = NULL
    ) {
    require(readxl);
    DF.output <- readxl::read_excel(path = input.file);
    DF.output <- as.data.frame(DF.output);
    write.csv(
        x         = DF.output,
        file      = output.file,
        row.names = FALSE
        );
    return( DF.output );
    }

getData.Ottawa_standardize <- function(
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

