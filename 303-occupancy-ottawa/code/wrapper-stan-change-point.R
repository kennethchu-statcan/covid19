
wrapper.stan.change.point <- function(
    StanModel          = "change-point",
    FILE.stan.model    = NULL,
    DF.input           = NULL,
    DF.IHR             = NULL,
    DF.serial.interval = NULL,
    buffer.period      =   14,
    forecast.window    =    7,
    n.chains           =    4,
    n.iterations       = 1000,
    n.warmup           =  500,
    period.thinning    =    4,
    sampler.control    = list(adapt_delta = 0.90, max_treedepth = 10),
    RData.output       = paste0('stan-model-',StanModel,'.RData')
    ) {

    thisFunctionName <- "wrapper.stan.change.point";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(RData.output) ) {

        cat(paste0("\n# ",RData.output," already exists; loading this file ...\n"));
        list.output <- readRDS(file = RData.output);
        cat(paste0("\n# Loading complete: ",RData.output,"\n"));

    } else {

        list.output <- wrapper.stan_inner(
            StanModel          = StanModel,
            FILE.stan.model    = FILE.stan.model,
            DF.input           = DF.input,
            DF.IHR             = DF.IHR,
            DF.serial.interval = DF.serial.interval,
            buffer.period      = buffer.period,
            RData.output       = RData.output,
            n.chains           = n.chains,
            n.iterations       = n.iterations,
            n.warmup           = n.warmup,
            period.thinning    = period.thinning,
            sampler.control    = sampler.control
            );

        if (!is.null(RData.output)) {
            saveRDS(object = list.output, file = RData.output);
            }

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output <- wrapper.stan.change.point_patch(
        list.input = list.output,
        DF.input   = DF.input
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    # return( DF.output );
    return( list.output );

    }

##################################################
wrapper.stan.change.point_patch <- function(
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

    return( list.output );

    }

wrapper.stan_inner <- function(
    StanModel          = NULL,
    FILE.stan.model    = NULL,
    DF.input           = NULL,
    DF.IHR             = NULL,
    DF.serial.interval = NULL,
    buffer.period      = NULL,
    RData.output       = NULL,
    n.chains           = NULL,
    n.iterations       = NULL,
    n.warmup           = NULL,
    period.thinning    = NULL,
    sampler.control    = NULL
    ) {

    require(EnvStats);
    require(rstan);

    jurisdictions  <- unique(DF.input[,'jurisdiction']);
    forecast       <- 0;
    N2             <- 720; # 360;
    dates          <- list();
    reported_cases <- list();

    stan_data <- list(
        log_max_step_large = log(4.0),
        log_max_step_small = log(1.5),
        log_max_step_four  = log(1.1),
        M                  = length(jurisdictions),
        N                  = NULL,
        x1                 = poly(1:N2,2)[,1],
        x2                 = poly(1:N2,2)[,2],
        y                  = NULL,
        admissions         = NULL,
        f                  = NULL,
        N0                 = 6, # N0 = 6 to make it consistent with Rayleigh
        cases              = NULL,
        LENGTHSCALE        = 7,
        SI                 = DF.serial.interval[,"fit"][1:N2],
        EpidemicStart      = NULL,
        minChgPt1          = NULL,
        maxChgPt1          = NULL,
        minChgPt2          = NULL,
        maxChgPt2          = NULL,
        minChgPt3          = NULL,
        maxChgPt3          = NULL,
        minChgPt4          = NULL,
        maxChgPt4          = NULL
        );

    admissions_by_jurisdiction <- list();
    observed.data              <- list();

    for( jurisdiction in jurisdictions ) {

        IHR <- DF.IHR$infection_hospitalization_rate[DF.IHR$jurisdiction == jurisdiction];

        d1   <- DF.input[DF.input$jurisdiction == jurisdiction,];
        d1$t <- decimal_date(d1$date);
        d1   <- d1[order(d1$t),];

        observed.data[[jurisdiction]] <- d1;

        index  <- which(d1$cases>0)[1];
        index1 <- which(cumsum(d1$admissions)>=10)[1]; # also 5
        index2 <- index1 - 30;

        print(sprintf("First non-zero cases is on day %d, and 30 days before 5 days is day %d",index,index2));
        d1 <- d1[index2:nrow(d1),];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        decimal.date.EpidemicStart <- index1+1-index2;
        stan_data$EpidemicStart    <- c(stan_data$EpidemicStart,decimal.date.EpidemicStart);

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        decimal.date.minChgPt1 <- max(decimal.date.EpidemicStart,which(d1$date == as.Date("2020-03-01"))[1],na.rm=TRUE);
        decimal.date.maxChgPt1 <- max(decimal.date.EpidemicStart,which(d1$date == as.Date("2020-03-28"))[1],na.rm=TRUE);

        decimal.date.minChgPt2 <- max(decimal.date.EpidemicStart,which(d1$date == as.Date("2020-07-05"))[1],na.rm=TRUE);
        decimal.date.maxChgPt2 <- max(decimal.date.EpidemicStart,which(d1$date == as.Date("2020-08-01"))[1],na.rm=TRUE);

        decimal.date.minChgPt3 <- max(decimal.date.EpidemicStart,which(d1$date == as.Date("2020-09-06"))[1],na.rm=TRUE);
        decimal.date.maxChgPt3 <- max(decimal.date.EpidemicStart,which(d1$date == as.Date("2020-10-03"))[1],na.rm=TRUE);

        decimal.date.minChgPt4 <- max(decimal.date.EpidemicStart,which(d1$date == as.Date("2020-11-01"))[1],na.rm=TRUE);
        date.maxChgPt4         <- d1[nrow(d1),'date'] - buffer.period;
        decimal.date.maxChgPt4 <- max(decimal.date.EpidemicStart,which(d1$date == date.maxChgPt4       )[1],na.rm=TRUE);

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        cat("\n### ~~~~~~ #####\n")
        cat(paste0("\njurisdiction: ",jurisdiction,"\n"));
        cat(paste0("\ndecimal.date.minChgPt1: ",decimal.date.minChgPt1,"\n"));
        cat(paste0("\ndecimal.date.maxChgPt1: ",decimal.date.maxChgPt1,"\n"));
        cat(paste0("\ndecimal.date.minChgPt2: ",decimal.date.minChgPt2,"\n"));
        cat(paste0("\ndecimal.date.maxChgPt2: ",decimal.date.maxChgPt2,"\n"));
        cat(paste0("\ndecimal.date.minChgPt3: ",decimal.date.minChgPt3,"\n"));
        cat(paste0("\ndecimal.date.maxChgPt3: ",decimal.date.maxChgPt3,"\n"));
        cat(paste0("\ndecimal.date.minChgPt4: ",decimal.date.minChgPt4,"\n"));
        cat(paste0("\ndecimal.date.maxChgPt4: ",decimal.date.maxChgPt4,"\n"));
        cat("\n### ~~~~~~ #####\n")

        stan_data$minChgPt1 <- c(stan_data$minChgPt1,decimal.date.minChgPt1);
        stan_data$maxChgPt1 <- c(stan_data$maxChgPt1,decimal.date.maxChgPt1);
        stan_data$minChgPt2 <- c(stan_data$minChgPt2,decimal.date.minChgPt2);
        stan_data$maxChgPt2 <- c(stan_data$maxChgPt2,decimal.date.maxChgPt2);
        stan_data$minChgPt3 <- c(stan_data$minChgPt3,decimal.date.minChgPt3);
        stan_data$maxChgPt3 <- c(stan_data$maxChgPt3,decimal.date.maxChgPt3);
        stan_data$minChgPt4 <- c(stan_data$minChgPt4,decimal.date.minChgPt4);
        stan_data$maxChgPt4 <- c(stan_data$maxChgPt4,decimal.date.maxChgPt4);

        dates[[jurisdiction]] = d1$date;
        # hazard estimation
        N <- length(d1$cases);
        print(sprintf("%s has %d days of data",jurisdiction,N));
        forecast <- N2 - N;
        if( forecast < 0 ) {
            print(sprintf("%s: %d", jurisdiction, N))
            print("ERROR!!!! increasing N2")
            N2 <- N;
            forecast <- N2 - N;
            }

        h <- rep(0,forecast+N) # discrete hazard rate from time t = 1, ..., 100
        # if( DEBUG ) { # OLD -- but faster for testing this part of the code
        if( FALSE ) { # obsolete code segment

            mean <- 18.8;
            cv   <- 0.45;

            for( i in 1:length(h) ) {
                h[i] <- (
                    IHR * pgammaAlt(i,  mean = mean,cv=cv)
                    -
                    IHR * pgammaAlt(i-1,mean = mean,cv=cv)
                    ) / (
                    1 - IHR * pgammaAlt(i-1,mean = mean,cv=cv)
                    );
                }

        } else { # NEW

            mean1 <-  5.1; cv1 <- 0.86; # infection to onset
            mean2 <- 18.8; cv2 <- 0.45; # onset to death

            ## assume that IHR is probability of dying given infection
            x1 <- rgammaAlt(5e6,mean1,cv1) # infection-to-onset ----> do all people who are infected get to onset?
            x2 <- rgammaAlt(5e6,mean2,cv2) # onset-to-death
            x2 <- x2 / 2                   # onset-to-admission = (onset-to-death) / 2

            f  <- ecdf(x1+x2);
            convolution <- function(u) { IHR * f(u) }

            h[1] = (convolution(1.5) - convolution(0));
            for( i in 2:length(h) ) {
                h[i] = (convolution(i+.5) - convolution(i-.5)) / (1-convolution(i-.5));
                }

            }

        s    <- rep(0,N2);
        s[1] <- 1;
        for( i in 2:N2 ) {
            s[i] <- s[i-1]*(1-h[i-1]);
            }
        f <- s * h;

        y <- c(as.vector(as.numeric(d1$cases)),rep(-1,forecast));
        reported_cases[[jurisdiction]] <- as.vector(as.numeric(d1$cases));
        admissions <- c(as.vector(as.numeric(d1$admissions)),rep(-1,forecast));
        cases      <- c(as.vector(as.numeric(d1$cases)), rep(-1,forecast));
        admissions_by_jurisdiction[[jurisdiction]] <- as.vector(as.numeric(d1$admissions))

        # append data
        stan_data$N <- c(stan_data$N,N   );
        stan_data$y <- c(stan_data$y,y[1]); # just the index case!
        # stan_data$x = cbind(stan_data$x,x)
        stan_data$f          <- cbind(stan_data$f,f);
        stan_data$admissions <- cbind(stan_data$admissions,admissions);
        stan_data$cases      <- cbind(stan_data$cases, cases );

        stan_data$N2 <- N2;
        stan_data$x  <- 1:N2;
        if( length(stan_data$N) == 1 ) {
            stan_data$N <- as.array(stan_data$N);
            }

        } # for( jurisdiction in jurisdictions )

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    stan_data$y <- t(stan_data$y);
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
                Uchg1 = runif(length(jurisdictions), min = 0, max = 1),
                Uchg2 = runif(length(jurisdictions), min = 0, max = 1),
                Uchg3 = runif(length(jurisdictions), min = 0, max = 1),
                Uchg4 = runif(length(jurisdictions), min = 0, max = 1),
               #Uchg5 = runif(length(jurisdictions), min = 0, max = 1),
                step1 = runif(length(jurisdictions), min = -stan_data[["log_max_step_large"]], max = 0                                ),
                step2 = runif(length(jurisdictions), min =  0,                                 max = stan_data[["log_max_step_small"]]),
                step3 = runif(length(jurisdictions), min = -stan_data[["log_max_step_small"]], max = 0                                ),
                step4 = runif(length(jurisdictions), min = -stan_data[["log_max_step_four"]],  max = stan_data[["log_max_step_four" ]])
              #,step5 = runif(length(jurisdictions), min = -stan_data[["log_max_step_small"]], max = stan_data[["log_max_step_small"]])
                )
            }
        )

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
    posterior.samples       <- rstan::extract(results.rstan.sampling);
    prediction              <- posterior.samples$prediction;
    estimated.admissions    <- posterior.samples$E_admissions;
    estimated.admissions.cf <- posterior.samples$E_admissions0;

    list.output <- list(
        StanModel                  = StanModel,
        jurisdictions              = jurisdictions,
        observed.data              = observed.data,
        results.rstan.sampling     = results.rstan.sampling,
        prediction                 = prediction,
        dates                      = dates,
        reported_cases             = reported_cases,
        admissions_by_jurisdiction = admissions_by_jurisdiction,
        estimated_admissions       = estimated.admissions,
        estimated_admissions_cf    = estimated.admissions.cf,
        posterior.samples          = posterior.samples,
        sampling.parameters = list(
            n.chains        = n.chains,
            n.iterations    = n.iterations,
            n.warmup        = n.warmup,
            period.thinning = period.thinning,
            control         = sampler.control
            )
        );

    return( list.output );

    }

##################################################
