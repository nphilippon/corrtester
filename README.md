# CorrTester - Shiny Correlation Analysis App

## Application Overview

Corrtester is a Shiny app built to be used as a tool for analyzing
correlations between equities, commodities, and indexes in the energy
sector. The app uses a multi file structure, and is containerized with
docker .

CorrTester allows the user to select assets and view correlation relationships
and trends. Supported assets include Canadian and US Energy companies,
commodities futures prices, and key sector indexes. 

Main Features:
- Relative Share Price Performance
- Rolling correlations between two assets
- Daily, Weekly, or Monthly Return Differentials between two assets 

Extra Features:
- Correlation Matrix between multiple assets
- Annualized Volatility Comparison
- Portfolio Back-testing to implement trading strategies 


------------------------------------------------------------------------

# Deployment

## Containerizing the App

The shiny app has been containerized with Docker and is readily
available for pulling via DockerHub.

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

## Automated Github Deployment Pipeline to DockerHub

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

### Running the published image via Dockerhub

In order to run the most recent version of the image do the following:

  ```bash
  docker pull cainaidoo/corrtester:latest
  docker run -p 3838:3838 cainaidoo/corrtester:latest
  ```

Then go to the following website:
- http://localhost:3838

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

## Additional info about deployment

The container supports the following features:
- Multi CPU support (Runs on both AMD and ARM CPUS)
- Image versions via tagging (`latest` and `${{github.run_number}}`)
- Health monitoring to ensure shiny app is responsive via `HEALTHCHECK`
- Cloud deployment ready without additional code (Via AWS, Azure, Google)


