
getForecast.occupancy <- function(
    results.stan.change.point = NULL,
    results.stan.LoS          = NULL,
    RData.output              = "data-forecast-occupancy.RData"
    ) {

    thisFunctionName <- "getForecast.occupancy";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    require(dplyr);
    require(matrixStats);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( file.exists(RData.output) ) {

        cat(paste0("\n# ",RData.output," already exists; loading this file ...\n"));
        DF.output <- readRDS(file = RData.output);
        cat(paste0("\n# Loading complete: ",RData.output,"\n"));

    } else {

        # cat("\nnames(results.stan.change.point)\n");
        # print( names(results.stan.change.point)   );
        #
        # cat("\nnames(results.stan.LoS)\n");
        # print( names(results.stan.LoS)   );

        list.output   <- list();
        jurisdictions <- results.stan.LoS[['jurisdictions']];

        for ( index.jurisdiction in 1:length(jurisdictions) ) {

            jurisdiction <- jurisdictions[index.jurisdiction];
            index.jurisdiction.chgpt <- which( jurisdiction == results.stan.change.point[['jurisdictions']] );

            DF.observed.data       <- results.stan.change.point[['observed.data']][[jurisdiction]]
            observation.dates      <- DF.observed.data[,'date'];
            DF.expected.admissions <- results.stan.change.point[['posterior.samples']][['E_admissions']][,,index.jurisdiction.chgpt];
            n.days                 <- ncol(DF.expected.admissions);

            # cat("\nresults.stan.change.point[['dates']][[jurisdiction]]\n");
            # print( results.stan.change.point[['dates']][[jurisdiction]]   );
            #
            # cat("\nstr(results.stan.change.point[['posterior.samples']][['E_admissions']][,,index.jurisdiction.chgpt])\n");
            # print( str(results.stan.change.point[['posterior.samples']][['E_admissions']][,,index.jurisdiction.chgpt])   );
            #
            # cat("\nstr(results.stan.change.point[['observed.data']][[jurisdiction]])\n");
            # print( str(results.stan.change.point[['observed.data']][[jurisdiction]])   );
            #
            # cat("\nstr(results.stan.LoS[['observed.data']][[jurisdiction]])\n");
            # print( str(results.stan.LoS[['observed.data']][[jurisdiction]])   );

            DF.cumulative.forecast.admissions <- getForecast.occupancy_getCumulatveForecast.admissions(
                DF.observed.data = DF.observed.data,
                DF.admissions    = DF.expected.admissions
                );

            # cat("\nstr(DF.cumulative.forecast.admissions)\n");
            # print( str(DF.cumulative.forecast.admissions)   );

            ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
            DF.Prob.LoS <- getForecast.occupancy_get.Prob.LoS(
                index.jurisdiction    = index.jurisdiction,
                LoS.posterior.samples = results.stan.LoS[['posterior.samples']],
                n.days                = n.days # dim(results.stan.change.point[['posterior.samples']][['E_admissions']])[2]
                );

            # cat("\nstr(DF.Prob.LoS)\n");
            # print( str(DF.Prob.LoS)   );

            ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
            posterior.sample.indexes <- seq(1,nrow(DF.Prob.LoS));
            non.stuck.sample.indexes <- posterior.sample.indexes[results.stan.LoS[['is.not.stuck']][[jurisdiction]]];

            # cat(paste0("\n# ",thisFunctionName,"(): results.stan.LoS[['is.not.stuck']][[jurisdiction]]","\n"));
            # print( results.stan.LoS[['is.not.stuck']][[jurisdiction]] );
            #
            # cat(paste0("\n# ",thisFunctionName,"(): non.stuck.sample.indexes","\n"));
            # print( non.stuck.sample.indexes );

            indexes.LoS.posterior.samples <- base::sample(
                x       = non.stuck.sample.indexes,
                size    = nrow(DF.expected.admissions),
                replace = TRUE
                );

            # cat(paste0("\n# ",thisFunctionName,"(): indexes.LoS.posterior.samples","\n"));
            # print( indexes.LoS.posterior.samples );

            ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
            DF.forecast.discharges <- getForecast.occupancy_forecast.discharges(
                DF.observed.data              = DF.observed.data,
                DF.admissions                 = DF.expected.admissions,
                DF.Prob.LoS                   = DF.Prob.LoS,
                indexes.LoS.posterior.samples = indexes.LoS.posterior.samples
                );

            # cat("\nstr(DF.forecast.discharges)\n");
            # print( str(DF.forecast.discharges)   );

            DF.cumulative.forecast.discharges <- matrixStats::rowCumsums(x = DF.forecast.discharges);
            colnames(DF.cumulative.forecast.discharges) <- colnames(DF.forecast.discharges);

            # cat("\nstr(DF.cumulative.forecast.discharges)\n");
            # print( str(DF.cumulative.forecast.discharges)   );

            ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
            DF.estimated.discharges <- results.stan.LoS[['posterior.samples']][['E_discharges']][,,index.jurisdiction];
            DF.estimated.discharges <- DF.estimated.discharges[indexes.LoS.posterior.samples,];

            estimated.occupancy.last.observed.day <- sum(DF.observed.data[,'admissions']) - matrixStats::rowSums2(x = DF.estimated.discharges);

            DF.estimated.occupancy.last.observed.day <- matrix(
                data  = rep(x = estimated.occupancy.last.observed.day, times = ncol(DF.cumulative.forecast.admissions)),
                nrow  = length(estimated.occupancy.last.observed.day),
                byrow = FALSE
                );

            ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
            DF.forecast.occupancy.tail <- DF.cumulative.forecast.admissions - DF.cumulative.forecast.discharges;

            DF.forecast.occupancy.01 <- DF.observed.data[nrow(DF.observed.data),'occupancy'] + DF.forecast.occupancy.tail;
            DF.forecast.occupancy.02 <- DF.estimated.occupancy.last.observed.day             + DF.forecast.occupancy.tail;

            colnames(DF.forecast.occupancy.01) <- colnames(DF.cumulative.forecast.discharges);
            colnames(DF.forecast.occupancy.02) <- colnames(DF.cumulative.forecast.discharges);

            ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
            list.output[[ jurisdiction ]] <- list(
                forecast.discharges   = DF.forecast.discharges,
                forecast.occupancy.01 = DF.forecast.occupancy.01,
                forecast.occupancy.02 = DF.forecast.occupancy.02
                );

            }

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if (!is.null(RData.output)) {
        saveRDS(object = list.output, file = RData.output);
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    # return( DF.output );
    return( list.output );

    }

##################################################
getForecast.occupancy_forecast.discharges <- function(
    DF.observed.data              = NULL,
    DF.admissions                 = NULL,
    DF.Prob.LoS                   = NULL,
    indexes.LoS.posterior.samples = NULL
    ) {

    # indexes.LoS.posterior.samples <- base::sample(
    #     x       = seq(1,nrow(DF.Prob.LoS)),
    #     size    = nrow(DF.admissions),
    #     replace = TRUE
    #     );

    n.samples.chgpt <- nrow(DF.admissions);
    n.forecast.days <- ncol(DF.admissions) - nrow(DF.observed.data);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- matrix(
        data = rep(x = NA, times = n.samples.chgpt * n.forecast.days),
        nrow = n.samples.chgpt
        );
    colnames.DF.output  <- max(DF.observed.data[,'date'])  + seq(1,n.forecast.days);
    colnames(DF.output) <- as.character(colnames.DF.output);

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

        DF.temp.2.0 <- DF.admissions[,seq(n.observed.days + 1, index.forecast.day - 1,1)];
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
        shape = LoS.posterior.samples[['alpha']][,index.jurisdiction],
        rate  = LoS.posterior.samples[['beta']] [,index.jurisdiction]
        );

    indexes.date    <- seq(1,n.days);
    upper.limits    <- indexes.date + 0.5;
    lower.limits    <- indexes.date - 0.5;
    lower.limits[1] <- 0;

    DF.temp <- data.frame(
        date.index  = indexes.date,
        lower.limit = lower.limits,
        upper.limit = upper.limits
        );

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
    DF.observed.data = NULL,
    DF.admissions    = NULL
    ) {

    require(matrixStats);

    observation.dates <- DF.observed.data[,'date'];

    DF.forecast.admissions <- DF.admissions[,seq(1+length(observation.dates),ncol(DF.admissions))];
    forcast.dates <- observation.dates[length(observation.dates)] + seq(1,ncol(DF.forecast.admissions));
    colnames(DF.forecast.admissions) <- as.character(forcast.dates);

    DF.cumulatve.forecast.admissions <- matrixStats::rowCumsums(x = DF.forecast.admissions);
    colnames(DF.cumulatve.forecast.admissions) <- colnames(DF.forecast.admissions);

    return( DF.cumulatve.forecast.admissions );

    }
