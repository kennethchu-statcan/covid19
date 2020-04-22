
getData.raw <- function(
    csv.Census2016.age.sex = '98-400-X2016001_English_CSV_data.csv'
    ) {

    thisFunctionName <- "getData.raw";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(lubridate);
    require(readr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.Census2016.age.sex <- getData.raw_load.or.download(
        csv.file = csv.Census2016.age.sex
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( DF.Census2016.age.sex );

    }

##################################################
getData.raw_load.or.download <- function(
    target.url = NULL,
    csv.file   = NULL
    ) {

    if ( file.exists(csv.file) ) {

        cat(paste0("\n# Data file ",csv.file," already exists; loading this file ...\n"));
        DF.output <- read.csv(file = csv.file, stringsAsFactors = FALSE, na.strings = c("NA","N/A"));
        cat(paste0("\n# Loading complete: ",csv.file,".\n"));
    
    } else {

        cat(paste0("\n# Data file ",csv.file," does NOT yet exists; downloading it from: ",target.url,"\n"));
        tryCatch(
            expr = {
                code <- download.file(url = target.url, destfile = csv.file);
                if (code != 0) { stop("Error downloading file") }
                },
            error = function(e) {
                stop(sprintf("Error downloading file '%s': %s", target.url, e$message));
                }
            );
        cat(paste0("\n# Download complete: ",target.url,".\n"));
        DF.output <- read.csv(file = csv.file, stringsAsFactors = FALSE);

        }

    return( DF.output );

    }

