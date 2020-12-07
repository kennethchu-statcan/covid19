
examine.Weibull <- function(
    output.csv = "data-weibull.csv"
    ) {

    thisFunctionName <- "examine.Weibull";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    require(dplyr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    examine.Weibull_get.table(output.csv = output.csv);
    examine.Weibull_plot.fixed.scale();
    examine.Weibull_plot.fixed.shapes();

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( NULL );

    }

##################################################
examine.Weibull_plot.fixed.scale <- function(fixed.scale = 1) {

    require(ggplot2);

    shapes <- c(
        0.1,
        seq(0.2,1,0.2),
        seq(2,8,2),
        seq(10,50,10)
        );

    time.points <- seq(0,2.5,0.01);
    DF.plot     <- data.frame();
    for ( temp.shape in shapes ) {
        DF.temp <- data.frame(
            shape        = rep(temp.shape,length(time.points)),
            time.point   = time.points,
            prob.density = stats::dweibull(
                x     = time.points,
                shape = temp.shape,
                scale = fixed.scale
                )
            );
        DF.plot <- rbind(DF.plot,DF.temp);
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.plot[,'colour'] <- "red";

    is.selected <- (DF.plot[,'shape'] <= 1);
    DF.plot[is.selected,'colour'] <- "black";

    is.selected <- (DF.plot[,'shape'] >= 10);
    DF.plot[is.selected,'colour'] <- "blue";

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Weibull distributions PDF, scale = 1'
        );

    my.ggplot <- my.ggplot + xlab('day');
    my.ggplot <- my.ggplot + ylab('density');

    my.ggplot <- my.ggplot + geom_line(
        data    = DF.plot,
        mapping = aes(x = time.point, y = prob.density, group = shape),
        alpha   = 0.50,
        size    = 0.75,
        colour  = DF.plot[,'colour']
        );

    PNG.output  <- paste0("plot-weibull-PDF-scale-",fixed.scale,".png");
    ggsave(
        file   = PNG.output,
        plot   = my.ggplot,
        dpi    = 300,
        height =   8,
        width  =  16,
        units  = 'in'
        );

    }

examine.Weibull_plot.fixed.shapes <- function() {

    require(ggplot2);
    require(RColorBrewer);

    shapes <- 2; # c(1.5,2,10);
    scales <- c(1,2,3,4,5,6);

    time.points <- seq(0,50,0.1);
    DF.plot     <- data.frame();
    for ( temp.shape in shapes ) {
    for ( temp.scale in scales ) {
        DF.temp <- data.frame(
            shape        = rep(temp.shape,length(time.points)),
            scale        = rep(temp.scale,length(time.points)),
            time.point   = time.points,
            prob.density = stats::dweibull(
                x     = time.points,
                shape = temp.shape,
                scale = temp.scale
                )
            );
        DF.plot <- rbind(DF.plot,DF.temp);
        }}

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.plot[,'shape.scale'] <- apply(
        X      = DF.plot[,c('shape','scale')],
        MARGIN = 1,
        FUN    = function(x) {
            return(paste(x,collapse = "_"));
            }
        );

    cat("\nhead(x = DF.plot, n = 100)\n");
    print( head(x = DF.plot, n = 100)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    length.shapes <- length(shapes);
    my.palette <- RColorBrewer::brewer.pal(n = length.shapes, name = "Set2");

    DF.plot[,'colour'] <- character(length.shapes);
    for ( temp.index in 1:length.shapes ) {
        is.selected <- (DF.plot[,'shape'] == shapes[temp.index]);
        DF.plot[is.selected,'colour'] <- my.palette[temp.index];
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = 'Weibull distributions PDF'
        );

    my.ggplot <- my.ggplot + xlab('day');
    my.ggplot <- my.ggplot + ylab('density');

    my.ggplot <- my.ggplot + geom_line(
        data    = DF.plot,
        mapping = aes(x = time.point, y = prob.density, group = shape.scale),
        alpha   = 0.50,
        size    = 0.75,
        colour  = DF.plot[,'colour']
        );

    PNG.output  <- paste0("plot-weibull-PDF-fixed-shapes.png");
    ggsave(
        file   = PNG.output,
        plot   = my.ggplot,
        dpi    = 300,
        height =   8,
        width  =  16,
        units  = 'in'
        );

    }

examine.Weibull_get.table <- function(
    output.csv = NULL
    ) {

    alphas <- seq(0.1,50,0.1);
    sigmas <- c(1); # seq(0.1,50,0.1);

    DF.output <- expand.grid(
        alpha = alphas,
        sigma = sigmas
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output[,'mean'] <- DF.output[,'sigma'] * gamma(1 + 1 / DF.output[,'alpha']);

    DF.output[,'mode'] <- apply(
        X      = DF.output[,c('alpha','sigma')],
        MARGIN = 1,
        FUN    = function(x) {
            if (x[1] > 1) {
                return( x[2] * ( ((x[1]-1)/x[1])^(1/x[1]) )  );
            } else {
                return( 0 );
                }
            }
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output[,'pcntl.25'] <- stats::qweibull(
        p     = 0.25,
        shape = DF.output[,'alpha'],
        scale = DF.output[,'sigma']
        );

    DF.output[,'pcntl.50'] <- stats::qweibull(
        p     = 0.50,
        shape = DF.output[,'alpha'],
        scale = DF.output[,'sigma']
        );

    DF.output[,'pcntl.75'] <- stats::qweibull(
        p     = 0.75,
        shape = DF.output[,'alpha'],
        scale = DF.output[,'sigma']
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    write.csv(
        x         = DF.output,
        file      = output.csv,
        row.names = FALSE
        );

    }
