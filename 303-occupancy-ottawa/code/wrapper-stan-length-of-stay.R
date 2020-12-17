
wrapper.stan.length.of.stay <- function(
    StanModel       = "length-of-stay",
    FILE.stan.model = NULL,
    DF.input        = NULL,
    RData.output    = paste0('stan-model-',StanModel,'.RData'),
    n.chains        = 4,
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
            n.chains        = n.chains,
            DEBUG           = DEBUG
            );

        if (!is.null(RData.output)) {
            saveRDS(object = list.output, file = RData.output);
            }

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output <- wrapper.stan.length.of.stay_patch(
        list.input = list.output,
        DF.input   = DF.input
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( list.output );

    }

##################################################
wrapper.stan.length.of.stay_patch <- function(
    list.input = NULL,
    DF.input   = NULL
    ) {

    list.output <- list.input;

    if ( !('observed.data' %in% names(list.input)) ) {
        jurisdictions <- unique(DF.input[,'jurisdiction']);
        observed.data <- list();
        for( jurisdiction in jurisdictions ) {
            DF.jurisdiction   <- DF.input[DF.input$jurisdiction == jurisdiction,];
            DF.jurisdiction$t <- lubridate::decimal_date(DF.jurisdiction$date);
            DF.jurisdiction   <- DF.jurisdiction[order(DF.jurisdiction$t),];
            observed.data[[jurisdiction]] <- DF.jurisdiction;
            } # for( jurisdiction in jurisdictions )
        list.output[['observed.data']] <- observed.data;
        }

    #if( !('is.not.stuck' %in% names(list.input)) ) {
    if ( TRUE ) {
        jurisdictions   <- unique(DF.input[,'jurisdiction']);
        n.jurisdictions <- length(jurisdictions);
        is.not.stuck    <- list();
        for( temp.index in 1:n.jurisdictions ) {
            temp.stddev  <- get.moving.stddev(
                input.vector = list.input[['extracted.samples']][['alpha']][,temp.index],
                half.window  = 10
                );
            jurisdiction <- jurisdictions[temp.index];
            is.not.stuck[[jurisdiction]] <- ((0.05 < temp.stddev) & (temp.stddev < 0.5));
            } # for( temp.index in 1:n.jurisdictions )
        list.output[['is.not.stuck']] <- is.not.stuck;
        }

    return( list.output );

    }

wrapper.stan.length.of.stay_inner <- function(
    StanModel       = NULL,
    FILE.stan.model = NULL,
    DF.input        = NULL,
    RData.output    = NULL,
    n.chains        = NULL,
    DEBUG           = FALSE
    ) {

    require(rstan);

    jurisdictions   <- unique(DF.input[,'jurisdiction']);
    n.jurisdictions <- length(jurisdictions);

    if( DEBUG == FALSE ) {
        N2 = 360 # Increase this for a further forecast
    }  else  {
        ### For faster runs:
        # jurisdictions <- c("Austria","Belgium") #,Spain")
        N2 = 360
        }

    stan_data <- list(
        n_days          = nrow(DF.input) / n.jurisdictions,
        n_jurisdictions = n.jurisdictions,
        admissions      = NULL,
        discharges      = NULL,
        LENGTHSCALE     = 7
        );

    observed.data <- list();
    for( jurisdiction in jurisdictions ) {

        DF.jurisdiction   <- DF.input[DF.input$jurisdiction == jurisdiction,];
        DF.jurisdiction$t <- lubridate::decimal_date(DF.jurisdiction$date);
        DF.jurisdiction   <- DF.jurisdiction[order(DF.jurisdiction$t),];

        observed.data[[jurisdiction]] <- DF.jurisdiction;

        # append data
        stan_data$admissions <- cbind(stan_data$admissions,as.vector(as.numeric(DF.jurisdiction$admissions)));
        stan_data$discharges <- cbind(stan_data$discharges,as.vector(as.numeric(DF.jurisdiction$discharges)));

        } # for( jurisdiction in jurisdictions )

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    # options(mc.cores = parallel::detectCores())
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
        X   = 1:n.chains, # 1:getOption("mc.cores"),
        FUN = function(x) {
            list(
                uniform_mu = runif(n.jurisdictions, min = 0, max = 1),
                uniform_cv = runif(n.jurisdictions, min = 0, max = 1)
                )
            }
        );

    if( DEBUG ) {

        if ( grepl(x = sessionInfo()[['platform']], pattern = 'apple', ignore.case = TRUE) ) {
            my.iter     <- 40;
            my.warmup   <- 20;
            my.n.chains <- n.chains;
        } else {
            my.iter     <- 200;
            my.warmup   <- 100;
            my.n.chains <- n.chains;
           }

        results.rstan.sampling <- rstan::sampling(
            object = my.stan.model,
            data   = stan_data,
            init   = list.init,
            iter   = my.iter,     # 20,
            warmup = my.warmup,   # 10,
            chains = my.n.chains  #  2
            );

    } else {

        # results.rstan.sampling = rstan::sampling(
        #     object  = my.stan.model,
        #     data    = stan_data,
        #     iter    = 4000,
        #     warmup  = 2000,
        #     chains  = 8,
        #     thin    = 4,
        #     init    = list.init,
        #     control = list(adapt_delta = 0.90, max_treedepth = 10)
        #     );

        # results.rstan.sampling <- rstan::sampling(
        #    object  = my.stan.model,
        #    data    = stan_data,
        #    iter    = 200,
        #    warmup  = 100,
        #    chains  = 4,
        #    thin    = 4,
        #    init    = list.init,
        #    control = list(adapt_delta = 0.90, max_treedepth = 10)
        #    );

        # results.rstan.sampling <- rstan::sampling(
        #     object  = my.stan.model,
        #     data    = stan_data,
        #     init    = list.init,
        #     iter    = 1000,
        #     warmup  =  500,
        #     chains  =    8,
        #     thin    =    4,
        #     control = list(adapt_delta = 0.90, max_treedepth = 10)
        #     );

        results.rstan.sampling <- rstan::sampling(
            object  = my.stan.model,
            data    = stan_data,
            init    = list.init,
            iter    = 2000,
            warmup  = 1000,
            chains  = n.chains,
            thin    = 4,
            control = list(adapt_delta = 0.90, max_treedepth = 10)
            );

        }

    extracted.samples <- rstan::extract(results.rstan.sampling);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    is.not.stuck <- list();
    for( temp.index in 1:n.jurisdictions ) {
        temp.stddev  <- get.moving.stddev(
            input.vector = extracted.samples[['alpha']][,temp.index],
            half.window  = 10
            );
        jurisdiction <- jurisdictions[temp.index];
        is.not.stuck[[jurisdiction]] <- ((0.05 < temp.stddev) & (temp.stddev < 0.5));
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output <- list(
        StanModel              = StanModel,
        jurisdictions          = jurisdictions,
        observed.data          = observed.data,
        results.rstan.sampling = results.rstan.sampling,
        extracted.samples      = extracted.samples,
        is.not.stuck           = is.not.stuck
        );

    return( list.output );

    }

##################################################
