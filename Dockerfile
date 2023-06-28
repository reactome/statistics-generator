FROM rocker/tidyverse:4.3.1

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install libssl-dev -y
RUN apt-get install libcurl4-openssl-dev -y
RUN apt-get install libfontconfig1-dev -y
RUN apt-get install libxml2-dev -y
RUN apt-get install libssh-dev -y
RUN apt-get install curl -y

RUN curl -o /tmp/cyphershell.deb 'https://dist.neo4j.org/cypher-shell/cypher-shell_4.2.2_all.deb'
RUN apt-get install /tmp/cyphershell.deb -y 
RUN rm -f /tmp/cyphershell.deb

COPY install_packages.R install_packages.R

RUN Rscript --save install_packages.R

COPY . . 

CMD ["Rscript", "reactome_release_stats.R", "--help"]
