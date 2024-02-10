FROM rocker/tidyverse:4.3.1

ENV DEBIAN_FRONTEND noninteractive

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libxml2-dev \
    libssh-dev \
    curl

RUN curl -o /tmp/cyphershell.deb 'https://dist.neo4j.org/cypher-shell/cypher-shell_4.2.2_all.deb' && \
    apt-get install -y /tmp/cyphershell.deb && \
    rm -f /tmp/cyphershell.deb

COPY install_packages.R install_packages.R

RUN Rscript --save install_packages.R && \
    rm -rf /usr/local/lib/R/site-library/*/doc

COPY reactome-stats-package /app

CMD ["Rscript", "R/run.R", "--help"]
