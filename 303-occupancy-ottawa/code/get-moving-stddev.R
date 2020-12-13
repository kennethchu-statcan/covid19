
get.moving.stddev <- function(
    input.vector = NULL,
    half.window  = 2
    ) {

    # thisFunctionName <- "get.moving.stddev";
    # cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    # cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    require(matrixStats);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    nrow.DF.temp <- length(input.vector) - 2 * half.window;
    ncol.DF.temp <- 1 + 2 * half.window;
    DF.temp      <- matrix(
        data = rep(x = 0, times = nrow.DF.temp * ncol.DF.temp),
        nrow = nrow.DF.temp,
        ncol = ncol.DF.temp
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    for ( temp.shift in seq(-half.window,half.window,1) ) {
        column.index <- 1 + temp.shift + half.window;
        DF.temp[,column.index] <- input.vector[seq(column.index,column.index+nrow.DF.temp-1,1)]
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    output.vector <- c(
        rep(Inf,half.window),
        sqrt(matrixStats::rowVars(x = DF.temp)),
        rep(Inf,half.window)
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    # cat(paste0("\n",thisFunctionName,"() quits."));
    # cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( output.vector );

    }

##################################################
