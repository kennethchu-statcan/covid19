FROM continuumio/miniconda3

RUN apt-get update \
    && apt-get --yes install wget jq git \
    && rm -rf /var/lib/apt/lists/*

# Default environment
RUN conda install --quiet --yes \
      -c conda-forge \
      "r-bayesplot" \
      "r-cowplot" \
      "r-data.table" \
      "r-dplyr" \
      "r-EnvStats" \
      "r-gdata" \
      "r-gdata"\
      "r-ggplot2" \
      "r-ggpubr" \
      "r-gridExtra" \
      "r-lubridate" \
      "r-matrixStats" \
      "r-readr" \
      "r-rstan" \
      "r-scales" \
      "r-tidyr" \
      "r-jsonlite" \
    && conda clean --all -f -y

#RUN git clone --depth=1 \
#      https://github.com/kennethchu-statcan/covid19/ \
#      /tmp/covid19 \
#    && mv /tmp/covid19/005-test-kubeflow/pipeline-test/image-loadData/src /src \
#    && rm -rf /tmp/covid19

COPY src     /src

COPY main.sh /main.sh

ENTRYPOINT ["/main.sh"]

