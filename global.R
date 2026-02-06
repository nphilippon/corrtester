# Required Packages
library(dplyr)
library(tidyverse)
library(shiny)
library(plotly)
library(tidyquant)
library(corrplot)

# Supported assets list (will expand)
assets <- list(
  "Commodity Spot Prices" = c(
    "WTI Crude Oil" = "DCOILWTICO",
    "Natural Gas (Henry Hub)" = "DHHNGSP",
    # "WCS Crude Oil" = "WCS", Will do later
    "Brent Crude Oil" = "DCOILBRENTEU"
  ),
  "Canadian Energy" = c(
    "Canadian National Resources" = "CNQ",
    "Suncor Energy" = "SU",
    "Enbridge Pipelines" = "ENB",
    "TC Energy" = "TRP",
    "Cenovus Energy" = "CVE",
    "Tamarack Valley Energy" = "TVE.TO",
    "Strathcona Resources" = "SCR.TO"
  ),
  "US Energy" = c(
    "Exxon Mobil" = "XOM",
    "Chevron" = "CVX",
    "CononoPhillips" = "COP",
    "Energy Sector ETF" = "XLE"
  )
)

tickers <- unlist(assets, use.names = FALSE)

clean_ticker_names <- function(symbols) {
  case_when(symbols == "DCOILWTICO" ~ "WTI",
            symbols == "DHHNGSP" ~ "NG",
            symbols == "DCOILBRENTEU" ~ "BRENT",
            TRUE ~ symbols
  )
}

# Get stock and commodity (FRED) data 
get_data <- function(tickers, from, to) {
  
  # FRED Tickers here
  fred_codes <- c("DCOILWTICO", "DHHNGSP", "DCOILBRENTEU")
  fred_tickers <- tickers[tickers %in% fred_codes]
  stock_tickers <- tickers[!tickers %in% fred_codes]
  
  stock_data <- tibble()
  commodity_data <- tibble()
  
  # Get Stock Data
  if (length(stock_tickers) > 0) {
    stock_data <- tq_get(stock_tickers,
                         get = "stock.prices",
                         from = from, 
                         to = to)
  }
  
  # Get FRED Data
  if (length(fred_tickers) > 0) {
    commodity_raw <- tq_get(fred_tickers,
                           get = "economic.data",
                           from = from,
                           to = to) %>% 
      na.omit()
    
    if (nrow(commodity_raw) > 0 && "price" %in% colnames(commodity_raw)) {
      commodity_data <- commodity_raw %>% 
        rename(adjusted = price)
    }
  }
  
  bind_rows(stock_data, commodity_data) %>% 
    arrange(symbol, date)
  
}