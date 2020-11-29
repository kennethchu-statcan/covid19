
examine.Gamma <- function() {

    thisFunctionName <- "examine.Gamma";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    require(dplyr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    temp.mus <- c(2,10,20,30,40,50);
    temp.cvs <- seq(0.1,0.9,0.2);

    for ( temp.mu in temp.mus ) {
        DF.mu.cv <- expand.grid(mu = temp.mu, cv = temp.cvs);
        my.ggplot <- examine.Gamma_plot.mu.cv(
            DF.mu.cv   = DF.mu.cv,
            subtitle   = paste0("Gamma distribution, mean = ",temp.mu,", cv = ",paste(temp.cvs,collapse=", ")),
            output.csv = paste0("data-Gamma-mu-",temp.mu,".csv"),
            output.png = paste0("plot-Gamma-mu-",temp.mu,".png")
            );
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( NULL );

    }

##################################################
examine.Gamma_plot.mu.cv <- function(
    DF.mu.cv   = NULL,
    subtitle   = NULL,
    output.csv = NULL,
    output.png = NULL
    ) {

    require(ggplot2);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.parameters <- DF.mu.cv;
    DF.parameters[,'alpha'] <- 1 / (DF.parameters[,'cv']^2);
    DF.parameters[,'beta' ] <- DF.parameters[,'alpha'] / DF.parameters[,'mu'];

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( !is.null(output.csv) ) {
        write.csv(
            x         = DF.parameters,
            file      = output.csv,
            row.names = FALSE
            );
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    time.points <- seq(0,100,0.1);
    DF.plot     <- data.frame();
    for ( row.index in 1:nrow(DF.parameters) ) {
        temp.alpha <- DF.parameters[row.index,'alpha'];
        temp.beta  <- DF.parameters[row.index,'beta' ];
        DF.temp <- data.frame(
            alpha        = rep(temp.alpha,length(time.points)),
            beta         = rep(temp.beta, length(time.points)),
            time.point   = time.points,
            prob.density = stats::dgamma(
                x     = time.points,
                shape = temp.alpha,
                rate  = temp.beta
                )
            );
        DF.plot <- rbind(DF.plot,DF.temp);
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.plot[,'alpha.beta'] <- apply(
        X = DF.plot[,c('alpha','beta')],
        MARGIN = 1,
        FUN = function(x) { return( paste(x,collapse="_") ) }
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    # DF.plot[,'colour'] <- "red";
    #
    # is.selected <- (DF.plot[,'shape'] <= 1);
    # DF.plot[is.selected,'colour'] <- "black";
    #
    # is.selected <- (DF.plot[,'shape'] >= 10);
    # DF.plot[is.selected,'colour'] <- "blue";

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = subtitle
        );

    my.ggplot <- my.ggplot + xlab('day');
    my.ggplot <- my.ggplot + ylab('density');

    my.ggplot <- my.ggplot + geom_line(
        data    = DF.plot,
        mapping = aes(x = time.point, y = prob.density, group = alpha.beta),
        alpha   = 0.50,
        size    = 0.75
        );

    if ( !is.null(output.png) ) {
        ggsave(
            file   = output.png,
            plot   = my.ggplot,
            dpi    = 300,
            height =   8,
            width  =  16,
            units  = 'in'
            );
        }

    return( my.ggplot );

    }
