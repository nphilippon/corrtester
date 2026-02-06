library(shiny)
library(shinythemes)

fluidPage(
  theme = shinytheme("slate"),
  
  # --- minimal CSS: clearer select box + narrower dropdown ---
  tags$head(tags$style(HTML("
    body { background:#272b30; }

    /* Make selectize input readable (white bg + dark text) */
    .selectize-control .selectize-input{
      background:#fff !important;
      color:#111827 !important;
      border:1px solid #cbd5e1 !important;
    }
    .selectize-control .selectize-input input{ color:#111827 !important; }

    /* Narrow dropdown so it doesn't cover the plot too much */
    .selectize-dropdown{
      width: 320px !important;
      max-width: 320px !important;
      z-index: 2000 !important;
    }
    .selectize-dropdown-content{ max-height: 320px !important; }
  "))),
  
  
  titlePanel("Energy Equity Sensitivies to Commodities"),
  
  # Global Asset and Date Inputs
  fluidRow(
    column(width = 3,
      wellPanel(
        style = "background:#2e3338; border:1px solid #444; border-radius:14px;",
        
        selectizeInput(
          "tickers", "Select Assets:",
          choices = assets,
          selected = c("CVX", "CNQ.TO", "CL=F"),
          multiple = TRUE,
          options  = list(
            placeholder = "Select assets",
            plugins = list("remove_button"),
            hideSelected = FALSE,
            closeAfterSelect = FALSE
          )
        ),
        
        dateRangeInput(
          "dates", "Time Period:",
          start = "2020-01-01",
          end = Sys.Date()
        ),
        
        checkboxInput("show_actual_price", "Show actual price in tooltip", TRUE),
        
        hr()
      )
    ),
    # Relative Price Chart
    column(
      width = 9,
      plotlyOutput("relative_plot", height = "400px")
    )
  ),
  
  br(),
  
  # Analytics Tabs
  fluidRow(
    column(
      width = 12,
      tabsetPanel(
        tabPanel(
          "Correlation",
          div(
            style = "background:#272b30; padding:20px; border:1px solid #444; border-top:none; border-radius:0 0 14px 14px;",
            fluidRow(
              # Correlation Matrix
              column(width = 4, 
                     h4("Correlation Heatmap", style = "color: #e67e22;"), 
                     plotOutput("corr_plot", height = "550px"),
                     br(),
              ),
              
              # Rolling Correlation
              column(width = 8, 
                     h4("Rolling Correlation", style = "color: #e67e22;"),
                     div(class = "control-panel",
                         fluidRow(
                           column(width = 4,
                                  selectInput("focus_asset", "Focus Asset:", choices = NULL)),
                           column(width = 4,
                                  selectInput("benchmark_asset", "Benchmark Asset:", choices = NULL)),
                           column(width = 4,
                                  numericInput("roll_window", "Rolling Correlation Window (days):", 
                                               value = 60,
                                               min = 10,
                                               max = 252))
                           )
                         ),
                     plotlyOutput("rolling_corr_plot", height = "500px")
              )
            )
          )
        ),
        tabPanel("Risk & Volatility", 
                 div(style = "background: #272b30; padding: 20px; border: 1px solid #444; border-top: none;",
                  plotlyOutput("vol_plot", height = "500px")
                 )
        )
      )
      )
    )
  )
