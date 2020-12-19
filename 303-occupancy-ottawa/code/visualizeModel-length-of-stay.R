
visualizeModel.length.of.stay <- function(
    list.input = NULL
    ) {

    thisFunctionName <- "visualizeModel.length.of.stay";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    plot.density.mu.cv(
        list.input          = list.input,
        remove.stuck.chains = FALSE
        );

    plot.trace.mu.cv(
        list.input          = list.input,
        remove.stuck.chains = FALSE
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    plot.density.mu.cv(
        list.input          = list.input,
        remove.stuck.chains = TRUE
        );

    plot.trace.mu.cv(
        list.input          = list.input,
        remove.stuck.chains = TRUE
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    plot.scatter.mu.cv(
        list.input = list.input
        );

    list.plot.admissions <- plot.admissions(
        list.input = list.input
        );

    list.plot.discharges <- plot.expected.discharges(
        list.input = list.input
        );

    list.plot.occupancy <- plot.expected.occupancy(
        list.input = list.input
        );

    plot.cowplot.discharges.occupancy(
        list.plot.admissions = list.plot.admissions,
        list.plot.discharges = list.plot.discharges,
        list.plot.occupancy  = list.plot.occupancy
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( NULL );

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

        PNG.output  <- paste0("plot-LoS-admissions-",jurisdiction,".png");
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

        PNG.output  <- paste0("plot-LoS-expected-cowplot-",jurisdiction,".png");
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

    cat("\nstr(list.input[['posterior.samples']])\n");
    print( str(list.input[['posterior.samples']])   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.plots    <- list();
    jurisdictions <- list.input[["jurisdictions"]];

    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.plot <- list.input[['observed.data']][[jurisdiction]];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        cat("\nstr(list.input[['posterior.samples']][['E_discharges']][,,temp.index])\n");
        print( str(list.input[['posterior.samples']][['E_discharges']][,,temp.index])   );

        cat("\nstr(list.input[['is.not.stuck']][[jurisdiction]])\n");
        print( str(list.input[['is.not.stuck']][[jurisdiction]])   );

        DF.expected.discharges <- list.input[['posterior.samples']][['E_discharges']][,,temp.index];
        DF.expected.discharges <- DF.expected.discharges[list.input[['is.not.stuck']][[jurisdiction]],];

        cat("\nstr(DF.expected.discharges)\n");
        print( str(DF.expected.discharges)   );

        DF.expected.cumulative.discharges <- matrixStats::rowCumsums(x = DF.expected.discharges);

        DF.cumulative.admissions <- base::matrix(
            data  = rep(x = DF.plot[,'cumulative.admissions'], times = nrow(DF.expected.cumulative.discharges)),
            nrow  = nrow(DF.expected.cumulative.discharges),
            byrow = TRUE
            );

        cat("\nstr(DF.cumulative.admissions)\n");
        print( str(DF.cumulative.admissions)   );

        cat("\nstr(DF.expected.cumulative.discharges)\n");
        print( str(DF.expected.cumulative.discharges)   );

        print("A-1");

        DF.expected.occupancy <- DF.cumulative.admissions - DF.expected.cumulative.discharges;

        print("A-2");

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

        PNG.output  <- paste0("plot-LoS-expected-occupancy-",jurisdiction,".png");
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

    cat("\nstr(list.input[['posterior.samples']])\n");
    print( str(list.input[['posterior.samples']])   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.plots    <- list();
    jurisdictions <- list.input[["jurisdictions"]];

    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.plot <- list.input[['observed.data']][[jurisdiction]];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        DF.expected.discharges <- list.input[['posterior.samples']][['E_discharges']][,,temp.index];
        DF.expected.discharges <- DF.expected.discharges[list.input[['is.not.stuck']][[jurisdiction]],];

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

        PNG.output  <- paste0("plot-LoS-expected-discharges-",jurisdiction,".png");
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

plot.trace.mu.cv <- function(
    list.input          = NULL,
    remove.stuck.chains = FALSE
    ) {

    require(ggplot2);

    jurisdictions <- list.input[["jurisdictions"]];
    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        temp.alpha <- list.input[["posterior.samples"]][["alpha"]][,temp.index];
        temp.beta  <- list.input[["posterior.samples"]][["beta" ]][,temp.index];

        if ( remove.stuck.chains ) {
            temp.alpha <- temp.alpha[list.input[["is.not.stuck"]][[jurisdiction]]];
            temp.beta  <- temp.beta[ list.input[["is.not.stuck"]][[jurisdiction]]];
            }

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        cat("\nstr(temp.alpha)\n");
        print( str(temp.alpha)   );

        cat("\ntemp.alpha\n");
        print( temp.alpha   );

        cat("\nstr(temp.beta)\n");
        print( str(temp.beta)   );

        cat("\ntemp.beta\n");
        print( temp.beta   );

        DF.plot <- data.frame(
            index = { if ( length(temp.alpha)>0 ) { seq(1,length(temp.alpha),1) } else { integer(0) } },
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

        PNG.output <- ifelse(
            test = remove.stuck.chains,
            yes  = paste0("plot-LoS-trace-mu-",jurisdiction,"-stuck-chains-removed.png"),
            no   = paste0("plot-LoS-trace-mu-",jurisdiction,".png")
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

        PNG.output <- ifelse(
            test = remove.stuck.chains,
            yes  = paste0("plot-LoS-trace-cv-",jurisdiction,"-stuck-chains-removed.png"),
            no   = paste0("plot-LoS-trace-cv-",jurisdiction,".png")
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

        }

    return( NULL );

    }

plot.density.mu.cv <- function(
    list.input          = NULL,
    remove.stuck.chains = FALSE
    ) {

    require(ggplot2);

    jurisdictions <- list.input[["jurisdictions"]];
    for ( temp.index in 1:length(jurisdictions) ) {

        jurisdiction <- jurisdictions[temp.index];

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
        temp.alpha <- list.input[["posterior.samples"]][["alpha"]][,temp.index];
        temp.beta  <- list.input[["posterior.samples"]][["beta" ]][,temp.index];

        if ( remove.stuck.chains ) {
            temp.alpha <- temp.alpha[list.input[["is.not.stuck"]][[jurisdiction]]];
            temp.beta  <- temp.beta[ list.input[["is.not.stuck"]][[jurisdiction]]];
            }

        ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
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

        PNG.output <- ifelse(
            test = remove.stuck.chains,
            yes  = paste0("plot-LoS-density-mu-",jurisdiction,"-stuck-chains-removed.png"),
            no   = paste0("plot-LoS-density-mu-",jurisdiction,".png")
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

        PNG.output <- ifelse(
            test = remove.stuck.chains,
            yes  = paste0("plot-LoS-density-cv-",jurisdiction,"-stuck-chains-removed.png"),
            no   = paste0("plot-LoS-density-cv-",jurisdiction,".png")
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

        temp.alpha <- list.input[["posterior.samples"]][["alpha"]][,temp.index];
        temp.beta  <- list.input[["posterior.samples"]][["beta" ]][,temp.index];

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
            file   = paste0("plot-LoS-scatter-mu-cv-",jurisdiction,".png"),
            plot   = my.ggplot,
            dpi    = 300,
            height =   8,
            width  =  16,
            units  = 'in'
            );

        }

    return( NULL );

    }
