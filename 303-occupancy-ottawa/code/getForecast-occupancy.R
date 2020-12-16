
getForecast.occupancy <- function(
    results.stan.change.point = NULL,
    results.stan.LoS          = NULL,
    RData.output              = "data-forecast-occupancy.RData"
    ) {

    thisFunctionName <- "getForecast.occupancy";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    require(dplyr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(RData.output) ) {

        cat(paste0("\n# ",RData.output," already exists; loading this file ...\n"));
        DF.output <- readRDS(file = RData.output);
        cat(paste0("\n# Loading complete: ",RData.output,"\n"));

    } else {

        cat("\nnames(results.stan.change.point)\n");
        print( names(results.stan.change.point)   );

        cat("\nnames(results.stan.LoS)\n");
        print( names(results.stan.LoS)   );

        jurisdictions <- results.stan.LoS[['jurisdictions']];
        for ( index.jurisdiction in 1:length(jurisdiction) ) {

            jurisdiction <- jurisdictions[index.jurisdiction];
            index.jurisdiction.chgpt <- which( jurisdiction == results.stan.change.point[['jurisdictions']] )

            DF.cumulatve.forecast.admissions <- getForecast.occupancy_getCumulatveForecast.admissions(
                observation.dates = results.stan.change.point[['dates']][[jurisdiction]];
                DF.admissions     = results.stan.change.point[['out']][['E_admissions']][,,index.jurisdiction.chgpt]
                );

            DF.Prob.LoS <- getForecast.occupancy_get.Prob.LoS(
                index.jurisdiction    = index.jurisdiction,
                LoS.posterior.samples = results.stan.LoS[['extracted.samples']],
                n.days                = dim(results.stan.change.point[['out']][['E_admissions']])[2]
                );

            DF.forecast.discharges <- getForecast.occupancy_forecast.discharges(
                DF.observed.data = results.stan.LoS[['observed.data']][[jurisdiction]],
                DF.admissions    = results.stan.change.point[['out']][['E_admissions']][,,index.jurisdiction.chgpt],
                DF.Prob.LoS      = DF.Prob.LoS
                );

            results.stan.LoS[['extracted.samples']][['']]

            }


        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    # write.csv(
    #     x         = DF.output,
    #     file      = gsub(x = RData.output, pattern = "\\.RData$", replacement = ".csv"),
    #     row.names = FALSE
    #     );
    #
    # base::saveRDS(
    #     file   = RData.output,
    #     object = DF.output
    #     );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    # return( DF.output );
    return( NULL );

    }

##################################################
getForecast.occupancy_forecast.discharges <- function(
    DF.observed.data = NULL,
    DF.admissions    = NULL,
    DF.Prob.LoS      = NULL
    ) {

    indexes.LoS.posterior.samples <- base::sample(
        x       = seq(1,nrow(DF.Prob.LoS)),
        size    = nrow(DF.admissions),
        replace = TRUE
        );

    n.samples.chgpt <- nrow(DF.admissions);
    n.forecast.days <- ncol(DF.admissions) - nrow(DF.observed.data);

    DF.output <- matrix(
        data = rep(x = NA, times = n.samples.chgpt * n.forecast.days),
        nrow = n.samples.chgpt
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    n.observed.days <- nrow(DF.observed.data);

    DF.temp.1.0 <- matrix(
        data  = rep(x = DF.observed.data[,'admissions'], times = n.samples.chgpt),
        nrow  = n.samples.chgpt,
        byrow = TRUE
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    index.forecast.day <- n.observed.days + 1;
    indexes.convoluted.days.1 <- seq(index.forecast.day - 1, index.forecast.day - n.observed.days, -1);
    DF.temp.1 <- DF.temp.1.0 * DF.Prob.LoS[indexes.LoS.posterior.samples,indexes.convoluted.days.1];
    DF.output[,1] <- matrixStats::rowSums2(x = DF.temp.1);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    for ( j in 2:ncol(DF.output) ) {

        index.forecast.day <- n.observed.days + j;

        # cat(paste0("\n### index.forecast.day = ",index.forecast.day,"\n"))
        # cat(paste0("\n### n.observed.days    = ",n.observed.days,   "\n"))

        indexes.convoluted.days.1 <- seq(index.forecast.day - 1, index.forecast.day - n.observed.days, -1);
        indexes.convoluted.days.2 <- seq(index.forecast.day - n.observed.days - 1, 1, -1);

        DF.temp.1 <- DF.temp.1.0 * DF.Prob.LoS[indexes.LoS.posterior.samples,indexes.convoluted.days.1];

        DF.temp.2.0 <- DF.admissions[,seq(n.observed.days+1,index.forecast.day-1,1)];
        DF.temp.2   <- DF.temp.2.0 * DF.Prob.LoS[indexes.LoS.posterior.samples,indexes.convoluted.days.2];
        DF.temp.2   <- matrix(data = DF.temp.2, nrow = nrow(DF.admissions));

        DF.output[,j] <- matrixStats::rowSums2(x = DF.temp.1) + matrixStats::rowSums2(x = DF.temp.2);

        }

    return( DF.output );

    }

getForecast.occupancy_get.Prob.LoS <- function(
    index.jurisdiction    = NULL,
    LoS.posterior.samples = NULL,
    n.days                = NULL
    ) {

    require(stats);

    DF.parameters <- data.frame(
        shape = LoS.posterior.samples[['extracted.samples']][['alpha']][,index.jurisdiction],
        rate  = LoS.posterior.samples[['extracted.samples']][['beta']] [,index.jurisdiction]
        );

    indexes.date    <- seq(1,n.days);
    upper.limits    <- indexes.date + 0.5;
    lower.limits    <- indexes.date - 0.5;
    lower.limits[1] <- 0;

    # pgamma(q, shape = alpha, rate = beta, lower.tail = TRUE, log.p = FALSE)

    # P_discharge[1,j] = gamma_cdf(1.5, alpha[j], beta[j]);
    # for(t in 2:n_days) {
    #     P_discharge[t,j] = gamma_cdf(t+0.5, alpha[j], beta[j]) - gamma_cdf(t-0.5, alpha[j], beta[j]);
    #     }

    DF.output <- t(apply(
        X      = DF.parameters,
        MARGIN = 1,
        FUN    = function(x) {return(
            stats::pgamma(q = upper.limits, shape = x[1], rate = x[2]) - stats::pgamma(q = lower.limits, shape = x[1], rate = x[2])
            )}
        ));

    return( DF.output );

    }

getForecast.occupancy_getCumulatveForecast.admissions <- function(
    observation.dates = NULL,
    DF.admissions     = NULL
    ) {

    require(matrixStats);

    DF.forecast.admission <- DF.admissions[,seq(1+length(observation.dates),ncol(DF.admissions))];
    forcast.dates <- observation.dates[length(observation.dates)] + seq(1,ncol(DF.forecast.admission));
    colnames(DF.forecast.admission) <- as.character(forcast.dates);

    DF.cumulatve.forecast.admission <- matrixStats::rowCumsums(x = DF.forecast.admission);
    colnames(DF.cumulatve.forecast.admission) <- colnames(DF.forecast.admission);

    return( DF.cumulatve.forecast.admission );

    }

getForecast.occupancy_cowplot <- function(
    results.stan.change.point = NULL,
    results.stan.LoS          = NULL
    ) {

    require(ggplot2);
    require(cowplot);

    jurisdictions <- base::names(list.plot.discharges);
    for ( jurisdiction in jurisdictions ) {

        plot.infections <- list.plot.infections[[jurisdiction]];
        plot.infections <- plot.infections + theme(axis.text.x = element_blank());

        plot.admissions <- list.plot.admissions[[jurisdiction]];
        plot.admissions <- plot.admissions + theme(axis.text.x = element_blank());

        plot.discharges <- list.plot.discharges[[jurisdiction]];
        plot.discharges <- plot.discharges + theme(axis.text.x = element_blank());

        plot.occupancy  <- list.plot.occupancy[[ jurisdiction]];

        my.cowplot <- cowplot::plot_grid(
            plot.infections,
            plot.admissions,
            plot.discharges,
            plot.occupancy,
            ncol        = 1,
            align       = "v",
            rel_heights = c(1,1,1,1.5)
            );

        PNG.output  <- paste0("plot-occupancy-forecast-cowplot-",jurisdiction,".png");
        cowplot::ggsave2(
            file   = PNG.output,
            plot   = my.cowplot,
            dpi    = 300,
            height =  3 + 3 + 3 + 5,
            width  =  24,
            units  = 'in'
            );

        }

    return( NULL );

    }

##################################################
getForecast.occupancy_cumulative.forecast.admissions <- function(
    list.input = NULL
    ) {

    }
