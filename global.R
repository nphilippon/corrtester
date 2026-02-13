# Required Packages
library(dplyr)
library(tidyverse)
library(shiny)
library(plotly)
library(tidyquant)
library(corrplot)

# Supported Equities
equity_list <- list(
  "Canadian Large-Cap E&Ps" = c(
    "Canadian National Resources" = "CNQ.TO",
    "Suncor Energy" = "SU.TO",
    "Imperial Oil" = "IMO.TO",
    "Cenovus Energy" = "CVE.TO",
    "Tourmaline Oil" = "TOU.TO",
    "Whitecap Resources" = "WCP.TO",
    "ARC Resources" = "ARX.TO"
  ),
  "Canadian Intermediate E&Ps" = c(
    "Strathcona Resources" = "SCR.TO",
    "Peyto Expl & Dev." = "PEY.TO",
    "Tamarack Valley Energy" = "TVE.TO",
    "Athabasca Oil" = "ATH.TO",
    "Paramount Resources" = "POU.TO",
    "NuVista Energy" = "NVA.TO",
    "Baytex Energy" = "BTE.TO",
    "International Petroleum" = "IPCO.TO",
    "Headwater Exploration" = "HWX.TO",
    "Vermilion Energy" = "VET.TO",
    "Birchcliff Energy" = "BIR.TO",
    "Parex Resources" = "PXT.TO",
    "Spartan Delta Expl." = "SDE.TO"
  ),
  "Canadian Junior E&Ps" = c(
    "Advantage Energy" = "AAV.TO",
    "Kelt Exploration" = "KEL.TO",
    "Cardinal Energy" = "CJ.TO",
    "Greenfire Resources" = "GFR.TO",
    "Surge Energy" = "SGY.TO",
    "Obsidian Energy" = "OBE.TO",
    "Saturn Oil & Gas" = "SOIL.TO",
    "Pine Cliff Energy" = "PNE.TO",
    "Rubellite Energy" = "RBY.TO",
    "Gran Tierra Energy" = "GTE.TO",
    "Journey Energy" = "JOY.TO",
    "Bonterra Energy" = "BNE.TO",
    "Yangarra Resources" = "YGR.TO",
    "Lycos Energy" = "LCX.TO"
  ), 
  "Canadian Royalties" = c(
    "PrairieSky Royalty" = "PSK.TO",
    "Topaz Energy" = "TPZ.TO",
    "Freehold Royalties" = "FRU.TO"
  ),
  "Canadian Infrastructure" = c(
    "Enbridge Pipelines" = "ENB.TO",
    "TC Energy" = "TRP.TO",
    "Pembina Pipeline" = "PPL.TO",
    "AltaGas Ltd" = "ALA.TO",
    "Keyera Corp" = "KEY.TO",
    "South Bow Corp" = "SOBO.TO",
    "Gibson Energy" = "GEI.TO"
  ),
  "US Energy" = c(
    "Exxon Mobil" = "XOM",
    "Chevron" = "CVX",
    "CononoPhillips" = "COP",
    "EOG Resources" = "EOG",
    "Devon Energy" = "DVN",
    "Diamondback Energy" = "FANG",
    "EQT Corp" = "EQT",
    "Coterra Energy" = "CTRA",
    "Ovintiv" = "OVV",
    "Antero Resources" = "AR",
    "APA Corp" = "APA"
  )
)

# Supported Commodities
commodity_list <- list(
  "Commodity Futures (Forward Month)" = c(
    "WTI Crude Oil" = "CL=F",
    "Natural Gas (Henry Hub)" = "NG=F",
    # "WCS Crude Oil" = "WCS", WIP
    "Brent Crude Oil" = "BZ=F"
  )
)

# Supported Indexes
index_list <- list(
  "Sector & Market Indexes" = c(
    "US Energy Sector (XLE)" = "XLE",
    "Canadian Energy Sector (XEG)" = "XEG.TO",
    "S&P 500" = "SPY",
    "Russel 2000" = "RUT"
  )
)


# Helper func for cleaning commodity & .TO ticker names
clean_ticker_names <- function(symbols) {
  case_when(symbols == "CL=F" ~ "WTI", # Fix Commodity Names
            symbols == "NG=F" ~ "NG",
            symbols == "BZ=F" ~ "BRENT",
            
            TRUE ~ gsub("\\.TO$", "", symbols) # Remove ".TO" from Canadian Tickers
  )
}

# Get data
get_data <- function(tickers, from, to) {
    tq_get(tickers,
           get = "stock.prices",
           from = from, 
           to = to) %>% 
    arrange(symbol, date)
}