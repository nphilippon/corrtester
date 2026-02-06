library(shiny)
library(shinythemes)

fluidPage(
  theme = shinytheme("slate"),
    
    titlePanel("Energy Equity Sensitivies to Commodities"),

    sidebarLayout(
      sidebarPanel(
        width = 4,
        
        selectizeInput("tickers", "Select Assets:",
                       choices = assets,
                       selected = c("XOM", "CNQ", "XLE", "USO"),
                       multiple = TRUE,
                       options = list(placeholder = 'Select tickers')),
        dateRangeInput("dates", "Time Period:",
                       start = "2015-01-01",
                       end = Sys.Date()),
        
        hr(),
        
        # Weighting UI
        helpText("Select primary asset for rolling corrleations with Oil"),
        selectInput("focus_asset", "Focus Asset:", choices = NULL),
        
        actionButton("run_analysis", "Update Analysis",
                     class = "btn-warning btn-block",
                     style = "color: white; font-weight: bold")
        ),

        # Show a plot of the generated distribution
        mainPanel(
          width = 9,
          tabsetPanel(
            tabPanel("Correlation Matrix",
                     br(),
                     plotOutput("corr_plot"),
                     hr(),
                     tableOutput("corr_summary")),
            tabPanel("Relative Growth",
                     br(),
                     plotlyOutput("relative_plot")),
            tabPanel("Risk & Volatility",
                     br(),
                     plotlyOutput("vol_plot"))
          )
        )
    )
)
