
visualize.estimates <- function(
    list.input = NULL
    ) {

    thisFunctionName <- "visualize.estimates";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    visualize.estimates_alpha(
        DF.input = list.input[["alpha"]]
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( NULL );

    }

###################################################
visualize.estimates_alpha <- function(
    DF.input = NULL
    ) {

    require(ggplot2);

    temp.covariates <- unique(DF.input[,"covariate"]);
    for ( temp.covariate in temp.covariates ) {

        DF.temp <- DF.input[DF.input[,"covariate"] == temp.covariate,];
        cat("\nDF.temp\n");
        print( DF.temp   );

        my.ggplot <- initializePlot(
            title    = NULL,
            subtitle = gsub(x=temp.covariate,pattern="\\.",replacement=" ")
            );

        my.ggplot <- my.ggplot + scale_x_continuous(limits=c(-0.05,1.05),breaks=seq(0,1,0.1));

        my.ggplot <- my.ggplot + geom_histogram(
            data    = DF.temp,
            mapping = aes(x = posterior.mean),
            #size    = 0.2,
            alpha   = 0.3
            );

        temp.string <- gsub(x=temp.covariate,pattern="\\.",replacement="-");
        PNG.output  <- paste0("plot-alpha-",temp.string,".png");
        ggsave(
            file   = PNG.output,
            plot   = my.ggplot,
            dpi    = 300,
            height =   8,
            width  =  10,
            units  = 'in'
            );

        }

    return( NULL );

    }

