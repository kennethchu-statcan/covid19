
wrapper.stan.length.of.stay <- function(
    StanModel       = "length-of-stay",
    FILE.stan.model = NULL,
    DF.input        = NULL,
    RData.output    = paste0('stan-model-',StanModel,'.RData'),
    DEBUG           = FALSE
    ) {

    thisFunctionName <- "wrapper.stan.length.of.stay";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(RData.output) ) {

        cat(paste0("\n# ",RData.output," already exists; loading this file ...\n"));
        list.output <- readRDS(file = RData.output);
        cat(paste0("\n# Loading complete: ",RData.output,"\n"));

    } else {

        list.output <- wrapper.stan.length.of.stay_inner(
            StanModel       = StanModel,
            FILE.stan.model = FILE.stan.model,
            DF.input        = DF.input,
            RData.output    = RData.output,
            DEBUG           = DEBUG
            );

        if (!is.null(RData.output)) {
            saveRDS(object = list.output, file = RData.output);
            }

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(list.output[['extracted.samples']])\n");
    print( str(list.output[['extracted.samples']])   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    # wrapper.stan_visualize.results(
    #     list.input = list.output
    #     );
    #
    # plot.3.panel(
    #     list.input = list.output
    #     );
    #
    # # plot.stepsize.vs.chgpt(
    # #     list.input = list.output
    # #     );
    #
    # plot.forecast(
    #     list.input      = list.output,
    #     forecast.window = forecast.window
    #     );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( list.output );

    }

##################################################
wrapper.stan.length.of.stay_visualize.results <- function(
    list.input = NULL
    ) {

    require(ggplot2);
    require(bayesplot);

    # to visualize results

    StanModel     <- list.input[["StanModel"]];
    jurisdictions <- list.input[["jurisdictions"]];

    step1 <- as.matrix(list.input[["out"]][["step1"]]);
    colnames(step1) <- jurisdictions;
    g <- bayesplot::mcmc_intervals(step1, prob = .9);
    ggsave(
        filename = paste0("output-",StanModel,"-covars-step1.png"),
        plot     = g,
        device   = "png",
        width    = 4,
        height   = 6
        );

    #g <- bayesplot::mcmc_intervals(alpha, prob = .9,transformations = function(x) exp(-x));
    #ggsave(
    #    filename = paste0("output-",StanModel,"-covars-alpha.png"),
    #    plot     = g,
    #    width    = 4,
    #    height   = 6
    #    );

    R0 <- as.matrix(list.input[["out"]][["R0"]]);
    colnames(R0) <- jurisdictions;
    g <- bayesplot::mcmc_intervals(R0,prob = .9);
    ggsave(
        filename = paste0("output-",StanModel,"-covars-R0.png"),
        plot     = g,
        width    = 4,
        height   = 6
        );

    dimensions   <- dim(list.input[["out"]][["Rt"]]);
    Rt           <- as.matrix(list.input[["out"]][["Rt"]][,dimensions[2],]);
    colnames(Rt) <- jurisdictions;

    g <- bayesplot::mcmc_intervals(Rt,prob = .9);
    ggsave(
        filename = paste0("output-",StanModel,"-covars-final-rt.png"),
        plot     = g,
        width    = 4,
        height   = 6
        );

    return( NULL );

    }

wrapper.stan.length.of.stay_inner <- function(
    StanModel       = NULL,
    FILE.stan.model = NULL,
    DF.input        = NULL,
    RData.output    = NULL,
    DEBUG           = FALSE
    ) {

    require(rstan);

    jurisdictions   <- unique(DF.input[,'jurisdiction']);
    n.jurisdictions <- length(jurisdictions);

    if( DEBUG == FALSE ) {
        N2 = 300 # Increase this for a further forecast
    }  else  {
        ### For faster runs:
        # jurisdictions <- c("Austria","Belgium") #,Spain")
        N2 = 300
        }

    stan_data <- list(
        n_days          = nrow(DF.input) / n.jurisdictions,
        n_jurisdictions = n.jurisdictions,
        admissions      = NULL,
        discharges      = NULL,
        LENGTHSCALE     = 7
        );

    dates <- list();
    for( jurisdiction in jurisdictions ) {

        DF.jurisdiction   <- DF.input[DF.input$jurisdiction == jurisdiction,];
        DF.jurisdiction$t <- lubridate::decimal_date(DF.jurisdiction$date);
        DF.jurisdiction   <- DF.jurisdiction[order(DF.jurisdiction$t),];

        dates[[jurisdiction]] <- DF.jurisdiction$date;

        # append data
        stan_data$admissions <- cbind(stan_data$admissions,as.vector(as.numeric(DF.jurisdiction$admissions)));
        stan_data$discharges <- cbind(stan_data$discharges,as.vector(as.numeric(DF.jurisdiction$discharges)));

        } # for( jurisdiction in jurisdictions )

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    options(mc.cores = parallel::detectCores())
    rstan_options(auto_write = TRUE)
    my.stan.model <- rstan::stan_model(FILE.stan.model);

    ##############################################
    ##############################################
    cat("\nstr(stan_data)\n");
    print( str(stan_data)   );
    saveRDS(object = stan_data, file = "data-stan-length-of-stay.RData");
    # return( NULL );
    ##############################################
    ##############################################
    list.init <- lapply(
        X   = 1:getOption("mc.cores"),
        FUN = function(x) {
            list(
                alpha0 = runif(n.jurisdictions, min = 0, max = 1),
                sigma0 = runif(n.jurisdictions, min = 0, max = 1)
                )
            }
        );

    if( DEBUG ) {

        results.rstan.sampling <- rstan::sampling(
            object = my.stan.model,
            data   = stan_data,
            # init = list.init,
            iter   = 40,
            warmup = 20,
            chains =  2
            );

    } else {

        # fit = rstan::sampling(
        #     object  = my.stan.model,
        #     data    = stan_data,
        #     iter    = 4000,
        #     warmup  = 2000,
        #     chains  = 8,
        #     thin    = 4,
        #     init    = list.init,
        #     control = list(adapt_delta = 0.90, max_treedepth = 10)
        #     );

        #fit <- rstan::sampling(
        #    object  = my.stan.model,
        #    data    = stan_data,
        #    iter    = 200,
        #    warmup  = 100,
        #    chains  = 4,
        #    thin    = 4,
        #    init    = list.init,
        #    control = list(adapt_delta = 0.90, max_treedepth = 10)
        #    );

        results.rstan.sampling <- rstan::sampling(
            object  = my.stan.model,
            data    = stan_data,
            init    = list.init,
            iter    = 1000,
            warmup  =  500,
            chains  =    4,
            thin    =    4,
            control = list(adapt_delta = 0.90, max_treedepth = 10)
            );

        }

    extracted.samples <- rstan::extract(results.rstan.sampling);

    list.output <- list(
        StanModel              = StanModel,
        jurisdictions          = jurisdictions,
        results.rstan.sampling = results.rstan.sampling,
        extracted.samples      = extracted.samples
        );

    return( list.output );

    }

##################################################
