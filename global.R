# Required Packages
library(dplyr)
library(tidyverse)
library(shiny)
library(plotly)
library(tidyquant)
library(corrplot)

# Supported assets list (will expand)
assets <- list(
  "Commodity Futures Prices" = c(
    "WTI Crude Oil" = "CL=F",
    "Natural Gas (Henry Hub)" = "NG=F",
    # "WCS Crude Oil" = "WCS", Will do later
    "Brent Crude Oil" = "BZ=F"
  ),
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
  ),
  "Sector Indexes" = c(
    "Energy Sector ETF" = "XLE"
  )
)

tickers <- unlist(assets, use.names = FALSE)

clean_ticker_names <- function(symbols) {
  case_when(symbols == "CL=F" ~ "WTI", # Fix FRED symbols
            symbols == "NG=F" ~ "NG",
            symbols == "BZ=F" ~ "BRENT",
            
            TRUE ~ gsub("\\.TO$", "", symbols) # Remove ".TO" from Canadian Tickers
  )
}

# Get stock and commodity data 
get_data <- function(tickers, from, to) {
    tq_get(tickers,
           get = "stock.prices",
           from = from, 
           to = to) %>% 
    na.omit() %>% 
    arrange(symbol, date)
}