
wrapper.stan.change.point <- function(
    StanModel          = "change-point",
    FILE.stan.model    = NULL,
    DF.input           = NULL,
    DF.IHR             = NULL,
    DF.serial.interval = NULL,
    forecast.window    = 7,
    n.chains           = 4,
    RData.output       = paste0('stan-model-',StanModel,'.RData'),
    DEBUG              = FALSE
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
            RData.output       = RData.output,
            n.chains           = n.chains,
            DEBUG              = DEBUG
            );

        if (!is.null(RData.output)) {
            saveRDS(object = list.output, file = RData.output);
            }

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(list.output[['out']])\n");
    print( str(list.output[['out']])   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    wrapper.stan_visualize.results(
        list.input = list.output
        );

    plot.3.panel(
        list.input = list.output
        );

    plot.stepsize.vs.chgpt(
        list.input = list.output
        );

    plot.forecast(
        list.input      = list.output,
        forecast.window = forecast.window
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    # return( DF.output );
    return( list.output );

    }

##################################################
wrapper.stan_visualize.results <- function(
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
        filename = paste0("plot-",StanModel,"-covars-step1.png"),
        plot     = g,
        device   = "png",
        width    = 4,
        height   = 6
        );

    #g <- bayesplot::mcmc_intervals(alpha, prob = .9,transformations = function(x) exp(-x));
    #ggsave(
    #    filename = paste0("plot-",StanModel,"-covars-alpha.png"),
    #    plot     = g,
    #    width    = 4,
    #    height   = 6
    #    );

    R0 <- as.matrix(list.input[["out"]][["R0"]]);
    colnames(R0) <- jurisdictions;
    g <- bayesplot::mcmc_intervals(R0,prob = .9);
    ggsave(
        filename = paste0("plot-",StanModel,"-covars-R0.png"),
        plot     = g,
        width    = 4,
        height   = 6
        );

    dimensions   <- dim(list.input[["out"]][["Rt"]]);
    Rt           <- as.matrix(list.input[["out"]][["Rt"]][,dimensions[2],]);
    colnames(Rt) <- jurisdictions;

    g <- bayesplot::mcmc_intervals(Rt,prob = .9);
    ggsave(
        filename = paste0("plot-",StanModel,"-covars-final-rt.png"),
        plot     = g,
        width    = 4,
        height   = 6
        );

    return( NULL );

    }

