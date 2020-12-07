
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
    DF.input      = NULL,
    textsize.axis = 13
    ) {

    DF.plot <- DF.input;
    DF.plot[,"cumsum_case"] <- base::cumsum(DF.plot[,"new.cases"]);

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 daily new confirmed case counts'
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

    my.ggplot <- my.ggplot + scale_x_date(date_breaks = "2 weeks");
    my.ggplot <- my.ggplot + theme(
        axis.text.x = element_text(size = textsize.axis, face = "bold", angle = 90, vjust = 0.5)
        );

    my.ggplot <- my.ggplot + xlab("");
    my.ggplot <- my.ggplot + ylab("");

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
    DF.input      = NULL,
    textsize.axis = 13
    ) {

    DF.plot <- DF.input;
    # DF.plot[,"cumsum_death"] <- base::cumsum(DF.plot[,"cumulative.deaths"]);

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 daily cumulative death counts'
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
#       width   = 0.50,
        fill    = "black",
        colour  = NA
        );

    my.ggplot <- my.ggplot + scale_x_date(date_breaks = "2 weeks");
    my.ggplot <- my.ggplot + theme(
        axis.text.x = element_text(size = textsize.axis, face = "bold", angle = 90, vjust = 0.5)
        );

    my.ggplot <- my.ggplot + xlab("");
    my.ggplot <- my.ggplot + ylab("");

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
    DF.input      = NULL,
    textsize.axis = 20
    ) {

    DF.plot <- DF.input;
    DF.plot[,"cumsum_admission"] <- base::cumsum(DF.plot[,"new.hospital.admissions"]);

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 daily new hospital admission counts'
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
    DF.input      = NULL,
    textsize.axis = 20
    ) {

    DF.plot <- DF.input;

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 daily hospital midnight census counts'
        );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = occupancy.hospital),
        alpha   = 0.50,
        size    = 0.75,
        fill    = "black",
        colour  = NA
        );

    my.ggplot <- my.ggplot + scale_x_date(date_breaks = "2 weeks");
    my.ggplot <- my.ggplot + theme(
        axis.text.x = element_text(size = textsize.axis, face = "bold", angle = 90, vjust = 0.5)
        );

    my.ggplot <- my.ggplot + xlab("");
    my.ggplot <- my.ggplot + ylab("");

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
    DF.input      = NULL,
    textsize.axis = 20
    ) {

    DF.plot <- DF.input;

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 daily ICU midnight census counts'
        );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = occupancy.icu),
        alpha   = 0.50,
        size    = 0.75,
        fill    = "black",
        colour  = NA
        );

    my.ggplot <- my.ggplot + scale_x_date(date_breaks = "2 weeks");
    my.ggplot <- my.ggplot + theme(
        axis.text.x = element_text(size = textsize.axis, face = "bold", angle = 90, vjust = 0.5)
        );

    my.ggplot <- my.ggplot + xlab("");
    my.ggplot <- my.ggplot + ylab("");

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

visualizeData.Ottawa_cumulative.hospital.admissions <- function(
    DF.input      = NULL,
    textsize.axis = 20
    ) {

    DF.plot <- DF.input;

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 cumulative hospital admissions'
        );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = cumulative.hospital.admissions),
        alpha   = 0.50,
        size    = 0.75,
#       width   = 0.50,
        fill    = "orange",
        colour  = NA
        );

    my.ggplot <- my.ggplot + scale_x_date(date_breaks = "2 weeks");
    my.ggplot <- my.ggplot + theme(
        axis.text.x = element_text(size = textsize.axis, face = "bold", angle = 90, vjust = 0.5)
        );

    my.ggplot <- my.ggplot + xlab("");
    my.ggplot <- my.ggplot + ylab("");

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

visualizeData.Ottawa_cumulative.discharges <- function(
    DF.input      = NULL,
    textsize.axis = 20
    ) {

    DF.plot <- DF.input;

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 cumulative discharges'
        );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = cumulative.discharges),
        alpha   = 0.50,
        size    = 0.75,
#       width   = 0.50,
        fill    = "orange",
        colour  = NA
        );

    my.ggplot <- my.ggplot + scale_x_date(date_breaks = "2 weeks");
    my.ggplot <- my.ggplot + theme(
        axis.text.x = element_text(size = textsize.axis, face = "bold", angle = 90, vjust = 0.5)
        );

    my.ggplot <- my.ggplot + xlab("");
    my.ggplot <- my.ggplot + ylab("");

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

visualizeData.Ottawa_daily.discharges <- function(
    DF.input      = NULL,
    textsize.axis = 20
    ) {

    DF.plot <- DF.input;

    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Ottawa COVID-19 daily hospital discharges'
        );

    my.ggplot <- my.ggplot + geom_col(
        data    = DF.plot,
        mapping = aes(x = date, y = daily.discharges),
        alpha   = 0.50,
        size    = 0.75,
        fill    = "orange",
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
