library(shiny)

# Define server logic required to draw a histogram
function(input, output, session) {

  # Update Dropdown
  observe({
    updateSelectInput(session, "focus_asset",
                      choices = input$tickers[input$tickers != "USO"])
  })
  
  # Get data
  all_data <- eventReactive(input$run_analysis, {
    req(input$tickers)
    get_data(input$tickers, input$dates[1], input$dates[2])
  }, ignoreNULL = FALSE)
  
  # Calculate Returns
  returns_data <- reactive({
    all_data() %>%
      group_by(symbol) %>%
      tq_transmute(
        select = adjusted,
        mutate_fun = periodReturn,
        period = "daily",
        col_rename = "daily_return"
      )
  })
  
  # Correlation Plot
  output$corr_plot <- renderPlot({
    req(returns_data())
    
    wide_returns <- returns_data() %>%
      pivot_wider(names_from = symbol, values_from = daily_return) %>%
      select(-date) %>%
      na.omit()
    
    cor_matrix <- cor(wide_returns)
    
    # Correlation Colouring
    col <- colorRampPalette(c("#BB4444", "#EE9988", "#FFFFFF", "#77AADD", "#4477AA"))
    
    corrplot(cor_matrix, method = "shade", shade.col = NA, 
             tl.col = "black", tl.srt = 45, addCoef.col = "black", 
             cl.pos = "n", order = "hclust", col = col(200))
  })
  
  # Performance Comparison
  output$relative_plot <- renderPlotly({
    req(all_data())
    
    p <- all_data %>%
      group_by(symbol) %>%
      mutate(indexed = (adjusted / first(adjusted)) * 100) %>%
      ggplot(aes(x = date, y = indexed, color = symbol)) +
      geom_line(alpha = 0.8) +
      theme_minimal() +
      labs(title = "Performance Indexed to 100", y = "Index Value", x = "") +
      scale_color_tq()
    
    ggplotly(p)
  })
  
  # Volatility Plot
  output$vol_plot <- renderPlotly({
    req(returns_data())
    
    # Calculate SD of returns
    vol_data <- returns_data() %>%
      summarise(stdev = sd(daily_return, na.rm = TRUE) * sqrt(252)) # Annualized Vol
    
    p <- ggplot(vol_data, aes(x = reorder(symbol, stdev), y = stdev, fill = symbol)) +
      geom_col() +
      coord_flip() +
      theme_tq() +
      labs(title = "Annualized Volatility (Risk Profile)", 
           x = "Asset", y = "Annualized StDev") +
      scale_fill_tq()
    
    ggplotly(p)
  })
  
  output$corr_summary <- renderTable({
  }, striped = TRUE)
}
