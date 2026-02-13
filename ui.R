

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
    /* Formatting for stacked charts */
    .chart-label { 
      color: #EBF38B; font-weight: bold; 
      margin-bottom: 5px; margin-top: 15px; 
      text-transform: uppercase; 
      font-size: 1.8rem; letter-spacing: 1px; }
    
    /* Formatting for header */
    .app-header {
      padding: 10px 0;
      border-bottom: 2px solid #EBF38B;
      margin-bottom: 10px;}
    .app-title { 
      margin: 0; 
      font-weight: 700; 
      color: #f8fafc; }
    .app-subtitle { 
      margin: 5px 0 0 0; 
      color: #94a3b8; 
      font-size: 1.1rem; }
      /* Stats Summary notes box */
.stats-notes {
  color: #ffffff;
  background: rgba(0,0,0,0.15);
  border: 1px solid rgba(255,255,255,0.08);
  padding: 12px 14px;
  border-radius: 10px;
  margin-bottom: 12px;
}
.stats-notes h4 {
  margin: 0 0 6px 0;
  color: #EBF38B;
}
.stats-notes p, .stats-notes li {
  font-size: 13px;
  line-height: 1.35;
}
      
      
  "))),
  
  
  # Header
  div(class = "app-header",
      h2(class = "app-title", "Energy Sector Correlation Dashboard"),
      p(class = "app-subtitle", "Correlation Analysis between Energy Equities, Commodities, and Indexes")
  ),
  
  # Global Asset and Date Inputs
  fluidRow(
    column(width = 3,
           wellPanel(
             h4("Asset Selection", style = "color: #EBF38B; margin-top:0;"),
             
             # Equity Selection Dropdown
             selectizeInput("equities", "Select Equities:",
                            choices = equity_list,
                            selected = c("CVE.TO", "SU.TO"),
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
             
             hr(style = "border-color: #444;"),
             
             # Rolling Correlation Controls
             h4("Rolling Correlation Analysis", style = "color: #EBF38B;"),
             selectInput("focus_asset", "Target Asset:", choices = NULL),
             selectInput("benchmark_asset", "Benchmark:", choices = NULL),
             numericInput("roll_window", "Rolling Correlation Window (days):", value = 90, min = 5),
             hr(style = "border-color: #444;"),
             
             # Return Differential Controls
             h4("Return Differential Analysis", style = "color: #EBF38B;"),
             selectInput("return_freq", "Return Frequency:",
                         choices = c("Daily" = "daily", "Weekly" = "weekly", "Monthly" = "monthly"),
                         selected = "weekly"),
             
             hr(style = "border-color: #444;")
           )
    ),
    
    # Relative Price Chart
    column(width = 9,
           div(class = "chart-label", "Relative Performance (Indexed to 100)"),
           plotlyOutput("relative_plot", height = "350px"),
           
           div(class = "chart-label", "Rolling Correlation Trend"),
           plotlyOutput("rolling_corr_plot", height = "250px"),
           
           div(class = "chart-label", "Return Differential"),
           plotlyOutput("ret_diff_plot", height = "250px"),
    )
  ),
  
  br(),
  
  # Analytics Tabs
  fluidRow(
    column(
      width = 12,
      tabsetPanel(
        tabPanel(
          "Correlations & Volatility",
          div(
            style = "background:#272b30; padding:20px; border:1px solid #444; border-top:none;",
            fluidRow(
              column(
                width = 6,
                h4("Correlation Heatmap", style = "color: #EBF38B;"),
                plotOutput("corr_plot", height = "500px")
              ),
              column(
                width = 6,
                h4("Annnualized Volatility", style = "color: #EBF38B;"),
                plotlyOutput("vol_plot", height = "500px")
              )
            )
          )
        ),
        
        tabPanel(
          "Portfolio Backtesting",
          div(
            style = "background: #272b30; padding: 20px; border: 1px solid #444; border-top: none;",
            fluidRow(
              column(
                width = 4,
                wellPanel(
                  style = "background:#2e3338; border:1px solid #444;",
                  h4("Portfolio Allocation", style = "color: #EBF38B;"),
                  helpText("Assign weights to selected equities (total to 100%)."),
                  uiOutput("weight_inputs"),
                  hr(),
                  actionButton("run_backtest", "Run Backtest", class = "btn-warning btn-block")
                )
              ),
              column(
                width = 8,
                h4("Cumulative Returns vs Benchmarks", style = "color: #EBF38B;"),
                plotlyOutput("backtest_plot", height = "500px")
              )
            )
          )
        ),
        
        tabPanel(
          "Stats Summary",
          div(
            style = "background:#272b30; padding:20px; border:1px solid #444; border-top:none;",
            
            h4("Daily Return Summary Statistics", style = "color: #EBF38B;"),
            
            fluidRow(
              column(
                width = 4,
                selectInput(
                  "beta_benchmark",
                  "Beta benchmark (market proxy):",
                  choices = c("SPY" = "SPY", "XEG.TO" = "XEG.TO", "CL=F" = "CL=F"),
                  selected = "SPY"
                )
              ),
              column(
                width = 8,
                tags$div(
                  class = "stats-notes",
                  tags$p(style = "margin:0;", textOutput("beta_note"))
                )
              )
            ),
            
            tags$div(
              class = "stats-notes",
              tags$p("Metrics computed from daily returns over the selected date range."),
              tags$ul(
                tags$li(tags$b("SD (Daily):"), " Standard deviation of daily returns."),
                tags$li(tags$b("Ann Return:"), " Annualized mean return using 252 trading days."),
                tags$li(tags$b("Ann Vol:"), " Annualized volatility = SD(daily) × √252."),
                tags$li(tags$b("Sharpe:"), " Annualized Sharpe ratio using Rf = 0."),
                tags$li(tags$b("Beta:"), " Cov(asset, benchmark) / Var(benchmark) using overlapping daily returns."),
                tags$li(tags$b("Skew / Kurtosis:"), " Return distribution shape (kurtosis > 3 implies fat tails)."),
                tags$li(tags$b("Min/Max Price:"), " Min and max adjusted price over the selected range.")
              )
            ),
            
            div(
              style = "overflow-x:auto;",
              gt::gt_output("stats_table")
            )
          )
        )
      )
    )
  )
)