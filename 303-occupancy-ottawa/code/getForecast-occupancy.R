
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