wrapper.stan_inner <- function(
    StanModel          = NULL,
    FILE.stan.model    = NULL,
    DF.input           = NULL,
    DF.IHR             = NULL,
    DF.serial.interval = NULL,
    RData.output       = NULL,
    n.chains           = NULL,
    DEBUG              = FALSE
    ) {

    require(EnvStats);
    require(rstan);

    jurisdictions <- unique(DF.input[,'jurisdiction']);
    forecast      <- 0;

    if( DEBUG == FALSE ) {
        N2 = 300 # Increase this for a further forecast
    }  else  {
        ### For faster runs:
        # jurisdictions <- c("Austria","Belgium") #,Spain")
        N2 = 300
        }

    dates          <- list();
    reported_cases <- list();

    stan_data <- list(
        log_max_step_up   = log(1.5),
        log_max_step_down = log(4.0),
        M                 = length(jurisdictions),
        N                 = NULL,
        x1                = poly(1:N2,2)[,1],
        x2                = poly(1:N2,2)[,2],
        y                 = NULL,
        admissions        = NULL,
        f                 = NULL,
        N0                = 6, # N0 = 6 to make it consistent with Rayleigh
        cases             = NULL,
        LENGTHSCALE       = 7,
        SI                = DF.serial.interval[,"fit"][1:N2],
        EpidemicStart     = NULL,
        minChgPt1         = NULL,
        maxChgPt1         = NULL,
        minChgPt2         = NULL,
        maxChgPt2         = NULL,
        minChgPt3         = NULL,
        maxChgPt3         = NULL,
        minChgPt4         = NULL
        );

    admissions_by_jurisdiction = list();

    for( jurisdiction in jurisdictions ) {

        IHR <- DF.IHR$infection_hospitalization_rate[DF.IHR$jurisdiction == jurisdiction];

        d1   <- DF.input[DF.input$jurisdiction == jurisdiction,];
        d1$t <- decimal_date(d1$date);
        d1   <- d1[order(d1$t),];

        index  <- which(d1$cases>0)[1];
        index1 <- which(cumsum(d1$admissions)>=10)[1]; # also 5
        index2 <- index1 - 30;

        print(sprintf("First non-zero cases is on day %d, and 30 days before 5 days is day %d",index,index2));
        d1 <- d1[index2:nrow(d1),];

        decimal.date.EpidemicStart <- index1+1-index2;
        stan_data$EpidemicStart    <- c(stan_data$EpidemicStart,decimal.date.EpidemicStart);

        decimal.date.minChgPt1 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-03-01"))[1],na.rm=TRUE);
        decimal.date.maxChgPt1 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-04-04"))[1],na.rm=TRUE);

        decimal.date.minChgPt2 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-04-05"))[1],na.rm=TRUE);
        decimal.date.maxChgPt2 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-09-05"))[1],na.rm=TRUE);

        decimal.date.minChgPt3 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-09-06"))[1],na.rm=TRUE);
        decimal.date.maxChgPt3 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-10-31"))[1],na.rm=TRUE);

        decimal.date.minChgPt4 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-11-01"))[1],na.rm=TRUE);

        cat("\n### ~~~~~~ #####\n")
        cat(paste0("\njurisdiction: ",jurisdiction,"\n"));
        cat(paste0("\ndecimal.date.minChgPt1: ",decimal.date.minChgPt1,"\n"));
        cat(paste0("\ndecimal.date.maxChgPt1: ",decimal.date.maxChgPt1,"\n"));
        cat(paste0("\ndecimal.date.minChgPt2: ",decimal.date.minChgPt2,"\n"));
        cat(paste0("\ndecimal.date.maxChgPt2: ",decimal.date.maxChgPt2,"\n"));
        cat(paste0("\ndecimal.date.minChgPt3: ",decimal.date.minChgPt3,"\n"));
        cat(paste0("\ndecimal.date.maxChgPt3: ",decimal.date.maxChgPt3,"\n"));
        cat(paste0("\ndecimal.date.minChgPt4: ",decimal.date.minChgPt4,"\n"));
        cat("\n### ~~~~~~ #####\n")

        stan_data$minChgPt1 <- c(stan_data$minChgPt1,decimal.date.minChgPt1);
        stan_data$maxChgPt1 <- c(stan_data$maxChgPt1,decimal.date.maxChgPt1);
        stan_data$minChgPt2 <- c(stan_data$minChgPt2,decimal.date.minChgPt2);
        stan_data$maxChgPt2 <- c(stan_data$maxChgPt2,decimal.date.maxChgPt2);
        stan_data$minChgPt3 <- c(stan_data$minChgPt3,decimal.date.minChgPt3);
        stan_data$maxChgPt3 <- c(stan_data$maxChgPt3,decimal.date.maxChgPt3);
        stan_data$minChgPt4 <- c(stan_data$minChgPt4,decimal.date.minChgPt4);

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
        if( DEBUG ) { # OLD -- but faster for testing this part of the code

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
    m <- rstan::stan_model(FILE.stan.model);

    ##############################################
    ##############################################
    cat("\nstr(stan_data)\n");
    print( str(stan_data)   );
    saveRDS(object = stan_data, file = "data-stan-change-point.RData");
    # return( NULL );
    ##############################################
    ##############################################
    list.init <- lapply(
        X   = 1:n.chains, # 1:getOption("mc.cores"),
        FUN = function(x) {
            list(
                Uchg1 = runif(length(jurisdictions), min = 0, max = 1),
                Uchg2 = runif(length(jurisdictions), min = 0, max = 1),
                Uchg3 = runif(length(jurisdictions), min = 0, max = 1),
                Uchg4 = runif(length(jurisdictions), min = 0, max = 1),
               #Uchg5 = runif(length(jurisdictions), min = 0, max = 1),
                step1 = runif(length(jurisdictions), min = -stan_data[["log_max_step_down"]], max = stan_data[["log_max_step_up"]]),
                step2 = runif(length(jurisdictions), min = -stan_data[["log_max_step_down"]], max = stan_data[["log_max_step_up"]]),
                step3 = runif(length(jurisdictions), min = -stan_data[["log_max_step_down"]], max = stan_data[["log_max_step_up"]]),
                step4 = runif(length(jurisdictions), min = -stan_data[["log_max_step_down"]], max = stan_data[["log_max_step_up"]])
              #,step5 = runif(length(jurisdictions), min = -stan_data[["log_max_step_down"]], max = stan_data[["log_max_step_up"]])
                )
            }
        )

    if( DEBUG ) {

        fit <- rstan::sampling(
            object = m,
            data   = stan_data,
            iter   = 100, # 20,
            warmup =  50, # 10,
            chains =   4  #  2
            );

    } else {

        # fit = rstan::sampling(
        #     object  = m,
        #     data    = stan_data,
        #     iter    = 4000,
        #     warmup  = 2000,
        #     chains  = 8,
        #     thin    = 4,
        #     init    = list.init,
        #     control = list(adapt_delta = 0.90, max_treedepth = 10)
        #     );

        #fit <- rstan::sampling(
        #    object  = m,
        #    data    = stan_data,
        #    iter    = 200,
        #    warmup  = 100,
        #    chains  = 4,
        #    thin    = 4,
        #    init    = list.init,
        #    control = list(adapt_delta = 0.90, max_treedepth = 10)
        #    );

        fit = rstan::sampling(
            object  = m,
            data    = stan_data,
            iter    = 2000,
            warmup  = 1000,
            chains  = n.chains,
            thin    = 4,
            init    = list.init,
            control = list(adapt_delta = 0.90, max_treedepth = 10)
            );

        }

    out                     <- rstan::extract(fit);
    prediction              <- out$prediction;
    estimated.admissions    <- out$E_admissions;
    estimated.admissions.cf <- out$E_admissions0;

    list.output <- list(
        StanModel                  = StanModel,
        fit                        = fit,
        prediction                 = prediction,
        dates                      = dates,
        reported_cases             = reported_cases,
        admissions_by_jurisdiction = admissions_by_jurisdiction,
        jurisdictions              = jurisdictions,
        estimated_admissions       = estimated.admissions,
        estimated_admissions_cf    = estimated.admissions.cf,
        out                        = out
        );

    return( list.output );

    }

##################################################
