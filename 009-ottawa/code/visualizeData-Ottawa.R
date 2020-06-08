
visualizeData.Ottawa <- function(
    DF.input = NULL
    ) {

    thisFunctionName <- "visualizeData.Ottawa";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(ggplot2);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    visualizeData.Ottawa_by.date(
        DF.input = DF.input
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( NULL );

    }

##################################################
visualizeData.Ottawa_by.date <- function(
    DF.input = NULL
    ) {

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 hospitalization data',
        );

    my.ggplot <- my.ggplot + geom_line(
        data    = DF.input,
        mapping = aes(x = date, y = hospitalized),
        alpha   = 0.80,
        size    = 0.75,
        colour  = "black"
        );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.input,
        mapping = aes(x = date, y = admission),
        alpha   = 0.50,
        size    = 0.75,
        width   = 0.50,
        colour  = "red"
        );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.input,
        mapping = aes(x = date, y = -1 * discharge),
        alpha   = 0.50,
        size    = 0.75,
        width   = 0.50,
        colour  = "black"
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

    return( NULL );

    }

