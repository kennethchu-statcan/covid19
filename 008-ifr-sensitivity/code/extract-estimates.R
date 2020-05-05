
extract.estimates <- function(
    input.directory = NULL,
    simulation.ID   = NULL
    ) {

    thisFunctionName <- "extract.estimates";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    RData.input <- file.path(input.directory,"stan-model-base.RData");
    list.input <- readRDS(file = RData.input);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nnames(list.input)\n");
    print( names(list.input)   );

    cat("\nstr(list.input)\n");
    print( str(list.input)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output  <- list();

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.temp <- extract.estimates_posteriorMean.alpha(
        list.input = list.input
        );
    list.output[["alpha"]] <- DF.temp;

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    my.variables <- c("mu","prediction","E_deaths","Rt");
    for ( my.variable in my.variables ) {
        DF.temp <- extract.estimates_posteriorMean.jurisdiction(
            list.input = list.input,
            variable   = my.variable
            );
        list.output[[my.variable]] <- DF.temp;
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    for ( temp.name in names(list.output) ) {
        DF.temp <- list.output[[temp.name]];
        DF.temp <- cbind(
            simulation.ID = as.character(rep(simulation.ID,nrow(DF.temp))),
            DF.temp,
            stringsAsFactors = FALSE
            );
        list.output[[temp.name]] <- DF.temp;
        }
    
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(list.output)\n");
    print( str(list.output)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    # return( list.output );
    return( NULL );

    }

###################################################
extract.estimates_posteriorMean.alpha <- function(
    list.input       = NULL,
    covariate.labels = c(
        "school.closure",
        "self.isolating.if.ill",
        "public.events",
        "any.intervention",
        "lockdown",
        "social.distancing.encouraged"
        )
    ) {

    DF.output <- data.frame();

    n.alphas <- ncol(list.input[["out"]][["alpha"]]);
    for ( j in seq(1,n.alphas) ) {

        DF.temp <- data.frame(
            variable         = "exp.minus.alpha",
            covariate        = covariate.labels[j],
            posterior.mean   = mean( exp( - list.input[["out"]][["alpha"]][,j] ) ),
            stringsAsFactors = FALSE
            );
    
        DF.output <- rbind(DF.output,DF.temp);

        } 

    return( DF.output );    
    
    }

extract.estimates_posteriorMean.jurisdiction <- function(
    list.input = NULL,
    variable   = NULL
    ) {

    DF.output <- data.frame();

    n.jurisdictions <- length(list.input[["jurisdictions"]]);
    for ( i in seq(1,n.jurisdictions) ) {

        is.time.series <- (3 == length(dim(list.input[["out"]][[variable]])));
        if ( is.time.series ) {

            N <- length(list.input[["dates" ]][[i]]);
            posterior.means <- colMeans( list.input[["out"]][[variable]][,1:N,i] );
            DF.temp <- data.frame(
                variable         = rep(x = variable, times = N),
                jurisdiction     = rep(x = list.input[["jurisdictions"]][[i]], times = N),
                date             = list.input[["dates"]][[i]],
                posterior.mean   = posterior.means,
                stringsAsFactors = FALSE
                );
    
        } else {

            DF.temp <- data.frame(
                variable         = variable,
                jurisdiction     = list.input[["jurisdictions"]][[i]],
                posterior.mean   = mean( list.input[["out"]][[variable]][,i] ),
                stringsAsFactors = FALSE
                );
    
            }

        DF.output <- rbind(DF.output,DF.temp);

        } 

    return( DF.output );    
    
    }

