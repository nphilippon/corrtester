#Dont assign to linux cpu just call it to shiny-verse 
FROM rocker/shiny-verse:latest


#HAVE PACMAN INSTLALL DEPENDENCIES ON SYSTEM
RUN apt-get update && apt-get install -y \ 
  libssl-dev \
  libcurl4-gnutls-dev \ 
  libxml2-dev 
  
#COPY SHINY FILES INTO DOCKER CONTAINMENT
COPY . /srv/shiny-app

#install REQUIRED PACKAGES
RUN Rscript /srv/shiny-app/requirements.R

#create user (dont give everyone root access)
RUN useradd -m shinylover
USER shinylover

#EXPOSE SHINY PORT
EXPOSE 3838

#BASIC HEALTHCHECK TO MAKE SURE SHINY IS ACTUALLY RUNNING PROPERLY
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:3838/ || exit 1

#RUN SHINY APP BYPASS ROCKER R STUDIO AND DIRECTLY GO TO shiny-app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-app', host='0.0.0.0', port=3838)"]
