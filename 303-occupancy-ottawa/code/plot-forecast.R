
plot.forecast <- function(
    list.input      = NULL,
    forecast.window = 7
    ){

    require(ggplot2)
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

    StanModel                  <- list.input[["StanModel"                 ]];
    dates                      <- list.input[["dates"                     ]];
    jurisdictions              <- list.input[["jurisdictions"             ]];
    prediction                 <- list.input[["prediction"                ]];
    estimated.admissions       <- list.input[["estimated_admissions"      ]];
    out                        <- list.input[["out"                       ]];
    covariates                 <- list.input[["covariates"                ]];
    reported_cases             <- list.input[["reported_cases"            ]];
    admissions_by_jurisdiction <- list.input[["admissions_by_jurisdiction"]];

    max.N2 <- dim(estimated.admissions)[2];

    for( i in 1:length(jurisdictions) ) {

        N            <- length(dates[[i]])
        N2           <- min(N + forecast.window,max.N2)
        jurisdiction <- jurisdictions[[i]]

        predicted_cases    <- colMeans(    prediction[,1:N,i])
        predicted_cases_li <- colQuantiles(prediction[,1:N,i], probs=.025)
        predicted_cases_ui <- colQuantiles(prediction[,1:N,i], probs=.975)

        estimated_admissions    <- colMeans(    estimated.admissions[,1:N,i])
        estimated_admissions_li <- colQuantiles(estimated.admissions[,1:N,i], probs=.025)
        estimated_admissions_ui <- colQuantiles(estimated.admissions[,1:N,i], probs=.975)

        estimated_admissions_forecast    <- colMeans(    estimated.admissions[,1:N2,i])[N:N2]
        estimated_admissions_li_forecast <- colQuantiles(estimated.admissions[,1:N2,i], probs=.025)[N:N2]
        estimated_admissions_ui_forecast <- colQuantiles(estimated.admissions[,1:N2,i], probs=.975)[N:N2]

        rt    <- colMeans(    out$Rt[,1:N,i])
        rt_li <- colQuantiles(out$Rt[,1:N,i],probs=.025)
        rt_ui <- colQuantiles(out$Rt[,1:N,i],probs=.975)

        data_jurisdiction <- data.frame(
            "time"                    = as_date(as.character(dates[[i]])),
            "jurisdiction"            = rep(jurisdiction, length(dates[[i]])),
#           "jurisdiction_population" = rep(jurisdiction_population, length(dates[[i]])),
            "reported_cases"          = reported_cases[[i]],
            "reported_cases_c"        = cumsum(reported_cases[[i]]),
            "predicted_cases_c"       = cumsum(predicted_cases),
            "predicted_min_c"         = cumsum(predicted_cases_li),
            "predicted_max_c"         = cumsum(predicted_cases_ui),
            "predicted_cases"         = predicted_cases,
            "predicted_min"           = predicted_cases_li,
            "predicted_max"           = predicted_cases_ui,
            "admissions"              = admissions_by_jurisdiction[[i]],
            "admissions_c"            = cumsum(admissions_by_jurisdiction[[i]]),
            "estimated_admissions_c"  = cumsum(estimated_admissions),
            "admission_min_c"         = cumsum(estimated_admissions_li),
            "admission_max_c"         = cumsum(estimated_admissions_ui),
            "estimated_admissions"    = estimated_admissions,
            "admission_min"           = estimated_admissions_li,
            "admission_max"           = estimated_admissions_ui,
            "rt"                      = rt,
            "rt_min"                  = rt_li,
            "rt_max"                  = rt_ui
            );

        times <- as_date(as.character(dates[[i]]))
        times_forecast <- times[length(times)] + 0:(N2 - N)
        data_jurisdiction_forecast <- data.frame(
            "time"                          = times_forecast,
            "jurisdiction"                  = rep(jurisdiction,length(estimated_admissions_forecast)),
            "estimated_admissions_forecast" = estimated_admissions_forecast,
            "admission_min_forecast"        = estimated_admissions_li_forecast,
            "admission_max_forecast"        = estimated_admissions_ui_forecast
            );

        plot.forecast_single.plot(
            data_jurisdiction          = data_jurisdiction,
            data_jurisdiction_forecast = data_jurisdiction_forecast,
            StanModel                  = StanModel,
            jurisdiction               = jurisdiction
            );

        }

    return( NULL );

    }

##################################################
plot.forecast_single.plot <- function(
    data_jurisdiction,
    data_jurisdiction_forecast,
    StanModel,
    jurisdiction
    ) {

  data_admissions <- data_jurisdiction %>%
    select(time, admissions, estimated_admissions) %>%
    gather("key" = key, "value" = value, -time)

  data_admissions_forecast <- data_jurisdiction_forecast %>%
    select(time, estimated_admissions_forecast) %>%
    gather("key" = key, "value" = value, -time)

  # Force less than 1 case to zero
  data_admissions$value[data_admissions$value < 1] <- NA
  data_admissions_forecast$value[data_admissions_forecast$value < 1] <- NA
  data_admissions_all <- rbind(data_admissions, data_admissions_forecast)

  p <- ggplot(data_jurisdiction) +
    geom_bar(data = data_jurisdiction, aes(x = time, y = admissions),
             fill = "coral4", stat='identity', alpha=0.5) +
    geom_line(data = data_jurisdiction, aes(x = time, y = estimated_admissions),
              col = "deepskyblue4") +
    geom_line(data = data_jurisdiction_forecast,
              aes(x = time, y = estimated_admissions_forecast),
              col = "black", alpha = 0.5) +
    geom_ribbon(data = data_jurisdiction, aes(x = time,
                                         ymin = admission_min,
                                         ymax = admission_max),
                fill="deepskyblue4", alpha=0.3) +
    geom_ribbon(data = data_jurisdiction_forecast,
                aes(x = time,
                    ymin = admission_min_forecast,
                    ymax = admission_max_forecast),
                fill = "black", alpha=0.35) +
    geom_vline(xintercept = data_admissions$time[length(data_admissions$time)],
               col = "black", linetype = "dashed", alpha = 0.5) +
    #scale_fill_manual(name = "",
    #                 labels = c("Confirmed admissions", "Predicted admissions"),
    #                 values = c("coral4", "deepskyblue4")) +
    xlab("Date") +
    ylab("Daily number of admissions\n") +
    scale_x_date(date_breaks = "weeks", labels = date_format("%Y-%m-%d")) +
    scale_y_continuous(trans='log10', labels=comma) +
    coord_cartesian(ylim = c(1, 100000), expand = FALSE) +
    theme_pubr() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    guides(fill=guide_legend(ncol=1, reverse = TRUE)) +
    annotate(geom="text", x=data_jurisdiction$time[length(data_jurisdiction$time)]+8,
             y=10000, label="Forecast",
             color="black")
  print(p)

  ggsave(
      file = paste0("plot-",StanModel,"-forecast-",jurisdiction,".png"),
      p,
      width = 16
      );

}
#-----------------------------------------------------------------------------------------------
# make_forecast_plot()
