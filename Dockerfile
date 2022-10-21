FROM rocker/rstudio:4.1.0


RUN \
	apt-get update \
	&& \
	apt-get install -y -q --no-install-recommends \
	libxml2-dev \
	libcairo2-dev \
	libpng-dev \
	libproj-dev \
	libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
	libmagick++-dev \
	imagemagick \
	openjdk-8-jdk \
	texlive-xetex \
	s3cmd \
	neovim \
	zsh \
	&& \
	apt-get clean

RUN \
	R -e "install.packages('rmarkdown', dependencies=NA, repos='http://cran.rstudio.com/')" \
	  && \
	R -e "install.packages('knitr', dependencies=NA, repos='http://cran.rstudio.com/')" \
	  && \
	R -e "install.packages('bookdown', dependencies=NA, repos='http://cran.rstudio.com/')" \
	echo "> Installed markdown R packages"


RUN \
	R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))" \
	  && \
	R -e "remotes::install_github('rstudio/renv@0.13.2')" \
	  && \
	echo "> Installed Renv for managing R package versions"


RUN \
	R -e "install.packages('BiocManager')" \
	  && \
	R -e "BiocManager::install(version = '3.13')"

RUN \
	apt-get update \
	&& \
	apt-get install -y -q --no-install-recommends \
	gsfonts \
	&& \
	apt-get clean


WORKDIR /home/rstudio

RUN \
	git clone https://gitlab.internal.sanger.ac.uk/mirna-and-pirna-project/SmallRNA-in-GCT.git && cd SmallRNA-in-GCT && git checkout master && \
	R -e 'renv::restore(project="rmarkdown", lockfile="rmarkdown/renv.lock", library="rmarkdown/renv/library")' \
	  && \
	echo "> Installed packages specified in Renv lock file"

USER rstudio
RUN mkdir -p /home/rstudio/.config/rstudio/
COPY rstudio-prefs.json /home/rstudio/.config/rstudio/
USER root
RUN chmod 777 /home/rstudio/.config/rstudio/rstudio-prefs.json
