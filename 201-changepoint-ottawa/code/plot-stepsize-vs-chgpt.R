
plot.stepsize.vs.chgpt <- function(
    list.input = NULL
    ) {
  
    require(ggplot2);
    require(tidyr)
    require(dplyr)
    require(rstan)
    require(data.table)
    require(lubridate)
    require(gdata)
    require(EnvStats)
    require(matrixStats)
    require(scales)
    require(gridExtra)
    require(ggpubr)
    require(bayesplot)
    require(cowplot)
 
    for( i in 1:length(jurisdictions) ){

        DF.chgpt1 <- plot.stepsize.vs.chgpt_getData(
            list.input         = list.input,
            jurisdiction.index = i,
            which.chgpt        = "chgpt1",
            which.step         = "step1"
            );
 
        DF.chgpt2 <- plot.stepsize.vs.chgpt_getData(
            list.input         = list.input,
            jurisdiction.index = i,
            which.chgpt        = "chgpt2",
            which.step         = "step2"
            );
 
        DF.jurisdiction <- rbind(
            DF.chgpt1,
            DF.chgpt2
            );

        plot.stepsize.vs.chgpt_make.plots(
            DF.jurisdiction = DF.jurisdiction, 
            StanModel       = list.input[["StanModel"]],
            jurisdiction    = list.input[["jurisdictions"]][[i]],
            min.date        = min(list.input[["dates"]][[i]]),
            max.date        = max(list.input[["dates"]][[i]])
            );
    
        }

    return( NULL );

    }

########################################
plot.stepsize.vs.chgpt_getData <- function(
    list.input         = NULL,
    jurisdiction.index = NULL,
    which.chgpt        = NULL,
    which.step         = NULL
    ) {

    temp.dates <- as.Date(
        x      = list.input[['out']][[which.chgpt]][,jurisdiction.index],
        origin = as.Date(list.input[['dates']][[jurisdiction.index]][1])
        );

    DF.output <- data.frame(
        "jurisdiction" = rep(list.input[["jurisdictions"]][[jurisdiction.index]],nrow(list.input[['out']][[which.chgpt]])),
        "chgpt"        = rep(which.chgpt,nrow(list.input[['out']][[which.chgpt]])),
        "date"         = temp.dates,
        "stepsize"     = list.input[['out']][[which.step ]][,jurisdiction.index]
        );

    return( DF.output );

    }

plot.stepsize.vs.chgpt_make.plots <- function(
    DF.jurisdiction = NULL,
    StanModel       = NULL,
    jurisdiction    = NULL,
    min.date        = NULL,
    max.date        = NULL
    ) {
  
    require(ggplot2);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    my.ggplot <- initializePlot(
        title    = NULL,
        subtitle = jurisdiction
        )

    my.ggplot <- my.ggplot + geom_point(
        data    = DF.jurisdiction,
        mapping = aes(x = date, y = stepsize, colour = chgpt),
        alpha   = 0.3
        ); 

    #my.ggplot <- my.ggplot + scale_x_date(
    #    limits = c(  min.date,max.date),
    #    breaks = seq(min.date,max.date,7)
    #    );

    my.ggplot <- my.ggplot + scale_x_date(
        limits = c(  as.Date("2020-01-05"),as.Date("2020-12-27")),
        breaks = seq(as.Date("2020-01-05"),as.Date("2020-12-27"),14)
        );

    my.ggplot <- my.ggplot + theme(
       axis.text.x = element_text(angle = 45, hjust = 1)
       );

    PNG.output <- paste0("output-",StanModel,"-stepsize-vs-chgpt-",jurisdiction,".png");
    ggsave(
        file   = PNG.output,
        plot   = my.ggplot,
        dpi    = 300,
        height =   8,
        width  =  24,
        units  = 'in'
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

    return( NULL );

    }

