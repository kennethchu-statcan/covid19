
wrapper.stan.length.of.stay <- function(
    StanModel             = "length-of-stay",
    FILE.stan.model       = NULL,
    DF.input              = NULL,
    RData.output          = paste0('stan-model-',StanModel,'.RData'),
    n.chains              =    4,
    n.iterations          = 2000,
    n.warmup              = 1000,
    period.thinning       =    4,
    sampler.control       = list(adapt_delta = 0.90, max_treedepth = 10),
    threshold.stuck.chain = 0.05
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
            StanModel             = StanModel,
            FILE.stan.model       = FILE.stan.model,
            DF.input              = DF.input,
            RData.output          = RData.output,
            n.chains              = n.chains,
            n.iterations          = n.iterations,
            n.warmup              = n.warmup,
            period.thinning       = period.thinning,
            sampler.control       = sampler.control,
            threshold.stuck.chain = threshold.stuck.chain
            );

        if (!is.null(RData.output)) {
            saveRDS(object = list.output, file = RData.output);
            }

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output <- wrapper.stan.length.of.stay_add.is.not.stuck(
        list.input            = list.output,
        DF.input              = DF.input,
        threshold.stuck.chain = threshold.stuck.chain,
        n.chains              = n.chains,
        n.iterations          = n.iterations,
        n.warmup              = n.warmup,
        period.thinning       = period.thinning
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( list.output );

    }

##################################################
wrapper.stan.length.of.stay_add.is.not.stuck <- function(
    list.input            = NULL,
    DF.input              = NULL,
    threshold.stuck.chain = NULL,
    n.chains              = NULL,
    n.iterations          = NULL,
    n.warmup              = NULL,
    period.thinning       = NULL
    ) {
    list.output <- list.input;
    list.output[['threshold.stuck.chain']] <- threshold.stuck.chain;
    is.not.stuck <- list();
    jurisdictions <- list.input[['jurisdictions']];
    for( temp.index in 1:length(jurisdictions) ) {
        jurisdiction <- jurisdictions[temp.index];
        is.not.stuck[[jurisdiction]] <- wrapper.stan.length.of.stay_is.not.stuck(
            threshold.stuck.chain = threshold.stuck.chain,
            input.vector          = list.input[['posterior.samples']][['alpha']][,temp.index],
            n.chains              = n.chains,
            n.iterations          = n.iterations,
            n.warmup              = n.warmup,
            period.thinning       = period.thinning
            );
        }
    list.output[['is.not.stuck']] <- is.not.stuck;
    return( list.output );
    }

wrapper.stan.length.of.stay_inner <- function(
    StanModel             = NULL,
    FILE.stan.model       = NULL,
    DF.input              = NULL,
    RData.output          = NULL,
    n.chains              = NULL,
    n.iterations          = NULL,
    n.warmup              = NULL,
    period.thinning       = NULL,
    sampler.control       = NULL,
    threshold.stuck.chain = NULL
    ) {

    require(rstan);

    jurisdictions   <- unique(DF.input[,'jurisdiction']);
    n.jurisdictions <- length(jurisdictions);

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
    saveRDS(object = stan_data, file = paste0("data-stan-",StanModel,".RData"));
    ##############################################
    ##############################################
    list.init <- lapply(
        X   = 1:n.chains,
        FUN = function(x) {
            list(
                uniform_mu = runif(n.jurisdictions, min = 0, max = 1),
                uniform_cv = runif(n.jurisdictions, min = 0, max = 1)
                )
            }
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    results.rstan.sampling <- rstan::sampling(
        object  = my.stan.model,
        data    = stan_data,
        init    = list.init,
        iter    = n.iterations,
        warmup  = n.warmup,
        chains  = n.chains,
        thin    = period.thinning,
        control = sampler.control
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    posterior.samples <- rstan::extract(results.rstan.sampling);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output <- list(
        StanModel              = StanModel,
        jurisdictions          = jurisdictions,
        observed.data          = observed.data,
        results.rstan.sampling = results.rstan.sampling,
        posterior.samples      = posterior.samples,
        sampling.parameters = list(
            n.chains        = n.chains,
            n.iterations    = n.iterations,
            n.warmup        = n.warmup,
            period.thinning = period.thinning,
            control         = sampler.control
            )
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    return( list.output );

    }

wrapper.stan.length.of.stay_is.not.stuck <- function(
    threshold.stuck.chain = NULL,
    input.vector          = NULL,
    n.chains              = NULL,
    n.iterations          = NULL,
    n.warmup              = NULL,
    period.thinning       = NULL
    ) {

    print("A-0");

    require(dplyr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    thisFunctionName <- "wrapper.stan.length.of.stay_is.not.stuck";

    cat(paste0("\n# ",thisFunctionName,"(): threshold.stuck.chain = ",threshold.stuck.chain,"\n"));
    cat(paste0("\n# ",thisFunctionName,"(): n.chains = ",n.chains ,"\n"));
    cat(paste0("\n# ",thisFunctionName,"(): n.iterations = ",n.iterations,"\n"));
    cat(paste0("\n# ",thisFunctionName,"(): n.warmup = ",n.warmup ,"\n"));
    cat(paste0("\n# ",thisFunctionName,"(): period.thinning = ",period.thinning ,"\n"));

    cat(paste0("\n# ",thisFunctionName,"(): str(input.vector):\n"));
    print( str(input.vector) );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    print("A-1");

    # We are NOT taking the value of n.chains (number of chains) at face value.
    # Instead,  the 'effective' number of chains is computed to guard against
    # the scenario that any given chain may encounter errors and fail to
    # generate any posterior samples.
    chain.size         <- (n.iterations - n.warmup) / period.thinning;
    n.chains.effective <- length(input.vector) / chain.size;

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    print("A-2");

    DF.samples <- data.frame(
        index    = seq(1,length(input.vector)),
        chain.ID = rep(x = seq(1,n.chains.effective), each = chain.size),
        value    = input.vector
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    print("A-3");

    chain.IDs <- unique(DF.samples[,'chain.ID']);

    print("A-4");

    DF.chains <- data.frame(
        chain.ID  = chain.IDs,
        chain.var = rep(x = 0, times = length(chain.IDs))
        );

    print("A-5");

    for ( row.index in 1:nrow(DF.chains) ) {
        temp.chain.ID   <- DF.chains[row.index,'chain.ID'];
        is.selected.row <- (DF.samples[,'chain.ID'] == temp.chain.ID);
        temp.vector     <- DF.samples[is.selected.row,'value'];
        DF.chains[row.index,'chain.var'] <- stats::var(x = temp.vector, na.rm = TRUE);
        }

    print("A-6");

    DF.chains[,'normalized.chain.var'] <- DF.chains[,'chain.var'] / sum(DF.chains[,'chain.var']);

    print("A-7");

    DF.chains[,'normalized.chain.var'] <- nrow(DF.chains) * DF.chains[,'normalized.chain.var'];

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    print("A-8");

    DF.chains[,'is.not.stuck'] <- !(DF.chains[,'normalized.chain.var'] < threshold.stuck.chain);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    print("A-9");

    DF.samples <- dplyr::left_join(
        x  = DF.samples,
        y  = DF.chains,
        by = 'chain.ID'
        );

    print("A-10");

    DF.samples <- as.data.frame(DF.samples);

    print("A-11");

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    # return( list(DF.samples = DF.samples, DF.chains = DF.chains) );
    return( DF.samples[,'is.not.stuck'] );

    }
