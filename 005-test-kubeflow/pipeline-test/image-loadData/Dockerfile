FROM amd64/r-base:latest

RUN apt-get       update
RUN apt-get --yes upgrade

RUN apt-get --yes install wget
RUN apt-get --yes install jq

RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc && \
    chmod +x mc && \
    mv mc /usr/bin/

RUN R -e 'install.packages(c("gdata", "EnvStats", "ggplot2", "tidyr", "dplyr", "rstan", "data.table", "lubridate", "gdata", "matrixStats", "scales", "gridExtra", "ggpubr", "bayesplot", "cowplot", "readr"))'

COPY data    /data
COPY src     /src
COPY main.sh /main.sh

ENTRYPOINT ["/main.sh"]

