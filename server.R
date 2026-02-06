library(shiny)

function(input, output, session) {

  # Update Dropdown
  observe({
    active_selection <- input$tickers
    req(active_selection)
    updateSelectInput(session, "focus_asset",
                      choices = active_selection)
    updateSelectInput(session, "benchmark_asset",
                      choices = active_selection)
  })
  
  # Get reactive data
  all_data <- eventReactive(input$run_analysis, {
    req(input$tickers)
    
    fetch_list <- unique(c(input$tickers, input$benchmark_asset))
    data <- get_data(input$tickers, input$dates[1], input$dates[2])
    
    # Check for missing tickers
    returned_tickers <- unique(data$symbol)
    missing_tickers <- setdiff(input$tickers, returned_tickers)
    
    if (length(missing_tickers) > 0) {
      showNotification(
        paste("Warning: Unable to fetch data for", paste(missing_tickers, collapse = ", ")),
        type = "warning",
        duration = 10
      )
    }
    data
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
    
    colnames(cor_matrix) <- clean_ticker_names(colnames(cor_matrix))
    rownames(cor_matrix) <- colnames(cor_matrix)
    
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
      mutate(symbol = clean_ticker_names(symbol)) %>% 
      group_by(symbol) %>%
      filter(!is.na(adjusted)) %>% 
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
      summarise(stdev = sd(daily_return, na.rm = TRUE) * sqrt(252)) %>% # Annualized Vol 
      mutate(symbol = clean_ticker_names(symbol)) 
    
    # Generate Chart
    p <- ggplot(vol_data, aes(x = reorder(symbol, stdev), y = stdev, fill = symbol)) +
      geom_col() +
      coord_flip() +
      theme_tq() +
      labs(title = "Annualized Volatility (Risk Profile)", 
           x = "Asset", y = "Annualized StDev") +
      scale_fill_tq()
    
    ggplotly(p)
  })
  
  # Rolling Correlation Plot
  output$rolling_corr_plot <- renderPlotly({
    req(returns_data(), input$focus_asset, input$benchmark_asset)
    
    available_symbols <- unique(returns_data()$symbol)
    req(input$focus_asset %in% available_symbols)
    req(input$benchmark_asset %in% available_symbols)
    
    # Get Relevant Data
    rolling_data <- returns_data() %>% 
      filter(symbol %in% c(input$focus_asset, input$benchmark_asset)) %>% 
      pivot_wider(names_from = symbol, values_from = daily_return) %>% 
      na.omit()
    
    # Calculate rolling correlation
    res <- rolling_data %>% 
      mutate(
        rolling_corr = TTR::runCor(
          get(input$focus_asset),
          get(input$benchmark_asset),
          n = input$roll_window
        )
      ) %>% 
      na.omit()
    
    # Generate rolling correlation plot
    p <- ggplot(res, aes(x = date, y = rolling_corr)) +
      geom_line(color = "#e67e22", size = 1) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "white", alpha = 0.5) +
      geom_hline(yintercept = 0.5, linetype = "dotted", color = "#77AADD", alpha = 0.5) +
      theme_minimal() +
      theme(
        text = element_text(color = "white"),
        axis.text = element_text(color = "white"),
        panel.grid.major = element_line(color = "#444")) +
      labs(
        title = paste(clean_ticker_names(input$focus_asset), "vs", clean_ticker_names(input$benchmark_asset)),
        subtitle = paste(input$roll_window, "Day Rolling Correlation"),
        y = "Correlation",
        x = "") +
      scale_y_continuous(limits = c(-1,1))
  
    ggplotly(p) %>% 
      layout(paper_bgcolor = 'rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)')
  })
  
  output$corr_summary <- renderTable({
    req(returns_data())
    wide_returns <- returns_data() %>%
      pivot_wider(names_from = symbol, values_from = daily_return) %>%
      select(-date) %>%
      na.omit()
    
    if (ncol(wide_returns) < 1) return(NULL)
    
    cor_res <- cor(wide_returns)
    colnames(cor_res) <- clean_ticker_names(colnames(cor_res))
    rownames(cor_res) <- colnames(cor_res)
    cor_res
  }, rownames = TRUE, striped = TRUE, spacing ='xs')
}
