
eight.schools <- function(
    FILE.stan    = NULL,
    RData.output = 'model-stan.RData'
    ) {

    thisFunctionName <- "eight.schools";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(rstan);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(RData.output) ) {

        cat(paste0("\n### ",RData.output," already exists; loading this file ...\n"));

        list.data.raw <- readRDS(file = RData.output);

        cat(paste0("\n### Finished loading raw data.\n"));

    } else {

        rstan::rstan_options(auto_write = TRUE);

        schools_dat <- list(
            J     = 8,
            y     = c(28,  8, -3,  7, -1,  1, 18, 12),
            sigma = c(15, 10, 16, 11,  9, 11, 10, 18)
            );

        results.stan <- rstan::stan(
            file = FILE.stan,
            data = schools_dat
            );

        if (!is.null(RData.output)) {
            saveRDS(object = results.stan, file = RData.output);
            }

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( results.stan );

    }

##################################################

