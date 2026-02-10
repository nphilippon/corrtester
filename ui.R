library(shiny)
library(shinythemes)

# Colors
# Light Green: #EBF38B (Section Titles)
# Background: #272b30 (Matches Slate)

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

    /* Narrow dropdowns so it doesn't cover the plot too much */
    .selectize-dropdown{
      width: 320px !important;
      max-width: 320px !important;
      z-index: 2000 !important;
    }
    
    .well {
    background:#2e3338; 
    border:1px solid #444; 
    border-radius:14px; }
    .selectize-dropdown-content{ max-height: 450px !important; }
    
    /* Make auto-balanced weight plug box non-editable */
    .locked-input {
      pointer-events: none;
      opacity: 0.7;
    }
    .locked-input input {
      background-color: #3e444c !important;
      color: #9ca3af !important;
    }
  "))),
  
  
  titlePanel("Energy Equity Sensitivies to Commodities"),
  
  # Global Asset and Date Inputs
  fluidRow(
    column(width = 3,
      wellPanel(
        h4("Asset Selection", style = "color: #EBF38B; margin-top:0;"),
        
        # Equity Selection Dropdown
        selectizeInput("equities", "Select Equities:",
                       choices = equity_list,
                       selected = c("CNQ.TO", "SU.TO"),
                       multiple = TRUE,
                       options = list(
                         hideSelected = FALSE,
                         plugins = list(
                           "remove_button"))),
        
        # Commodity Selection Dropdown
        selectizeInput("commodities", "Select Commodities:",
                       choices = commodity_list,
                       selected = "CL=F",
                       multiple = TRUE,
                       options = list(
                         hideSelected = FALSE,
                         plugins = list(
                           "remove_button"))),
        
        # Index Selection Dropdown
        selectizeInput("indexes", "Select Indexes",
                       choices = index_list,
                       selected = "XEG.TO",
                       multiple = TRUE,
                       options = list(
                         hideSelected = FALSE,
                         plugins = list(
                           "remove_button"))),
        
        # Date Selection
        dateRangeInput("dates", "Time Period:",
          start = "2023-01-01",
          end = Sys.Date()
        ),
        
        hr(),
        
        checkboxInput("show_actual_price", "Show actual price in tooltip", TRUE)
      )
    ),
    # Relative Price Chart
    column(
      width = 9,
      plotlyOutput("relative_plot", height = "450px")
    )
  ),
  
  br(),
  
  # Analytics Tabs
  fluidRow(
    column(width = 12,
           tabsetPanel(
             # Correlation Tab
             tabPanel("Correlation",
                      div(
                        style = "background:#272b30; padding:20px; border:1px solid #444; border-top:none; border-radius:0 0 14px 14px;",
                        fluidRow(
                          column(width = 4,
                                 # Correlation Matrix (left side)
                                 h4("Correlation Heatmap", style = "color: #EBF38B ;"),
                                 # Output Chart
                                 plotOutput("corr_plot", height = "550px"),
                                 br()
                                 ),
                          column(width = 8,
                                 # Rolling Correlation (right side)
                                 h4("Rolling Correlation", style = "color: #EBF38B;"),
                                 div(class = "control-panel",
                                     # Make inputs for focus asset, benchmark asset, and rolling corr window
                                     fluidRow(
                                       column(width = 4,
                                              selectInput("focus_asset", "Focus Asset:", choices = NULL)),
                                       column(width = 4,
                                              selectInput("benchmark_asset", "Benchmark Asset:", choices = NULL)),
                                       column(width = 4,
                                              numericInput("roll_window", "Rolling Correlation Window (days):",
                                                           value = 90,
                                                           min = 10,
                                                           max = 252)) # 252 = approx. trading days in a year
                                       )
                                     ),
                                 # Output Chart
                                 plotlyOutput("rolling_corr_plot", height = "500px")
                                 )
                          )
                        )
                      ),
             # Risk & Volatility Tab
             tabPanel("Risk & Volatility",
                      div(style = "background: #272b30; padding: 20px; border: 1px solid #444; border-top: none;",
                          # Output Chart
                          plotlyOutput("vol_plot", height = "500px")
                          )
                      ),
             # Portfolio Backtesting Tab
             tabPanel("Portfolio Backtesting",
                      div(style = "background: #272b30; padding: 20px; border: 1px solid #444; border-top: none;",
                          fluidRow(
                            # Portfolio Setup Options
                            column(width = 4,
                                   wellPanel(
                                     style = "background:#2e3338; border:1px solid #444;",
                                     h4("Portfolio Allocation", style = "color: #EBF38B;"),
                                     helpText("Assign weights to selected equities (total to 100%)."),
                                     uiOutput("weight_inputs"),
                                     hr(),
                                     actionButton("run_backtest", "Run Backtest", class = "btn-warning btn-block")
                                   )
                            ),
                            # Show Portfolio Chart
                            column(width = 8,
                                   h4("Cumulative Returns vs Benchmarks", style = "color: #EBF38B;"),
                                   plotlyOutput("backtest_plot", height = "500px")
                            )
                          )
                      )
             )
           )
    )
  )
)