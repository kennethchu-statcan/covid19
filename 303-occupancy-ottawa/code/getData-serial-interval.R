
getData.serial.interval <- function(
    csv.serial.interval = NULL,
    csv.output          = "input-serial-interval.csv",
    length.tail         = 10000
    ) {

    thisFunctionName <- "getData.serial.interval";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(lubridate);
    require(readr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(csv.output) ) {

        cat(paste0("\n# The data file ",csv.output," already exists; loading this file ...\n"));
        DF.output <- read.csv(file = csv.output, stringsAsFactors = FALSE, na.strings = c("NA","N/A"));
        cat(paste0("\n# Loading complete: ",csv.output,"\n"));

    } else {

        DF.output <- read.csv( file = csv.serial.interval, stringsAsFactors = FALSE );

        DF.output[nrow(DF.output),'fit'] <- DF.output[nrow(DF.output),'fit'] / 2;

        cat("\nstr(DF.output)\n");
        print( str(DF.output)   );

        last.X   <- DF.output[nrow(DF.output),'X'  ];
        last.fit <- DF.output[nrow(DF.output),'fit'];

        DF.tail <- data.frame(
            X   = seq(last.X+1,last.X+length.tail),
            fit = rep(last.fit/length.tail, times = length.tail)
            );

        cat("\nstr(DF.tail)\n");
        print( str(DF.tail)   );

        DF.output <- rbind(DF.output,DF.tail);

        cat("\nstr(DF.output)\n");
        print( str(DF.output)   );

        cat("\nsum(DF.output[,'fit'])\n");
        print( sum(DF.output[,'fit'])   );

        write.csv(
            x         = DF.output,
            file      = csv.output,
            row.names = FALSE
            );

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( DF.output );

    }

##################################################
