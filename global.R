# Required Packages
library(dplyr)
library(tidyverse)
library(shiny)
library(plotly)
library(tidyquant)
library(corrplot)

# Supported assets list (will expand)
assets <- list(
  "Commodity Benchmarks" = c(
    "WTI Crude Oil (USO)" = "USO"
  ),
  "Canadian Energy" = c(
    "Canadian National Resources" = "CNQ",
    "Suncor Energy" = "SU",
    "Enbridge Pipelines" = "ENB",
    "TC Energy" = "TRP",
    "Cenovus Energy" = "CVE"
  ),
  "US Energy" = c(
    "Exxon Mobil" = "XOM",
    "Chevron" = "CVX",
    "CononoPhillips" = "COP",
    "Energy Sector ETF" = "XLE"
  )
)

tickers <- unlist(assets, use.names = FALSE)

# Get tidyquant stock data 
get_data <- function(tickers, from, to) {
  tq_get(tickers,
         get = "stock.prices",
         from = from,
         to = to)
}