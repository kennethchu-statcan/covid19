
visualizeModel.change.point <- function(
    list.input      = NULL,
    forecast.window = 7
    ) {

    thisFunctionName <- "visualizeModel.change.point";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    plot.cowplot.changepoints(
        list.input          = list.input,
        forecast.window     = forecast.window,
        remove.stuck.chains = FALSE
        );

    plot.trace.changepoints(
        list.input          = list.input,
        remove.stuck.chains = FALSE
        );

    plot.density.changepoints(
        list.input          = list.input,
        remove.stuck.chains = FALSE
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    visualizeModel.change.point_basic(
        list.input = list.input
        );

    plot.3.panel(
        list.input = list.input
        );

    plot.stepsize.vs.chgpt(
        list.input = list.input
        );

    plot.forecast(
        list.input      = list.input,
        forecast.window = forecast.window
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( NULL );

    }

##################################################
plot.cowplot.changepoints <- function(
    list.input          = NULL,
    forecast.window     = 7,
    remove.stuck.chains = FALSE
    ) {

    require(ggplot2);
    require(cowplot);

    jurisdictions <- list.input[["jurisdictions"]];
    for ( index.jurisdiction in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[index.jurisdiction];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        last.estimated.date.index <- length(list.input[["dates"]][[jurisdiction]]);
        DF.temp                   <- list.input[['out']][['E_admissions']][,,index.jurisdiction];
        last.forecast.date.index  <- min( last.estimated.date.index + forecast.window , ncol(DF.temp) );
        n.days.forecast           <- last.forecast.date.index - last.estimated.date.index;
        dates.forecast            <- max(list.input[['dates']][[jurisdiction]]) + seq(0,n.days.forecast);
        common.date.limits <- c(
            min(list.input[['dates']][[jurisdiction]]),
            max(dates.forecast)
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        plot.infections <- plot.cowplot.changepoints_expected(
            list.input         = list.input,
            index.jurisdiction = index.jurisdiction,
            jurisdiction       = jurisdiction,
            variable.observed  = 'cases',
            variable.estimated = 'prediction',
            plot.subtitle      = 'COVID-19 daily confirmed case counts & estimated (true) infection counts',
            plot.breaks        = seq(0,1000,100),
            textsize.axis      = 27
            );
        plot.infections <- plot.infections + theme(axis.text.x = element_blank());
        plot.infections <- plot.infections + scale_x_date(
            limits      = common.date.limits,
            date_breaks = "2 weeks"
            );
        plot.infections <- plot.infections + geom_vline(
            xintercept = dates.forecast[1],
            col        = "black",
            linetype   = "dashed",
            alpha      = 0.85
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        plot.admissions <- plot.cowplot.changepoints_expected(
            list.input         = list.input,
            index.jurisdiction = index.jurisdiction,
            jurisdiction       = jurisdiction,
            variable.observed  = 'admissions',
            variable.estimated = 'E_admissions',
            plot.subtitle      = 'COVID-19 daily new hospital admissions',
            plot.forecast      = TRUE,
            forecast.window    = forecast.window,
            plot.breaks        = seq(0,100,2),
            textsize.axis      = 27
            );
        plot.admissions <- plot.admissions + theme(axis.text.x = element_blank());
        plot.admissions <- plot.admissions + scale_x_date(
            limits      = common.date.limits,
            date_breaks = "2 weeks"
            );
        plot.admissions <- plot.admissions + geom_vline(
            xintercept = dates.forecast[1],
            col        = "black",
            linetype   = "dashed",
            alpha      = 0.85
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        plot.Rt <- plot.cowplot.changepoints_Rt(
            list.input         = list.input,
            index.jurisdiction = index.jurisdiction,
            jurisdiction       = jurisdiction,
            plot.subtitle      = 'COVID-19 time-varying reproduction number',
            plot.breaks        = seq(0,10,2),
            textsize.axis      = 27
            );
        plot.Rt <- plot.Rt + theme(axis.text.x = element_blank());
        plot.Rt <- plot.Rt + scale_x_date(
            limits      = common.date.limits,
            date_breaks = "2 weeks"
            );
        plot.Rt <- plot.Rt + geom_vline(
            xintercept = dates.forecast[1],
            col        = "black",
            linetype   = "dashed",
            alpha      = 0.85
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        plot.stepsize.vs.chgpt <- plot.cowplot.changepoints_stepsize.vs.chgpt(
            list.input         = list.input,
            index.jurisdiction = index.jurisdiction,
            jurisdiction       = jurisdiction,
            textsize.axis      = 27
            );
        plot.stepsize.vs.chgpt <- plot.stepsize.vs.chgpt + scale_x_date(
            limits      = common.date.limits,
            date_breaks = "2 weeks"
            );
        plot.stepsize.vs.chgpt <- plot.stepsize.vs.chgpt + geom_vline(
            xintercept = dates.forecast[1],
            col        = "black",
            linetype   = "dashed",
            alpha      = 0.85
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.cowplot <- cowplot::plot_grid(
            plot.infections,
            plot.admissions,
            plot.Rt,
            plot.stepsize.vs.chgpt,
            ncol        = 1,
            align       = "v",
            rel_heights = c(1,1,1,1.3)
            );

        PNG.output  <- paste0("plot-ChgPt-cowplot-",jurisdiction,".png");
        cowplot::ggsave2(
            file   = PNG.output,
            plot   = my.cowplot,
            dpi    = 300,
            height =  3 * 5 + 5,
            width  =  32,
            units  = 'in'
            );

        }

    return(NULL);

    }

plot.cowplot.changepoints_stepsize.vs.chgpt <- function(
    list.input         = NULL,
    index.jurisdiction = NULL,
    jurisdiction       = NULL,
    textsize.axis      = 27
    ) {

    DF.chgpt1 <- plot.stepsize.vs.chgpt_getData(
        list.input         = list.input,
        jurisdiction.index = index.jurisdiction,
        which.chgpt        = "chgpt1",
        which.step         = "step1"
        );

    DF.chgpt2 <- plot.stepsize.vs.chgpt_getData(
        list.input         = list.input,
        jurisdiction.index = index.jurisdiction,
        which.chgpt        = "chgpt2",
        which.step         = "step2"
        );

    DF.chgpt3 <- plot.stepsize.vs.chgpt_getData(
        list.input         = list.input,
        jurisdiction.index = index.jurisdiction,
        which.chgpt        = "chgpt3",
        which.step         = "step3"
        );

    DF.chgpt4 <- plot.stepsize.vs.chgpt_getData(
        list.input         = list.input,
        jurisdiction.index = index.jurisdiction,
        which.chgpt        = "chgpt4",
        which.step         = "step4"
        );

    DF.jurisdiction <- rbind(
        DF.chgpt1,
        DF.chgpt2,
        DF.chgpt3,
        DF.chgpt4
        );

    my.ggplot <- plot.stepsize.vs.chgpt_make.plots(
        DF.jurisdiction = DF.jurisdiction,
        StanModel       = list.input[["StanModel"]],
        jurisdiction    = list.input[["jurisdictions"]][[index.jurisdiction]],
        min.date        = min(list.input[["dates"]][[index.jurisdiction]]),
        max.date        = max(list.input[["dates"]][[index.jurisdiction]]),
        save.to.disk    = FALSE
        );

    my.ggplot <- my.ggplot + theme(
        legend.position = "none",
        axis.title.x    = element_blank(),
        axis.title.y    = element_blank(),
        axis.text.x     = element_text(size = textsize.axis, face = "bold", angle = 90, vjust = 0.5),
        axis.text.y     = element_text(size = textsize.axis, face = "bold")
        );

    my.ggplot <- my.ggplot + scale_x_date(
        limits      = range(list.input[["dates"]][[index.jurisdiction]]),
        date_breaks = "2 weeks"
        );

    my.ggplot <- my.ggplot + scale_y_continuous(
        limits = c(  -2,2),
        breaks = seq(-2,2,1)
        );

    return( my.ggplot );

    }

plot.cowplot.changepoints_Rt <- function(
    list.input         = NULL,
    index.jurisdiction = NULL,
    jurisdiction       = NULL,
    plot.subtitle      = NULL,
    plot.breaks        = NULL,
    textsize.axis      = 27
    ) {

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.Rt <- list.input[['out']][['Rt']][,,index.jurisdiction];
    # DF.Rt <- DF.Rt[list.input[['is.not.stuck']][[jurisdiction]],];

    selected.columns <- seq(1,length(list.input[["dates"]][[jurisdiction]]));
    DF.Rt <- DF.Rt[,selected.columns];

    DF.quantiles <- matrixStats::colQuantiles(
        x     = DF.Rt,
        probs = c(0.025,0.25,0.5,0.75,0.975)
        );
    colnames(DF.quantiles) <- c(
        "percentile.02.5",
        "percentile.25.0",
        "percentile.50.0",
        "percentile.75.0",
        "percentile.97.5"
        );

    DF.quantiles <- as.data.frame(DF.quantiles);
    DF.plot      <- cbind(DF.quantiles,date = list.input[['dates']][[jurisdiction]]);

    cat("\nstr(DF.plot)\n");
    print( str(DF.plot)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = paste0(jurisdiction,' ',plot.subtitle)
        );

    my.ggplot <- my.ggplot + geom_ribbon(
        data    = DF.plot,
        mapping = aes(x = date, ymin = percentile.02.5, ymax = percentile.97.5),
        alpha   = 0.50,
        fill    = "seagreen",
        colour  = NA
        );

    my.ggplot <- my.ggplot + geom_ribbon(
        data    = DF.plot,
        mapping = aes(x = date, ymin = percentile.25.0, ymax = percentile.75.0),
        alpha   = 0.75,
        fill    = "seagreen",
        colour  = NA
        );

    # my.ggplot <- my.ggplot + geom_line(
    #     data    = DF.plot,
    #     mapping = aes(x = date, y = percentile.50.0),
    #     alpha   = 0.85,
    #     size    = 1.00,
    #     colour  = "yellow"
    #     );

    my.ggplot <- my.ggplot + geom_hline(
        yintercept = 1,
        size       = 1.5,
        colour     = "gray"
        );

    my.ggplot <- my.ggplot + theme(
        axis.text.x = element_text(size = textsize.axis, face = "bold", angle = 90, vjust = 0.5),
        axis.text.y = element_text(size = textsize.axis, face = "bold")
        );

    my.ggplot <- my.ggplot + scale_x_date(date_breaks = "2 weeks");
    my.ggplot <- my.ggplot + scale_y_continuous(
        limits = c(0,1.75*max(DF.plot[,'percentile.75.0'])),
        breaks = plot.breaks
        );

    my.ggplot <- my.ggplot + xlab("");
    my.ggplot <- my.ggplot + ylab("");

    # PNG.output  <- paste0("plot-ChgPt-infections-",jurisdiction,".png");
    # ggsave(
    #     file   = PNG.output,
    #     plot   = my.ggplot,
    #     dpi    = 300,
    #     height =   5,
    #     width  =  24,
    #     units  = 'in'
    #     );

    return( my.ggplot )

    }

plot.cowplot.changepoints_expected <- function(
    list.input         = NULL,
    index.jurisdiction = NULL,
    jurisdiction       = NULL,
    variable.observed  = NULL,
    variable.estimated = NULL,
    plot.subtitle      = NULL,
    plot.breaks        = seq(0,1000,50),
    plot.forecast      = FALSE,
    forecast.window    = NULL,
    textsize.axis      = 27
    ) {

    DF.plot <- list.input[['observed.data']][[jurisdiction]];

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    colnames(DF.plot) <- gsub(
        x           = colnames(DF.plot),
        pattern     = variable.observed,
        replacement = "variable.observed"
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.estimated <- list.input[['out']][[variable.estimated]][,,index.jurisdiction];
    # DF.estimated <- DF.expected.discharges[list.input[['is.not.stuck']][[jurisdiction]],];

    columns.estimated <- seq(1,length(list.input[["dates"]][[jurisdiction]]));
    DF.estimated <- DF.estimated[,columns.estimated];

    DF.quantiles <- matrixStats::colQuantiles(
        x     = DF.estimated,
        probs = c(0.025,0.25,0.5,0.75,0.975)
        );
    colnames(DF.quantiles) <- c(
        "percentile.02.5",
        "percentile.25.0",
        "percentile.50.0",
        "percentile.75.0",
        "percentile.97.5"
        );

    DF.quantiles <- cbind(DF.quantiles, date = list.input[['dates']][[jurisdiction]]);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( plot.forecast ) {

        DF.forecast <- list.input[['out']][[variable.estimated]][,,index.jurisdiction];

        last.estimated.date.index <- length(list.input[["dates"]][[jurisdiction]]);
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
        dates.forecast        <- max(list.input[['dates']][[jurisdiction]]) + seq(0,n.days.forecast);
        DF.quantiles.forecast <- cbind(DF.quantiles.forecast, date = dates.forecast);

        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.plot <- merge(
        x  = DF.plot,
        y  = DF.quantiles,
        by = 'date'
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = paste0(jurisdiction,' ',plot.subtitle)
        );

    my.ggplot <- my.ggplot + geom_ribbon(
        data    = DF.plot,
        mapping = aes(x = date, ymin = percentile.02.5, ymax = percentile.97.5),
        alpha   = 0.50,
        fill    = "deepskyblue4",
        colour  = NA
        );

    my.ggplot <- my.ggplot + geom_ribbon(
        data    = DF.plot,
        mapping = aes(x = date, ymin = percentile.25.0, ymax = percentile.75.0),
        alpha   = 0.75,
        fill    = "deepskyblue4",
        colour  = NA
        );

    if ( plot.forecast ) {
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
        }

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = variable.observed),
        alpha   = 0.50,
        size    = 0.75,
        fill    = "coral4",
        colour  = NA
        );

    # my.ggplot <- my.ggplot + geom_line(
    #     data    = DF.plot,
    #     mapping = aes(x = date, y = percentile.50.0),
    #     alpha   = 0.85,
    #     size    = 1.00,
    #     colour  = "yellow"
    #     );

    my.ggplot <- my.ggplot + theme(
        axis.text.x = element_text(size = textsize.axis, face = "bold", angle = 90, vjust = 0.5),
        axis.text.y = element_text(size = textsize.axis, face = "bold")
        );

    my.ggplot <- my.ggplot + scale_x_date(date_breaks = "2 weeks");
    my.ggplot <- my.ggplot + scale_y_continuous(
        limits = NULL,
        breaks = plot.breaks
        );

    my.ggplot <- my.ggplot + xlab("");
    my.ggplot <- my.ggplot + ylab("");

    PNG.output  <- paste0("plot-ChgPt-",variable.observed,"-",jurisdiction,".png");
    ggsave(
        file   = PNG.output,
        plot   = my.ggplot,
        dpi    = 300,
        height =   5,
        width  =  32,
        units  = 'in'
        );

    return( my.ggplot )

    }

plot.trace.changepoints <- function(
    list.input          = NULL,
    remove.stuck.chains = FALSE
    ) {

    require(ggplot2);

    jurisdictions <- list.input[["jurisdictions"]];
    change.points <- grep( x = names(list.input[['out']]), pattern = "chgpt[0-9]", value = TRUE);
    step.sizes    <- grep( x = names(list.input[['out']]), pattern = "step[0-9]",  value = TRUE);

    for ( index.jurisdiction in 1:length(jurisdictions) ) {
    for ( index.change.point in 1:length(change.points) ) {

        jurisdiction  <- jurisdictions[index.jurisdiction];
        temp.chgpt    <- change.points[index.change.point];
        temp.stepsize <- step.sizes[   index.change.point];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        vector.chgpt    <- list.input[["out"]][[temp.chgpt   ]][,index.jurisdiction];
        vector.stepsize <- list.input[["out"]][[temp.stepsize]][,index.jurisdiction];

        # if ( remove.stuck.chains ) {
        #     temp.alpha <- temp.alpha[list.input[["is.not.stuck"]][[jurisdiction]]];
        #     temp.beta  <- temp.beta[ list.input[["is.not.stuck"]][[jurisdiction]]];
        #     }

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.plot <- data.frame(
            index        = seq(1,length(vector.chgpt),1),
            change.point = vector.chgpt,
            step.size    = vector.stepsize
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = paste0(jurisdiction,", ",temp.chgpt)
            );

        my.ggplot <- my.ggplot + geom_point(
            data    = DF.plot,
            mapping = aes(x = index, y = change.point),
            alpha   = 0.5,
            size    = 0.5
            );

        my.ggplot <- my.ggplot + xlab('iteration');
        my.ggplot <- my.ggplot + ylab('change point (date index)');

        # my.ggplot <- my.ggplot + scale_x_continuous(
        #     limits = c(0,50),
        #     breaks = seq(0,50,10)
        #     );

        my.ggplot <- my.ggplot + scale_y_continuous(
            limits = c(1,366),
            breaks = seq(1,366,28)
            );

        PNG.output <- ifelse(
            test = remove.stuck.chains,
            yes  = paste0("plot-ChgPt-trace-",jurisdiction,"-",temp.chgpt,"-stuck-chains-removed.png"),
            no   = paste0("plot-ChgPt-trace-",jurisdiction,"-",temp.chgpt,".png")
            );

        ggsave(
            file   = PNG.output,
            plot   = my.ggplot,
            dpi    = 300,
            height =   8,
            width  =  16,
            units  = 'in'
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = paste0(jurisdiction,", ",temp.stepsize)
            );

        my.ggplot <- my.ggplot + geom_point(
            data    = DF.plot,
            mapping = aes(x = index, y = step.size),
            alpha   = 0.5,
            size    = 0.5
            );

        my.ggplot <- my.ggplot + xlab('iteration');
        my.ggplot <- my.ggplot + ylab('step size( natural log )');

        # my.ggplot <- my.ggplot + scale_x_continuous(
        #     limits = c(0,50),
        #     breaks = seq(0,50,10)
        #     );

        my.ggplot <- my.ggplot + scale_y_continuous(
            limits = c(-2,2),
            breaks = seq(-2,2,0.5)
            );

        PNG.output <- ifelse(
            test = remove.stuck.chains,
            yes  = paste0("plot-ChgPt-trace-",jurisdiction,"-",temp.stepsize,"-stuck-chains-removed.png"),
            no   = paste0("plot-ChgPt-trace-",jurisdiction,"-",temp.stepsize,".png")
            );

        ggsave(
            file   = PNG.output,
            plot   = my.ggplot,
            dpi    = 300,
            height =   8,
            width  =  16,
            units  = 'in'
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

        }}

    return( NULL );

    }

plot.density.changepoints <- function(
    list.input          = NULL,
    remove.stuck.chains = FALSE
    ) {

    require(ggplot2);

    jurisdictions <- list.input[["jurisdictions"]];
    change.points <- grep( x = names(list.input[['out']]), pattern = "chgpt[0-9]", value = TRUE);
    step.sizes    <- grep( x = names(list.input[['out']]), pattern = "step[0-9]",  value = TRUE);

    for ( index.jurisdiction in 1:length(jurisdictions) ) {
    for ( index.change.point in 1:length(change.points) ) {

        jurisdiction  <- jurisdictions[index.jurisdiction];
        temp.chgpt    <- change.points[index.change.point];
        temp.stepsize <- step.sizes[   index.change.point];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        vector.chgpt    <- list.input[["out"]][[temp.chgpt   ]][,index.jurisdiction];
        vector.stepsize <- list.input[["out"]][[temp.stepsize]][,index.jurisdiction];

        # if ( remove.stuck.chains ) {
        #     temp.alpha <- temp.alpha[list.input[["is.not.stuck"]][[jurisdiction]]];
        #     temp.beta  <- temp.beta[ list.input[["is.not.stuck"]][[jurisdiction]]];
        #     }

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.plot <- data.frame(
            index        = seq(1,length(vector.chgpt),1),
            change.point = vector.chgpt,
            step.size    = vector.stepsize
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = paste0(jurisdiction,", ",temp.chgpt)
            );

        my.ggplot <- my.ggplot + geom_density(
            data    = DF.plot,
            mapping = aes(x = change.point),
            alpha   = 0.5,
            size    = 0.5
            );

        my.ggplot <- my.ggplot + xlab('change point (date index)');
        my.ggplot <- my.ggplot + ylab('posterior density');

        my.ggplot <- my.ggplot + scale_x_continuous(
            limits = c(1,366),
            breaks = seq(1,366,28)
            );

        # my.ggplot <- my.ggplot + scale_y_continuous(
        #     limits = c(0,50),
        #     breaks = seq(0,50,10)
        #     );

        PNG.output <- ifelse(
            test = remove.stuck.chains,
            yes  = paste0("plot-ChgPt-density-",jurisdiction,"-",temp.chgpt,"-stuck-chains-removed.png"),
            no   = paste0("plot-ChgPt-density-",jurisdiction,"-",temp.chgpt,".png")
            );

        ggsave(
            file   = PNG.output,
            plot   = my.ggplot,
            dpi    = 300,
            height =   8,
            width  =  16,
            units  = 'in'
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = paste0(jurisdiction,", ",temp.stepsize)
            );

        my.ggplot <- my.ggplot + geom_density(
            data    = DF.plot,
            mapping = aes(x = step.size),
            alpha   = 0.5,
            size    = 0.5
            );

        my.ggplot <- my.ggplot + xlab('step size( natural log )');
        my.ggplot <- my.ggplot + ylab('posterior density');

        my.ggplot <- my.ggplot + scale_x_continuous(
            limits = c(-2,2),
            breaks = seq(-2,2,0.5)
            );

        # my.ggplot <- my.ggplot + scale_y_continuous(
        #     limits = c(0,50),
        #     breaks = seq(0,50,10)
        #     );

        PNG.output <- ifelse(
            test = remove.stuck.chains,
            yes  = paste0("plot-ChgPt-density-",jurisdiction,"-",temp.stepsize,"-stuck-chains-removed.png"),
            no   = paste0("plot-ChgPt-density-",jurisdiction,"-",temp.stepsize,".png")
            );

        ggsave(
            file   = PNG.output,
            plot   = my.ggplot,
            dpi    = 300,
            height =   8,
            width  =  16,
            units  = 'in'
            );

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

        }}

    return( NULL );

    }

visualizeModel.change.point_basic <- function(
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
