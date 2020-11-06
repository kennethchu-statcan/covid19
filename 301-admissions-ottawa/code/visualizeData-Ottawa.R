
visualizeData.Ottawa <- function(
    DF.input = NULL
    ) {

    thisFunctionName <- "visualizeData.Ottawa";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(ggplot2);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    visualizeData.Ottawa_case(
        DF.input = DF.input
        );

    visualizeData.Ottawa_death(
        DF.input = DF.input
        );

    visualizeData.Ottawa_hospital.admission(
        DF.input = DF.input
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( NULL );

    }

##################################################
visualizeData.Ottawa_case <- function(
    DF.input = NULL
    ) {

    DF.plot <- DF.input;
    DF.plot[,"cumsum_case"] <- base::cumsum(DF.plot[,"new.cases"]);

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 case count'
        );

    my.ggplot <- my.ggplot + geom_col(
       data    = DF.plot,
       mapping = aes(x = date, y = new.cases),
       alpha   = 0.50,
       size    = 0.75,
       fill    = "black",
       colour  = NA
       );

    # my.ggplot <- my.ggplot + geom_col(
    #     data    = DF.plot,
    #     mapping = aes(x = date, y = case),
    #     alpha   = 0.50,
    #     size    = 0.75,
    #     width   = 0.50,
    #     colour  = "black"
    #     );

    # PNG.output  <- paste0("plot-ottawa-case.png");
    # ggsave(
    #     file   = PNG.output,
    #     plot   = my.ggplot,
    #     dpi    = 300,
    #     height =   8,
    #     width  =  16,
    #     units  = 'in'
    #     );

    return( my.ggplot );

    }

visualizeData.Ottawa_death <- function(
    DF.input = NULL
    ) {

    DF.plot <- DF.input;
    # DF.plot[,"cumsum_death"] <- base::cumsum(DF.plot[,"cumulative.deaths"]);

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 death count'
        );

    #my.ggplot <- my.ggplot + geom_line(
    #    data    = DF.plot,
    #    mapping = aes(x = date, y = cumsum_death),
    #    alpha   = 0.80,
    #    size    = 0.75,
    #    colour  = "black"
    #    );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = cumulative.deaths),
        alpha   = 0.50,
        size    = 0.75,
        width   = 0.50,
        colour  = "black"
        );

    # PNG.output  <- paste0("plot-ottawa-death.png");
    # ggsave(
    #     file   = PNG.output,
    #     plot   = my.ggplot,
    #     dpi    = 300,
    #     height =   8,
    #     width  =  16,
    #     units  = 'in'
    #     );

    return( my.ggplot );

    }

visualizeData.Ottawa_hospital.admission <- function(
    DF.input = NULL
    ) {

    DF.plot <- DF.input;
    DF.plot[,"cumsum_admission"] <- base::cumsum(DF.plot[,"new.hospital.admissions"]);

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 hospital admission'
        );

    # my.ggplot <- my.ggplot + geom_line(
    #     data    = DF.plot,
    #     mapping = aes(x = date, y = hospitalized),
    #     alpha   = 0.80,
    #     size    = 0.75,
    #     colour  = "black"
    #     );
    #
    # my.ggplot <- my.ggplot + geom_col(
    #     data    = DF.plot,
    #     mapping = aes(x = date, y = admission),
    #     alpha   = 0.50,
    #     size    = 0.75,
    #     width   = 0.50,
    #     colour  = "red"
    #     );
    #
    # my.ggplot <- my.ggplot + geom_col(
    #     data    = DF.plot,
    #     mapping = aes(x = date, y = -1 * discharge),
    #     alpha   = 0.50,
    #     size    = 0.75,
    #     width   = 0.50,
    #     colour  = "blue"
    #     );

    # PNG.output  <- paste0("plot-ottawa-hospitalization.png");
    # ggsave(
    #     file   = PNG.output,
    #     plot   = my.ggplot,
    #     dpi    = 300,
    #     height =   8,
    #     width  =  16,
    #     units  = 'in'
    #     );

    # my.ggplot <- my.ggplot + geom_line(
    #     data    = DF.plot,
    #     mapping = aes(x = date, y = cumsum_admission),
    #     alpha   = 0.80,
    #     size    = 0.75,
    #     colour  = "red"
    #     );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = new.hospital.admissions),
        alpha   = 0.50,
        size    = 0.75,
        fill    = "black",
        colour  = NA
        );

    # PNG.output  <- paste0("plot-ottawa-hospital-admission.png");
    # ggsave(
    #     file   = PNG.output,
    #     plot   = my.ggplot,
    #     dpi    = 300,
    #     height =   8,
    #     width  =  16,
    #     units  = 'in'
    #     );

    return( my.ggplot );

    }

visualizeData.Ottawa_occupancy.hospital <- function(
    DF.input = NULL
    ) {

    DF.plot <- DF.input;

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 hospital occupancy'
        );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = occupancy.hospital),
        alpha   = 0.50,
        size    = 0.75,
        fill    = "black",
        colour  = NA
        );

    # PNG.output  <- paste0("plot-ottawa-hospital-occupancy.png");
    # ggsave(
    #     file   = PNG.output,
    #     plot   = my.ggplot,
    #     dpi    = 300,
    #     height =   8,
    #     width  =  16,
    #     units  = 'in'
    #     );

    return( my.ggplot );

    }

visualizeData.Ottawa_occupancy.icu <- function(
    DF.input = NULL
    ) {

    DF.plot <- DF.input;

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 ICU occupancy'
        );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = occupancy.icu),
        alpha   = 0.50,
        size    = 0.75,
        fill    = "black",
        colour  = NA
        );

    # PNG.output  <- paste0("plot-ottawa-hospital-occupancy.png");
    # ggsave(
    #     file   = PNG.output,
    #     plot   = my.ggplot,
    #     dpi    = 300,
    #     height =   8,
    #     width  =  16,
    #     units  = 'in'
    #     );

    return( my.ggplot );

    }
