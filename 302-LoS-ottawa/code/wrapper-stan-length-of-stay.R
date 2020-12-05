
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
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output <- wrapper.stan.length.of.stay_patch(
        list.input = list.output,
        DF.input   = DF.input
        );
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(list.output[['extracted.samples']])\n");
    print( str(list.output[['extracted.samples']])   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    plot.density.mu.cv(
        list.input = list.output
        );

    plot.scatter.mu.cv(
        list.input = list.output
        );

    plot.trace.mu.cv(
        list.input = list.output
        );

    list.plot.admissions <- plot.admissions(
        list.input = list.output
        );

    list.plot.discharges <- plot.expected.discharges(
        list.input = list.output
        );

    list.plot.occupancy <- plot.expected.occupancy(
        list.input = list.output
        );

    plot.cowplot.discharges.occupancy(
        list.plot.admissions = list.plot.admissions,
        list.plot.discharges = list.plot.discharges,
        list.plot.occupancy  = list.plot.occupancy
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( list.output );

    }

##################################################
plot.admissions <- function(
    list.input    = NULL,
    textsize.axis = 20
    ) {

    thisFunctionName <- "plot.admissions";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(matrixStats);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(list.input[['observed.data']])\n");
    print( str(list.input[['observed.data']])   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.plots    <- list();
    jurisdictions <- list.input[["jurisdictions"]];

    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.plot <- list.input[['observed.data']][[jurisdiction]];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = paste0(jurisdiction,' COVID-19 daily hospital admissions')
            );

        my.ggplot <- my.ggplot + geom_col(
            data    = DF.plot,
            mapping = aes(x = date, y = admissions),
            alpha   = 0.50,
            size    = 0.75,
            fill    = "black",
            colour  = NA
            );

        my.ggplot <- my.ggplot + scale_x_date(date_breaks = "2 weeks");
        my.ggplot <- my.ggplot + theme(
            axis.text.x = element_text(size = textsize.axis, face = "bold", angle = 90, vjust = 0.5)
            );

        my.ggplot <- my.ggplot + scale_y_continuous(
            limits = NULL,
            breaks = seq(0,100,2)
            );

        my.ggplot <- my.ggplot + xlab("");
        my.ggplot <- my.ggplot + ylab("");

        list.plots[[jurisdiction]] <- my.ggplot;

        PNG.output  <- paste0("plot-admissions-",jurisdiction,".png");
        ggsave(
            file   = PNG.output,
            plot   = my.ggplot,
            dpi    = 300,
            height =   5,
            width  =  24,
            units  = 'in'
            );

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( list.plots );

    }

plot.cowplot.discharges.occupancy <- function(
    list.plot.admissions = NULL,
    list.plot.discharges = NULL,
    list.plot.occupancy  = NULL
    ) {

    require(ggplot2);
    require(cowplot);

    jurisdictions <- base::names(list.plot.discharges);
    for ( jurisdiction in jurisdictions ) {

        plot.admissions <- list.plot.admissions[[jurisdiction]];
        plot.admissions <- plot.admissions + theme(axis.text.x = element_blank());

        plot.discharges <- list.plot.discharges[[jurisdiction]];
        plot.discharges <- plot.discharges + theme(axis.text.x = element_blank());

        plot.occupancy  <- list.plot.occupancy[[ jurisdiction]];

        my.cowplot <- cowplot::plot_grid(
            plot.admissions,
            plot.discharges,
            plot.occupancy,
            ncol        = 1,
            align       = "v",
            rel_heights = c(1,1,1.5)
            );

        PNG.output  <- paste0("plot-expected-cowplot-",jurisdiction,".png");
        cowplot::ggsave2(
            file   = PNG.output,
            plot   = my.cowplot,
            dpi    = 300,
            height =  3 + 3 + 5,
            width  =  24,
            units  = 'in'
            );

        }

    return( NULL );

    }

plot.expected.occupancy <- function(
    list.input    = NULL,
    textsize.axis = 20
    ) {

    thisFunctionName <- "plot.expected.occupancy";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(matrixStats);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(list.input[['observed.data']])\n");
    print( str(list.input[['observed.data']])   );

    cat("\nstr(list.input[['extracted.samples']])\n");
    print( str(list.input[['extracted.samples']])   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.plots    <- list();
    jurisdictions <- list.input[["jurisdictions"]];

    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.plot <- list.input[['observed.data']][[jurisdiction]];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.expected.discharges <- list.input[['extracted.samples']][['E_discharges']][,,temp.index];
        DF.expected.cumulative.discharges <- matrixStats::rowCumsums(x = DF.expected.discharges);

        DF.cumulative.admissions <- base::matrix(
            data  = rep(x = DF.plot[,'cumulative.admissions'], times = nrow(DF.expected.cumulative.discharges)),
            nrow  = nrow(DF.expected.cumulative.discharges),
            byrow = TRUE
            );

        DF.expected.occupancy <- DF.cumulative.admissions - DF.expected.cumulative.discharges;

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.quantiles <- matrixStats::colQuantiles(
            x     = DF.expected.occupancy,
            probs = c(0.025,0.25,0.5,0.75,0.975)
            );
        colnames(DF.quantiles) <- c(
            "percentile.02.5",
            "percentile.25.0",
            "percentile.50.0",
            "percentile.75.0",
            "percentile.97.5"
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.plot <- cbind(DF.plot,DF.quantiles);

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = paste0(jurisdiction,' COVID-19 daily hospital midnight census counts')
            );

        my.ggplot <- my.ggplot + geom_ribbon(
            data    = DF.plot,
            mapping = aes(x = date, ymin = percentile.02.5, ymax = percentile.97.5),
            alpha   = 0.75,
            fill    = "cyan",
            colour  = NA
            );

        # my.ggplot <- my.ggplot + geom_ribbon(
        #     data    = DF.plot,
        #     mapping = aes(x = date, ymin = percentile.25.0, ymax = percentile.75.0),
        #     alpha   = 0.75,
        #     fill    = "darkcyan",
        #     colour  = NA
        #     );

        my.ggplot <- my.ggplot + geom_col(
            data    = DF.plot,
            mapping = aes(x = date, y = occupancy),
            alpha   = 0.50,
            size    = 0.75,
            fill    = "black",
            colour  = NA
            );

        my.ggplot <- my.ggplot + geom_line(
            data    = DF.plot,
            mapping = aes(x = date, y = percentile.50.0),
            alpha   = 0.85,
            size    = 1.00,
            colour  = "red"
            );

        my.ggplot <- my.ggplot + scale_x_date(date_breaks = "2 weeks");
        my.ggplot <- my.ggplot + theme(
            axis.text.x = element_text(size = textsize.axis, face = "bold", angle = 90, vjust = 0.5)
            );

        my.ggplot <- my.ggplot + scale_y_continuous(
            limits = NULL,
            breaks = seq(0,100,20)
            );

        my.ggplot <- my.ggplot + xlab("");
        my.ggplot <- my.ggplot + ylab("");

        list.plots[[jurisdiction]] <- my.ggplot;

        PNG.output  <- paste0("plot-expected-occupancy-",jurisdiction,".png");
        ggsave(
            file   = PNG.output,
            plot   = my.ggplot,
            dpi    = 300,
            height =   5,
            width  =  24,
            units  = 'in'
            );

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( list.plots );

    }

plot.expected.discharges <- function(
    list.input    = NULL,
    textsize.axis = 20
    ) {

    thisFunctionName <- "plot.expected.discharges";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(matrixStats);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(list.input[['observed.data']])\n");
    print( str(list.input[['observed.data']])   );

    cat("\nstr(list.input[['extracted.samples']])\n");
    print( str(list.input[['extracted.samples']])   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.plots    <- list();
    jurisdictions <- list.input[["jurisdictions"]];

    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.plot <- list.input[['observed.data']][[jurisdiction]];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.expected.discharges <- list.input[['extracted.samples']][['E_discharges']][,,temp.index];
        DF.quantiles <- matrixStats::colQuantiles(
            x     = DF.expected.discharges,
            probs = c(0.025,0.25,0.5,0.75,0.975)
            );
        colnames(DF.quantiles) <- c(
            "percentile.02.5",
            "percentile.25.0",
            "percentile.50.0",
            "percentile.75.0",
            "percentile.97.5"
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.plot <- cbind(DF.plot,DF.quantiles);

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = paste0(jurisdiction,' COVID-19 daily hospital discharges')
            );

        my.ggplot <- my.ggplot + geom_ribbon(
            data    = DF.plot,
            mapping = aes(x = date, ymin = percentile.02.5, ymax = percentile.97.5),
            alpha   = 0.75,
            fill    = "cyan",
            colour  = NA
            );

        # my.ggplot <- my.ggplot + geom_ribbon(
        #     data    = DF.plot,
        #     mapping = aes(x = date, ymin = percentile.25.0, ymax = percentile.75.0),
        #     alpha   = 0.75,
        #     fill    = "darkcyan",
        #     colour  = NA
        #     );

        my.ggplot <- my.ggplot + geom_col(
            data    = DF.plot,
            mapping = aes(x = date, y = discharges),
            alpha   = 0.50,
            size    = 0.75,
            fill    = "black",
            colour  = NA
            );

        my.ggplot <- my.ggplot + geom_line(
            data    = DF.plot,
            mapping = aes(x = date, y = percentile.50.0),
            alpha   = 0.85,
            size    = 1.00,
            colour  = "red"
            );

        my.ggplot <- my.ggplot + scale_x_date(date_breaks = "2 weeks");
        my.ggplot <- my.ggplot + theme(
            axis.text.x = element_text(size = textsize.axis, face = "bold", angle = 90, vjust = 0.5)
            );

        my.ggplot <- my.ggplot + scale_y_continuous(
            limits = NULL,
            breaks = seq(0,100,2)
            );

        my.ggplot <- my.ggplot + xlab("");
        my.ggplot <- my.ggplot + ylab("");

        list.plots[[jurisdiction]] <- my.ggplot;

        PNG.output  <- paste0("plot-expected-discharges-",jurisdiction,".png");
        ggsave(
            file   = PNG.output,
            plot   = my.ggplot,
            dpi    = 300,
            height =   5,
            width  =  24,
            units  = 'in'
            );

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( list.plots );

    }

wrapper.stan.length.of.stay_patch <- function(
    list.input = NULL,
    DF.input   = NULL
    ) {

    list.output <- list.input;

    if ( !('observed.data' %in% names(list.input)) ) {

        jurisdictions   <- unique(DF.input[,'jurisdiction']);
        n.jurisdictions <- length(jurisdictions);

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

plot.trace.mu.cv <- function(
    list.input = NULL
    ) {

    require(ggplot2);

    jurisdictions <- list.input[["jurisdictions"]];
    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        temp.alpha <- list.input[["extracted.samples"]][["alpha"]][,temp.index];
        temp.beta  <- list.input[["extracted.samples"]][["beta" ]][,temp.index];

        DF.plot <- data.frame(
            index = seq(1,length(temp.alpha),1),
            alpha = temp.alpha,
            beta  = temp.beta,
            mu    = temp.alpha / temp.beta,
            cv    = 1 / sqrt(temp.alpha)
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = jurisdiction
            );

        my.ggplot <- my.ggplot + geom_point(
            data    = DF.plot,
            mapping = aes(x = index, y = mu),
            alpha   = 0.5,
            size    = 0.5
            );

        my.ggplot <- my.ggplot + xlab('iteration');
        my.ggplot <- my.ggplot + ylab('mean( length of stay )');

        # my.ggplot <- my.ggplot + scale_x_continuous(
        #     limits = c(0,50),
        #     breaks = seq(0,50,10)
        #     );

        my.ggplot <- my.ggplot + scale_y_continuous(
            limits = c(0,50),
            breaks = seq(0,50,10)
            );

        ggsave(
            file   = paste0("plot-trace-LoS-mu-",jurisdiction,".png"),
            plot   = my.ggplot,
            dpi    = 300,
            height =   8,
            width  =  16,
            units  = 'in'
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = jurisdiction
            );

        my.ggplot <- my.ggplot + geom_point(
            data    = DF.plot,
            mapping = aes(x = index, y = cv),
            alpha   = 0.5,
            size    = 0.5
            );

        my.ggplot <- my.ggplot + xlab('iteration');
        my.ggplot <- my.ggplot + ylab('CV( length of stay )');

        # my.ggplot <- my.ggplot + scale_x_continuous(
        #     limits = c(0,50),
        #     breaks = seq(0,50,10)
        #     );

        my.ggplot <- my.ggplot + scale_y_continuous(
            limits = c(0,2),
            breaks = seq(0,2,0.2)
            );

        ggsave(
            file   = paste0("plot-trace-LoS-cv-",jurisdiction,".png"),
            plot   = my.ggplot,
            dpi    = 300,
            height =   8,
            width  =  16,
            units  = 'in'
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

        }

    return( NULL );

    }

plot.scatter.mu.cv <- function(
    list.input = NULL
    ) {

    require(ggplot2);

    jurisdictions <- list.input[["jurisdictions"]];
    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        temp.alpha <- list.input[["extracted.samples"]][["alpha"]][,temp.index];
        temp.beta  <- list.input[["extracted.samples"]][["beta" ]][,temp.index];

        DF.plot <- data.frame(
            mu = temp.alpha / temp.beta,
            cv = 1 / sqrt(temp.alpha)
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = jurisdiction
            );

        my.ggplot <- my.ggplot + geom_point(
            data    = DF.plot,
            mapping = aes(x = mu, y = cv),
            alpha   = 0.50,
            size    = 0.50
            );

        my.ggplot <- my.ggplot + xlab('mean( length of stay )');
        my.ggplot <- my.ggplot + ylab('CV( length of stay )');

        my.ggplot <- my.ggplot + scale_x_continuous(
            limits = c(0,50),
            breaks = seq(0,50,5)
            );

        my.ggplot <- my.ggplot + scale_y_continuous(
            limits = c(0,2),
            breaks = seq(0,2,0.2)
            );

        ggsave(
            file   = paste0("plot-scatter-LoS-mu-cv-",jurisdiction,".png"),
            plot   = my.ggplot,
            dpi    = 300,
            height =   8,
            width  =  16,
            units  = 'in'
            );

        }

    return( NULL );

    }

plot.density.mu.cv <- function(
    list.input = NULL
    ) {

    require(ggplot2);

    jurisdictions <- list.input[["jurisdictions"]];
    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        temp.alpha <- list.input[["extracted.samples"]][["alpha"]][,temp.index];
        temp.beta  <- list.input[["extracted.samples"]][["beta" ]][,temp.index];

        DF.plot <- data.frame(
            mu = temp.alpha / temp.beta,
            cv = 1 / sqrt(temp.alpha)
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = jurisdiction
            );

        my.ggplot <- my.ggplot + geom_density(
            data    = DF.plot,
            mapping = aes(x = mu),
            alpha   = 0.85,
            size    = 1.30
            );

        my.ggplot <- my.ggplot + xlab('mean( length of stay )');
        my.ggplot <- my.ggplot + ylab('density');

        my.ggplot <- my.ggplot + scale_x_continuous(
            limits = c(0,50),
            breaks = seq(0,50,10)
            );

        ggsave(
            file   = paste0("plot-density-LoS-mu-",jurisdiction,".png"),
            plot   = my.ggplot,
            dpi    = 300,
            height =   8,
            width  =  16,
            units  = 'in'
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = jurisdiction
            );

        my.ggplot <- my.ggplot + geom_density(
            data    = DF.plot,
            mapping = aes(x = cv),
            alpha   = 0.85,
            size    = 1.30
            );

        my.ggplot <- my.ggplot + xlab('CV( length of stay )');
        my.ggplot <- my.ggplot + ylab('density');

        my.ggplot <- my.ggplot + scale_x_continuous(
            limits = c(0,2),
            breaks = seq(0,2,0.2)
            );

        ggsave(
            file   = paste0("plot-density-LoS-cv-",jurisdiction,".png"),
            plot   = my.ggplot,
            dpi    = 300,
            height =   8,
            width  =  16,
            units  = 'in'
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

        }

    return( NULL );

    }

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
                uniform_mu = runif(n.jurisdictions, min = 0, max = 1),
                uniform_cv = runif(n.jurisdictions, min = 0, max = 1)
                )
            }
        );

    if( DEBUG ) {

        results.rstan.sampling <- rstan::sampling(
            object = my.stan.model,
            data   = stan_data,
            init   = list.init,
            iter   = 40,
            warmup = 20,
            chains =  2
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
            iter    = 2500,
            warmup  =  500,
            chains  =    2,
            thin    =    4,
            control = list(adapt_delta = 0.90, max_treedepth = 10)
            );

        }

    extracted.samples <- rstan::extract(results.rstan.sampling);

    list.output <- list(
        StanModel              = StanModel,
        jurisdictions          = jurisdictions,
        observed.data          = observed.data,
        results.rstan.sampling = results.rstan.sampling,
        extracted.samples      = extracted.samples
        );

    return( list.output );

    }

##################################################
