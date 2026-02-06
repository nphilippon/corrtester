library(shiny)

function(input, output, session) {

  # Update Dropdown
  observe({
    updateSelectInput(session, "focus_asset",
                      choices = input$tickers[input$tickers != "USO"])
  })
  
  # Get reactive data
  all_data <- eventReactive(input$run_analysis, {
    req(input$tickers)
    get_data(input$tickers, input$dates[1], input$dates[2])
  }, ignoreNULL = FALSE)
  
  # Calculate Returns
  returns_data <- reactive({
    all_data() %>%
      group_by(symbol) %>%
      filter(!is.na(adjusted)) %>% 
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
    
    colnames(cor_matrix) <- case_when(
      colnames(cor_matrix) == "DCOILWTICO" ~ "WTI OIL",
      colnames(cor_matrix) == "DHHNGSP" ~ "NAT GAS",
      colnames(cor_matrix) == "DCOILBRENTEU" ~ "BRENT",
      TRUE ~ colnames(cor_matrix)
    )
    rownames(cor_matrix) <- colnames(cor_matrix)
    # Correlation Colouring 
    col <- colorRampPalette(c("#BB4444", "#EE9988", "#FFFFFF", "#77AADD", "#4477AA"))
    
    par(bg = "#272b30") # Background Colour
    
    corrplot(cor_matrix, 
             method = "shade",  
             shade.col = NA, 
             tl.col = "white",  # Label Colour
             tl.srt = 45,       # Label Rotation 
             tl.cex = 1.4,      # Label Size
             addCoef.col = "black", # Coefficient Colour
             number.cex = 1.5,  # Coefficient Size
             cl.pos = "n",      # Hide Legend
             order = "hclust",  # Groups Similar
             col = col(200),    # Gradient
             mar = c(0, 0, 2, 0)) # Margins
   })
  
  # Performance Comparison (Stock price indexed to 100)
  output$relative_plot <- renderPlotly({
    req(all_data())
    
    p <- all_data() %>%
      group_by(symbol) %>%
      mutate(indexed = (adjusted / first(adjusted)) * 100) %>%
      ggplot(aes(x = date, y = indexed, color = symbol)) +
      geom_line(alpha = 1) +
      theme_minimal() +
      theme(
        text = element_text(color = "white"),
        axis.text = element_text(color = "white"),
        panel.grid.major = element_line(color = "#444"),
        panel.grid.minor = element_line(color = "#333")
      ) +
      labs(
        title = "Share Price Performance Indexed to 100", 
        y = "Indexed Value", 
        x = "",
        color = "Ticker")
    
    ggplotly(p) %>% 
      layout(paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)')
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
    req(returns_data())
    wide_returns <- returns_data() %>%
      pivot_wider(names_from = symbol, values_from = daily_return) %>%
      select(-date) %>%
      na.omit()
    cor(wide_returns)
  }, rownames = TRUE, striped = TRUE, spacing ='xs')
}
