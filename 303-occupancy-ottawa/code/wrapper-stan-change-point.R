
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
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output <- wrapper.stan.change.point_patch(
        list.input = list.output,
        DF.input   = DF.input
        );
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat("\nstr(list.output[['out']])\n");
    print( str(list.output[['out']])   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    plot.trace.changepoints(
        list.input          = list.output,
        remove.stuck.chains = FALSE
        );

    plot.density.changepoints(
        list.input          = list.output,
        remove.stuck.chains = FALSE
        );

    plot.cowplot.changepoints(
        list.input          = list.output,
        remove.stuck.chains = FALSE
        );

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

    # if ( !('is.not.stuck' %in% names(list.input)) ) {
    #     jurisdictions   <- unique(DF.input[,'jurisdiction']);
    #     n.jurisdictions <- length(jurisdictions);
    #     is.not.stuck    <- list();
    #     for( temp.index in 1:n.jurisdictions ) {
    #         jurisdiction  <- jurisdictions[temp.index];
    #         temp.0 <- list.input[['extracted.samples']][['alpha']][,temp.index];
    #         temp.1 <- abs(temp.0 - c(NA,temp.0[seq(1,length(temp.0)-1)]));
    #         temp.2 <- abs(temp.0 - c(temp.0[seq(2,length(temp.0))],NA));
    #         temp.3 <- (temp.1 < 1e-6) | (temp.2 < 1e-6);
    #         temp.3[c(1,length(temp.3))] <- FALSE;
    #         is.not.stuck[[jurisdiction]] <- !temp.3;
    #         } # for( jurisdiction in jurisdictions )
    #     list.output[['is.not.stuck']] <- is.not.stuck;
    #     }

    return( list.output );

    }

plot.cowplot.changepoints <- function(
    list.input          = NULL,
    remove.stuck.chains = FALSE
    ) {

    require(ggplot2);
    require(cowplot);

    jurisdictions <- list.input[["jurisdictions"]];
    for ( index.jurisdiction in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[index.jurisdiction];

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

        plot.admissions <- plot.cowplot.changepoints_expected(
            list.input         = list.input,
            index.jurisdiction = index.jurisdiction,
            jurisdiction       = jurisdiction,
            variable.observed  = 'admissions',
            variable.estimated = 'E_admissions',
            plot.subtitle      = 'COVID-19 daily new hospital admissions',
            plot.breaks        = seq(0,100,2),
            textsize.axis      = 27
            );
        plot.admissions <- plot.admissions + theme(axis.text.x = element_blank());

        plot.Rt <- plot.cowplot.changepoints_Rt(
            list.input         = list.input,
            index.jurisdiction = index.jurisdiction,
            jurisdiction       = jurisdiction,
            plot.subtitle      = 'COVID-19 time-varying reproduction number',
            plot.breaks        = seq(0,10,2),
            textsize.axis      = 27
            );
        plot.Rt <- plot.Rt + theme(axis.text.x = element_blank());

        plot.stepsize.vs.chgpt <- plot.cowplot.changepoints_stepsize.vs.chgpt(
            list.input         = list.input,
            index.jurisdiction = index.jurisdiction,
            jurisdiction       = jurisdiction,
            textsize.axis      = 27
            );

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
    DF.estimated.infections <- list.input[['out']][[variable.estimated]][,,index.jurisdiction];
    # DF.estimated.infections <- DF.expected.discharges[list.input[['is.not.stuck']][[jurisdiction]],];

    selected.columns <- seq(1,length(list.input[["dates"]][[jurisdiction]]));
    DF.estimated.infections <- DF.estimated.infections[,selected.columns];

    DF.quantiles <- matrixStats::colQuantiles(
        x     = DF.estimated.infections,
        probs = c(0.025,0.25,0.5,0.75,0.975)
        );
    colnames(DF.quantiles) <- c(
        "percentile.02.5",
        "percentile.25.0",
        "percentile.50.0",
        "percentile.75.0",
        "percentile.97.5"
        );

    DF.quantiles <- cbind(DF.quantiles,date = list.input[['dates']][[jurisdiction]]);

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
        N2 = 360 # Increase this for a further forecast
    }  else  {
        ### For faster runs:
        # jurisdictions <- c("Austria","Belgium") #,Spain")
        N2 = 360
        }

    dates          <- list();
    reported_cases <- list();

    stan_data <- list(
        log_max_step_large = log(4.0),
        log_max_step_small = log(1.5),
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
        minChgPt4          = NULL
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

        decimal.date.EpidemicStart <- index1+1-index2;
        stan_data$EpidemicStart    <- c(stan_data$EpidemicStart,decimal.date.EpidemicStart);

        decimal.date.minChgPt1 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-03-01"))[1],na.rm=TRUE);
        decimal.date.maxChgPt1 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-03-28"))[1],na.rm=TRUE);

        decimal.date.minChgPt2 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-07-05"))[1],na.rm=TRUE);
        decimal.date.maxChgPt2 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-08-01"))[1],na.rm=TRUE);

        decimal.date.minChgPt3 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-09-06"))[1],na.rm=TRUE);
        decimal.date.maxChgPt3 <- max(decimal.date.EpidemicStart,which(d1$date==as.Date("2020-10-03"))[1],na.rm=TRUE);

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
                step1 = runif(length(jurisdictions), min = -stan_data[["log_max_step_large"]], max = 0                                ),
                step2 = runif(length(jurisdictions), min = -stan_data[["log_max_step_small"]], max = stan_data[["log_max_step_small"]]),
                step3 = runif(length(jurisdictions), min = -stan_data[["log_max_step_small"]], max = stan_data[["log_max_step_small"]]),
                step4 = runif(length(jurisdictions), min = -stan_data[["log_max_step_small"]], max = stan_data[["log_max_step_small"]])
              #,step5 = runif(length(jurisdictions), min = -stan_data[["log_max_step_small"]], max = stan_data[["log_max_step_small"]])
                )
            }
        )

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

        fit <- rstan::sampling(
            object = m,
            data   = stan_data,
            iter   = my.iter,     # 20,
            warmup = my.warmup,   # 10,
            chains = my.n.chains  #  2
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

        # fit = rstan::sampling(
        #     object  = m,
        #     data    = stan_data,
        #     iter    = 2000,
        #     warmup  = 1000,
        #     chains  = n.chains,
        #     thin    = 4,
        #     init    = list.init,
        #     control = list(adapt_delta = 0.90, max_treedepth = 10)
        #     );

        fit = rstan::sampling(
            object  = m,
            data    = stan_data,
            iter    = 1000,
            warmup  =  500,
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
        jurisdictions              = jurisdictions,
        observed.data              = observed.data,
        fit                        = fit,
        prediction                 = prediction,
        dates                      = dates,
        reported_cases             = reported_cases,
        admissions_by_jurisdiction = admissions_by_jurisdiction,
        estimated_admissions       = estimated.admissions,
        estimated_admissions_cf    = estimated.admissions.cf,
        out                        = out
        );

    return( list.output );

    }

##################################################
