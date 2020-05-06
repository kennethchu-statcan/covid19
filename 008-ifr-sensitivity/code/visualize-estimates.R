
visualize.estimates <- function(
    list.input = NULL
    ) {

    thisFunctionName <- "visualize.estimates";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    visualize.estimates_alpha(
        DF.input = list.input[["alpha"]]
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( NULL );

    }

###################################################
visualize.estimates_alpha <- function(
    DF.input = NULL
    ) {

    temp.covariates <- unique(DF.input[,"covariate"]);
    for ( temp.covariate in temp.covariates ) {
        DF.temp <- DF.input[DF.input[,"covariate"] == temp.covariate,];
        cat("\nDF.temp\n");
        print( DF.temp   );
        }

    return( NULL );

    }

