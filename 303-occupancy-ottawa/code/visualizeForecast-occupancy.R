
visualizeForecast.occupancy <- function(
    DF.complete               = NULL,
    results.stan.change.point = NULL,
    results.stan.LoS          = NULL,
    list.forecast.occupancy   = NULL,
    forecast.window           = 7
    ) {

    thisFunctionName <- "visualizeForecast.occupancy";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.plot.admissions <- visualizeForecast.occupancy_admissions(
        DF.complete               = DF.complete,
        results.stan.change.point = results.stan.change.point,
        results.stan.LoS          = results.stan.LoS,
        forecast.window           = forecast.window
        );

    list.plot.discharges <- visualizeForecast.occupancy_discharges(
        DF.complete             = DF.complete,
        results.stan.LoS        = results.stan.LoS,
        list.forecast.occupancy = list.forecast.occupancy,
        forecast.window         = forecast.window
        );

    list.plot.occupancy <- visualizeForecast.occupancy_occupancy(
        DF.complete             = DF.complete,
        results.stan.LoS        = results.stan.LoS,
        list.forecast.occupancy = list.forecast.occupancy,
        forecast.window         = forecast.window
        );

    visualizeForecast.occupancy_cowplot(
        results.stan.LoS        = results.stan.LoS,
        list.forecast.occupancy = list.forecast.occupancy,
        list.plot.admissions    = list.plot.admissions,
        list.plot.discharges    = list.plot.discharges,
        list.plot.occupancy     = list.plot.occupancy,
        forecast.window         = forecast.window
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( NULL );

    }

##################################################
visualizeForecast.occupancy_cowplot <- function(
    results.stan.LoS        = NULL,
    list.forecast.occupancy = NULL,
    list.plot.admissions    = NULL,
    list.plot.discharges    = NULL,
    list.plot.occupancy     = NULL,
    forecast.window         = NULL
    ) {

    require(ggplot2);
    require(cowplot);

    jurisdictions <- base::names(list.plot.discharges);
    for ( jurisdiction in jurisdictions ) {

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        min.observed.date <- min(results.stan.LoS[['observed.data']][[jurisdiction]][,'date']);
        max.observed.date <- max(results.stan.LoS[['observed.data']][[jurisdiction]][,'date']);
        max.forecast.date <- max(as.Date(colnames(list.forecast.occupancy[[jurisdiction]][['forecast.occupancy']])));

        common.date.limits <- c(
            min.observed.date,
            min( max.observed.date + forecast.window , max.forecast.date )
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        plot.admissions <- list.plot.admissions[[jurisdiction]];
        plot.discharges <- list.plot.discharges[[jurisdiction]];
        plot.occupancy  <- list.plot.occupancy[[ jurisdiction]];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        plot.admissions <- plot.admissions + scale_x_date(
            limits      = common.date.limits,
            date_breaks = "2 weeks"
            );
        plot.admissions <- plot.admissions + geom_vline(
            xintercept = max.observed.date,
            col        = "black",
            linetype   = "dashed",
            alpha      = 0.85
            );

        plot.discharges <- plot.discharges + scale_x_date(
            limits      = common.date.limits,
            date_breaks = "2 weeks"
            );
        plot.discharges <- plot.discharges + geom_vline(
            xintercept = max.observed.date,
            col        = "black",
            linetype   = "dashed",
            alpha      = 0.85
            );

        plot.occupancy <- plot.occupancy + scale_x_date(
            limits      = common.date.limits,
            date_breaks = "2 weeks"
            );
        plot.occupancy <- plot.occupancy + geom_vline(
            xintercept = max.observed.date,
            col        = "black",
            linetype   = "dashed",
            alpha      = 0.85
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        plot.admissions <- plot.admissions + theme(axis.text.x = element_blank());
        plot.discharges <- plot.discharges + theme(axis.text.x = element_blank());

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.cowplot <- cowplot::plot_grid(
            plot.admissions,
            plot.discharges,
            plot.occupancy,
            ncol        = 1,
            align       = "v",
            rel_heights = c(1,1,1.5)
            );

        PNG.output  <- paste0("plot-occupancy-cowplot-",jurisdiction,".png");
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

visualizeForecast.occupancy_admissions <- function(
    DF.complete               = NULL,
    results.stan.change.point = NULL,
    results.stan.LoS          = NULL,
    forecast.window           = NULL,
    textsize.axis             = 20
    ) {

    thisFunctionName <- "visualizeForecast.occupancy_admissions";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(matrixStats);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(results.stan.LoS[['observed.data']])\n");
    print( str(results.stan.LoS[['observed.data']])   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.plots    <- list();
    jurisdictions <- results.stan.LoS[["jurisdictions"]];

    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.estimated      <- results.stan.change.point[['posterior.samples']][['E_admissions']][,,temp.index];
        columns.estimated <- seq(1,length(results.stan.change.point[["dates"]][[jurisdiction]]));
        DF.estimated      <- DF.estimated[,columns.estimated];

        DF.quantiles <- matrixStats::colQuantiles(
            x     = DF.estimated,
            probs = c(0.025,0.25,0.5,0.75,0.975)
            );
        DF.quantiles <- as.data.frame(DF.quantiles);
        colnames(DF.quantiles) <- c(
            "percentile.02.5",
            "percentile.25.0",
            "percentile.50.0",
            "percentile.75.0",
            "percentile.97.5"
            );

        DF.quantiles <- cbind(DF.quantiles, date = results.stan.change.point[['dates']][[jurisdiction]]);

        cat("\nstr(DF.quantiles)\n");
        print( str(DF.quantiles)   );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.forecast <- results.stan.change.point[['posterior.samples']][['E_admissions']][,,temp.index];

        last.estimated.date.index <- length(results.stan.change.point[["dates"]][[jurisdiction]]);
        last.forecast.date.index  <- min( last.estimated.date.index + forecast.window , ncol(DF.forecast) );
        columns.forecast          <- seq(last.estimated.date.index,last.forecast.date.index);

        DF.forecast <- DF.forecast[,columns.forecast];
        DF.quantiles.forecast  <- matrixStats::colQuantiles(
            x     = DF.forecast,
            probs = c(0.025,0.25,0.5,0.75,0.975)
            );
        DF.quantiles.forecast <- as.data.frame(DF.quantiles.forecast);
        colnames(DF.quantiles.forecast) <- c(
            "percentile.02.5",
            "percentile.25.0",
            "percentile.50.0",
            "percentile.75.0",
            "percentile.97.5"
            );

        n.days.forecast       <- last.forecast.date.index - last.estimated.date.index;
        dates.forecast        <- max(results.stan.change.point[['dates']][[jurisdiction]]) + seq(0,n.days.forecast);
        DF.quantiles.forecast <- cbind(DF.quantiles.forecast, date = dates.forecast);

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        # DF.plot <- results.stan.LoS[['observed.data']][[jurisdiction]];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = paste0(jurisdiction,' COVID-19 daily hospital admissions')
            );

        my.ggplot <- my.ggplot + geom_ribbon(
            data    = DF.quantiles,
            mapping = aes(x = date, ymin = percentile.02.5, ymax = percentile.97.5),
            alpha   = 0.50,
            fill    = "deepskyblue4",
            colour  = NA
            );

        my.ggplot <- my.ggplot + geom_ribbon(
            data    = DF.quantiles,
            mapping = aes(x = date, ymin = percentile.25.0, ymax = percentile.75.0),
            alpha   = 0.75,
            fill    = "deepskyblue4",
            colour  = NA
            );

        my.ggplot <- my.ggplot + geom_ribbon(
            data    = DF.quantiles.forecast,
            mapping = aes(x = date, ymin = percentile.02.5, ymax = percentile.97.5),
            alpha   = 0.50,
            fill    = "darkgoldenrod1",
            colour  = NA
            );

        my.ggplot <- my.ggplot + geom_ribbon(
            data    = DF.quantiles.forecast,
            mapping = aes(x = date, ymin = percentile.25.0, ymax = percentile.75.0),
            alpha   = 0.75,
            fill    = "darkgoldenrod1",
            colour  = NA
            );

        my.ggplot <- my.ggplot + geom_col(
            data    = DF.complete[DF.complete[,'jurisdiction'] == jurisdiction,], # DF.plot,
            mapping = aes(x = date, y = admissions),
            alpha   = 0.50,
            size    = 0.75,
            fill    = "coral4",
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

        PNG.output  <- paste0("plot-occupancy-admissions-",jurisdiction,".png");
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

visualizeForecast.occupancy_discharges <- function(
    DF.complete             = NULL,
    results.stan.LoS        = NULL,
    list.forecast.occupancy = list.forecast.occupancy,
    forecast.window         = forecast.window,
    textsize.axis           = 20
    ) {

    thisFunctionName <- "visualizeForecast.occupancy_discharges";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(matrixStats);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(results.stan.LoS[['observed.data']])\n");
    print( str(results.stan.LoS[['observed.data']])   );

    cat("\nstr(results.stan.LoS[['posterior.samples']])\n");
    print( str(results.stan.LoS[['posterior.samples']])   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.plots    <- list();
    jurisdictions <- results.stan.LoS[["jurisdictions"]];

    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.plot <- results.stan.LoS[['observed.data']][[jurisdiction]];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.expected.discharges <- results.stan.LoS[['posterior.samples']][['E_discharges']][,,temp.index];
        DF.expected.discharges <- DF.expected.discharges[results.stan.LoS[['is.not.stuck']][[jurisdiction]],];

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
        DF.forecast.discharges <- list.forecast.occupancy[[jurisdiction]][['forecast.discharges']];
        DF.quantiles.forecast <- matrixStats::colQuantiles(
            x     = DF.forecast.discharges,
            probs = c(0.025,0.25,0.5,0.75,0.975)
            );
        DF.quantiles.forecast <- as.data.frame(DF.quantiles.forecast);
        colnames(DF.quantiles.forecast) <- c(
            "percentile.02.5",
            "percentile.25.0",
            "percentile.50.0",
            "percentile.75.0",
            "percentile.97.5"
            );
        DF.quantiles.forecast[,'date'] <- as.Date(colnames(DF.forecast.discharges));
        DF.quantiles.forecast <- DF.quantiles.forecast[,c('date',setdiff(colnames(DF.quantiles.forecast),'date'))];
        DF.quantiles.forecast <- DF.quantiles.forecast[1:forecast.window,];

        cat("\nstr(DF.quantiles.forecast)\n");
        print( str(DF.quantiles.forecast)   );

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
            data    = DF.complete[DF.complete[,'jurisdiction'] == jurisdiction,], # DF.plot,
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

        my.ggplot <- my.ggplot + geom_ribbon(
            data    = DF.quantiles.forecast,
            mapping = aes(x = date, ymin = percentile.02.5, ymax = percentile.97.5),
            alpha   = 0.50,
            fill    = "darkgoldenrod1",
            colour  = NA
            );

        my.ggplot <- my.ggplot + geom_ribbon(
            data    = DF.quantiles.forecast,
            mapping = aes(x = date, ymin = percentile.25.0, ymax = percentile.75.0),
            alpha   = 0.75,
            fill    = "darkgoldenrod1",
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

        PNG.output  <- paste0("plot-occupancy-discharges-",jurisdiction,".png");
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

visualizeForecast.occupancy_occupancy <- function(
    DF.complete             = NULL,
    results.stan.LoS        = NULL,
    list.forecast.occupancy = NULL,
    forecast.window         = NULL,
    textsize.axis           = 20
    ) {

    thisFunctionName <- "visualizeForecast.occupancy_occupancy";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(matrixStats);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(results.stan.LoS[['observed.data']])\n");
    print( str(results.stan.LoS[['observed.data']])   );

    cat("\nstr(results.stan.LoS[['posterior.samples']])\n");
    print( str(results.stan.LoS[['posterior.samples']])   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.plots    <- list();
    jurisdictions <- results.stan.LoS[["jurisdictions"]];

    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.plot <- results.stan.LoS[['observed.data']][[jurisdiction]];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.expected.discharges <- results.stan.LoS[['posterior.samples']][['E_discharges']][,,temp.index];
        DF.expected.discharges <- DF.expected.discharges[results.stan.LoS[['is.not.stuck']][[jurisdiction]],];

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
        DF.forecast.occupancy <- list.forecast.occupancy[[jurisdiction]][['forecast.occupancy']];
        DF.quantiles.forecast <- matrixStats::colQuantiles(
            x     = DF.forecast.occupancy,
            probs = c(0.025,0.25,0.5,0.75,0.975)
            );
        DF.quantiles.forecast <- as.data.frame(DF.quantiles.forecast);
        colnames(DF.quantiles.forecast) <- c(
            "percentile.02.5",
            "percentile.25.0",
            "percentile.50.0",
            "percentile.75.0",
            "percentile.97.5"
            );
        DF.quantiles.forecast[,'date'] <- as.Date(colnames(DF.forecast.occupancy));
        DF.quantiles.forecast <- DF.quantiles.forecast[,c('date',setdiff(colnames(DF.quantiles.forecast),'date'))];
        DF.quantiles.forecast <- DF.quantiles.forecast[1:forecast.window,];

        cat("\nstr(DF.quantiles.forecast)\n");
        print( str(DF.quantiles.forecast)   );

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
            data    = DF.complete[DF.complete[,'jurisdiction'] == jurisdiction,], # DF.plot,
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

        my.ggplot <- my.ggplot + geom_ribbon(
            data    = DF.quantiles.forecast,
            mapping = aes(x = date, ymin = percentile.02.5, ymax = percentile.97.5),
            alpha   = 0.50,
            fill    = "darkgoldenrod1",
            colour  = NA
            );

        my.ggplot <- my.ggplot + geom_ribbon(
            data    = DF.quantiles.forecast,
            mapping = aes(x = date, ymin = percentile.25.0, ymax = percentile.75.0),
            alpha   = 0.75,
            fill    = "darkgoldenrod1",
            colour  = NA
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

        PNG.output  <- paste0("plot-occupancy-occupancy-",jurisdiction,".png");
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
