---
editor_options: 
  markdown: 
    wrap: 72
---

#CorrTester - Shiny Correlation Analysis App

##Application Overview

Corrtester is a Shiny app built to be used as a tool for analyzing
correlations between equities, commodities, and indexes in the energy
sector. The app uses a multi file structure, and is containerized with
docker .

\*\* [Fill this section in I made a basic template feel free to make it
however you want tho!]

CorrTester allows the user to select assets and view correlation relationships
and trends. Supported assets include Canadian and US Energy companies,
commodities futures prices, and key sector indexes. 

Main Features
- Relative Share Price Performance
- Rolling correlations between two assets
- Daily, Weekly, or Monthly Return Differentials between two assets 

Extra Features
- Correlation Matrix between multiple assets
- Annualized Volatility Comparison
- Portfolio Back-testing to implement trading strategies 


------------------------------------------------------------------------

# Deployment

## 1. Containerizing the App

The shiny app has been containerized with Docker and is readily
available for pulling via DockerHub as it follows concistnecy with
enterprise normalitities. Image is built on the 'rocker/shiny' image
instead of the 'rocker/rstudio' one as this project should pull directly
into the shiny app instead of RStudio.

By containering the app it had to ensure the following: - All required
packages are included via requirements.R file - No instance of a local R
installation is required - Reproducible deployment on all machines to
have consistency

### Building Image Locally

In the case that you are interested on developing this app further
consult the following bellow on instructions with local building.

Building Locally

``` terminal
docker build -t corrtester .
```

Running Locally

``` terminal
docker run -p 3838:3838 corrtester
```

Then Navigate to the following website: <http://localhost:3838>

## 2. Automated Github Deployment Pipeline to DockerHub

Github actions workflow is setup so when someone pushes to the GitHub it
automatically builds and pushes the image to DockerHub.

This pipeline includes the following:

-   Uses docker actions which include checkout, buildx, login all with
    their most recent versions
-   Authenticates DockerHub via Secrets including login username and
    secret credential
-   Has cache set up so it doesn't waste time building the entire app
    every time its loaded
-   Pushes image automatically to Docker if it builds succesfully

## 3. Multi CPU Support

Docker image pulling supports both CPU's - Makes it so the image works
on both macbooks and standard machines - linux/arm64 and linux/amd64

## 4. Image Versioning

The most recent build pushed to DockerHub is tagged with the following:
- latest
- ${{ github.run_number }} , which serves it purpose as giving version numbers starting from 1

## 5. Health Monitoring

HEALTCHECK is included in the dockerfile to make sure the Shiny app is responsive.
In the case that the Shiny app is not responding it will be marked as:
```terminal
unhealthy
```
This prepares the container for bigger projects such as Kubernetes where many containers can be used.

## 6. Cloud Deployment Ready!

With the container being fully containerized and automated to DockerHub it should be ready to be deployed to various cloud platforms such as:
- AWS
- Azure
- Google

No new code will need to be added here as it should just fit in properly.

## 7. Running the Published Image

In order to run the most recent version of the image do the following:

  ```bash
  docker pull cainaidoo/corrtester:latest
  docker run -p 3838:3838 cainaidoo/corrtester:latest
  ```

Then go to the following website:
http://localhost:3838

### Running a specific version of the code
Alternatively if you wanted to visit a former version of it you need to use the number tag, follow the steps below:

```terminal
docker pull cainaidoo/corrtester:<version_number>
docker run -p 3838:3838 cainaidoo/corrtester:<version_number>
```
An example if I wanted to see the 4th version of it pushed to DockerHub I would do the following:

```terminal
docker pull cainaidoo/corrtester:4
docker run -p 3838:3838 cainaidoo/corrtester:4
```

##Depolment Workflow Overview
