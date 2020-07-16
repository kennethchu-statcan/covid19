
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

    visualizeData.Ottawa_hospitalization(
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
    DF.plot[,"cumsum_case"] <- base::cumsum(DF.plot[,"case"]);

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 case data',
        );

    #my.ggplot <- my.ggplot + geom_line(
    #    data    = DF.plot,
    #    mapping = aes(x = date, y = cumsum_case),
    #    alpha   = 0.80,
    #    size    = 0.75,
    #    colour  = "black"
    #    );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = case),
        alpha   = 0.50,
        size    = 0.75,
        width   = 0.50,
        colour  = "black"
        );

    PNG.output  <- paste0("plot-ottawa-case.png");
    ggsave(
        file   = PNG.output,
        plot   = my.ggplot,
        dpi    = 300,
        height =   8,
        width  =  16,
        units  = 'in'
        );

    return( NULL );

    }

visualizeData.Ottawa_death <- function(
    DF.input = NULL
    ) {

    DF.plot <- DF.input;
    DF.plot[,"cumsum_death"] <- base::cumsum(DF.plot[,"death"]);

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 death data',
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
        mapping = aes(x = date, y = death),
        alpha   = 0.50,
        size    = 0.75,
        width   = 0.50,
        colour  = "black"
        );

    PNG.output  <- paste0("plot-ottawa-death.png");
    ggsave(
        file   = PNG.output,
        plot   = my.ggplot,
        dpi    = 300,
        height =   8,
        width  =  16,
        units  = 'in'
        );

    return( NULL );

    }

visualizeData.Ottawa_hospitalization <- function(
    DF.input = NULL
    ) {

    DF.plot <- DF.input;
    DF.plot[,"cumsum_admission"] <- base::cumsum(DF.plot[,"admission"]);

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 hospitalization data',
        );

    my.ggplot <- my.ggplot + geom_line(
        data    = DF.plot,
        mapping = aes(x = date, y = hospitalized),
        alpha   = 0.80,
        size    = 0.75,
        colour  = "black"
        );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = admission),
        alpha   = 0.50,
        size    = 0.75,
        width   = 0.50,
        colour  = "red"
        );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = -1 * discharge),
        alpha   = 0.50,
        size    = 0.75,
        width   = 0.50,
        colour  = "blue"
        );

    PNG.output  <- paste0("plot-ottawa-hospitalization.png");
    ggsave(
        file   = PNG.output,
        plot   = my.ggplot,
        dpi    = 300,
        height =   8,
        width  =  16,
        units  = 'in'
        );

    my.ggplot <- my.ggplot + geom_line(
        data    = DF.plot,
        mapping = aes(x = date, y = cumsum_admission),
        alpha   = 0.80,
        size    = 0.75,
        colour  = "red"
        );

    PNG.output  <- paste0("plot-ottawa-hospitalization-with-cumsum-admission.png");
    ggsave(
        file   = PNG.output,
        plot   = my.ggplot,
        dpi    = 300,
        height =   8,
        width  =  16,
        units  = 'in'
        );

    return( NULL );

    }

