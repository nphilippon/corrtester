#FORCE TO LINUX CPU + RUN THE R SHINY APP 
FROM --platform=linux/amd64 rocker/shiny-verse:latest


#HAVE PACMAN INSTLALL DEPENDENCIES ON SYSTEM
RUN apt-get update && apt-get install -y \ 
  libssl-dev \
  libcur4-gnutls-dev \ 
  libxml2-dev 
  
#COPY SHINY FILES INTO DOCKER CONTAINMENT
COPY . /srv/shiny-app

#install REQUIRED PACKAGES
RUN Rscript /srv/shiny-app/requirements.R

#create user
RUN useradd -m shinylover
USER shinylover

#EXPOSE SHINY PORT
EXPOSE 3838

#RUN SHINY APP BYPASS ROCKER R STUDIO AND DIRECTLY GO TO shiny-app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-app', host='0.0.0.0', port=3838)"]
