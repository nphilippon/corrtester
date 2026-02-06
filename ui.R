library(shiny)
library(shinythemes)

fluidPage(
  theme = shinytheme("slate"),
    
  titlePanel("Energy Equity Sensitivies to Commodities"),

  fluidRow(
    column(width = 3,
      wellPanel(
        style = "background: #2e3338; border: 1px solid #444;",
        selectizeInput("tickers", "Select Assets:",
                       choices = assets,
                       selected = c("CVX", "CNQ.TO", "CL=F"),
                       multiple = TRUE,
                       options = list(placeholder = 'Select tickers')),
        
        dateRangeInput("dates", "Time Period:",
                       start = "2023-01-01",
                       end = Sys.Date()),
        
        hr(),
          
        # Weighting UI - WIP
        helpText("Select primary asset for rolling corrleations with Oil (WIP)"),
        selectInput("focus_asset", "Focus Asset:", choices = NULL),
          
        actionButton("run_analysis", "Update Analysis",
                     class = "btn-warning btn-block",
                     style = "color: white; font-weight: bold")
      )
    ),
    
    column(width = 9,
           div(
             plotlyOutput("relative_plot", height = "400px")
           )
    )
  ),
    
  br(),
    
  fluidRow(
    column(width = 12,
           tabsetPanel(
               tabPanel("Correlation Matrix",
                        div(style = "background: #272b30; padding: 20px; border: 1px solid #444; border-top: none;",
                            fluidRow(
                              # Show Matrix
                              column(width = 7,
                                     h4("Correlation Heatmap", style = "color = #e67e22;"),
                                     plotOutput("corr_plot", height = "550px")
                              ),
                              # Show Table
                              column(width = 5,
                                     h4("Correlation Coefficients", style = "color = #e67e22;"),
                                     div(class = "table-container",
                                         tableOutput("corr_summary")
                                     ),
                                     br()
                              )
                            )
                        )
               ),
               tabPanel("Risk & Volatility",
                        br(),
                        plotlyOutput("vol_plot", height = "500px")
               )
           )
    )
  )
)