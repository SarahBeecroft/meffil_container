#Use an R base image
FROM r-base:4.3.1
# Install system dependencies
RUN apt-get update -qq \
      && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
		libcurl4-openssl-dev \
		libssl-dev \
		build-essential \
		libxml2-dev \
		libcairo2-dev \
		libxt-dev \
      && apt-get clean all \
      && rm -r /var/lib/apt/lists/*

# Install CMAKE for nloptr installation 
RUN wget https://github.com/Kitware/CMake/releases/download/v3.24.1/cmake-3.24.1-Linux-x86_64.sh \
      -q -O /tmp/cmake-install.sh \
      && chmod u+x /tmp/cmake-install.sh \
      && mkdir /opt/cmake-3.24.1 \
      && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake-3.24.1 \
      && rm /tmp/cmake-install.sh \
      && ln -s /opt/cmake-3.24.1/bin/* /usr/local/bin

# Install the 'meffil' R package
RUN R -e "install.packages('BiocManager',dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('MASS', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('ggplot2', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('plyr', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('reshape2', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('knitr', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('gridExtra', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('markdown', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('matrixStats', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('multcomp', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('parallel', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('fastICA', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('quadprog', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('betareg', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "BiocManager::install('illuminaio')" && \
R -e "BiocManager::install('limma')" && \
R -e "BiocManager::install('sva')" && \
R -e "BiocManager::install('DNAcopy')" && \
R -e "install.packages('Cairo', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
R -e "install.packages('nloptr', dependencies=TRUE, repos='http://cran.rstudio.com/');   if (!library(nloptr, logical.return=T)) quit(status=10)" && \
R -e "install.packages('lme4', dependencies=TRUE, repos='http://cran.rstudio.com/');  if (!library(lme4, logical.return=T)) quit(status=10)" && \
R -e "BiocManager::install('gdsfmt');  if (!library(gdsfmt, logical.return=T)) quit(status=10)" && \
R -e "BiocManager::install('SmartSVA');  if (!library(gdsfmt, logical.return=T)) quit(status=10)" && \
R -e "BiocManager::install('preprocessCore');  if (!library(gdsfmt, logical.return=T)) quit(status=10)"
# Set the working directory
WORKDIR /app

#Download and manually install meffil
RUN wget https://github.com/perishky/meffil/archive/master.zip && \
      unzip master.zip && \
      mv meffil-master meffil && \
      R CMD INSTALL meffil

# Entry point, you can run your R script or work in an interactive R session
CMD ["R"]
