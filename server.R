library(shiny)

function(input, output, session) {

  # Update Dropdown
  observe({
    active_selection <- input$tickers
    req(active_selection)
    
    clean_active_selection <- setNames(active_selection, clean_ticker_names(active_selection))
    
    updateSelectInput(session, "focus_asset",
                      choices = clean_active_selection)
    updateSelectInput(session, "benchmark_asset",
                      choices = clean_active_selection)
  })
  
  # Get reactive data
  all_data <- reactive({
    req(input$tickers, input$dates)
    
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
  })
  
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
             number.digits = 2, # New, decimal points
             cl.pos = "n",      # Hide Legend
             order = "hclust",  # Groups Similar
             col = col(200),    # Gradient
             mar = c(0, 0, 2, 0)) # Margins
   })
  
  # Performance Comparison Plot (Stock price indexed to 100)
  output$relative_plot <- renderPlotly({
    req(all_data())
    
    p <- all_data() %>%
      mutate(symbol = clean_ticker_names(symbol)) %>%
      group_by(symbol) %>%
      arrange(date, .by_group = TRUE) %>%         # make sure "first(adjusted)" is the true start
      filter(!is.na(adjusted)) %>%
      mutate(indexed = (adjusted / first(adjusted)) * 100) %>%
      mutate(
        tip = if (isTRUE(input$show_actual_price)) {
          paste0(
            "date: ", date,
            "<br>symbol: ", symbol,
            "<br>index: ", sprintf("%.2f", indexed),
            "<br>price: ", sprintf("%.2f", adjusted)
          )
        } else {
          paste0(
            "date: ", date,
            "<br>symbol: ", symbol,
            "<br>index: ", sprintf("%.2f", indexed)
          )
        }
      ) %>%
      ggplot(aes(x = date, y = indexed, color = symbol, group = symbol, text = tip)) +  # <-- group fixes missing lines
      geom_line(alpha = 1) +
      theme_minimal() +
      theme(
        text = element_text(color = "white"),
        axis.text = element_text(color = "white"),
        panel.grid.major = element_line(color = "#444"),
        panel.grid.minor = element_line(color = "#333")
      ) +
      labs(
        title = "Share Price Performance (Indexed to 100)",
        y = "Indexed Value",
        x = "",
        color = "Ticker"
      )
    
    ggplotly(p, tooltip = "text") %>%
      layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)")
  })
  
  # Volatility Plot
  output$vol_plot <- renderPlotly({
    req(returns_data())
    
    vol_data <- returns_data() %>%
      summarise(stdev = sd(daily_return, na.rm = TRUE) * sqrt(252)) %>%
      mutate(symbol = clean_ticker_names(symbol))
    
    p <- ggplot(vol_data, aes(x = reorder(symbol, stdev), y = stdev, fill = symbol)) +
      geom_col() +
      coord_flip() +
      theme_minimal() +
      theme(
        text = element_text(color = "white"),
        axis.text = element_text(color = "white"),
        panel.grid.major = element_line(color = "#444"),
        legend.position = "none"
      ) +
      labs(
        title = "Annualized Volatility", 
        x = "Asset", 
        y = "Annualized Standard Deviation")
    
    ggplotly(p) %>% 
      layout(showlegend = FALSE,
             paper_bgcolor = 'rgba(0,0,0,0)', 
             plot_bgcolor='rgba(0,0,0,0)')
  })
  
# Rolling Correlations
  
  # Get Rolling Correlation Data
  output$rolling_corr_plot <- renderPlotly({
    req(returns_data(), input$focus_asset, input$benchmark_asset)
    
    available_symbols <- unique(returns_data()$symbol)
    req(input$focus_asset %in% available_symbols)
    req(input$benchmark_asset %in% available_symbols)
    
    rolling_data <- returns_data() %>% 
      filter(symbol %in% c(input$focus_asset, input$benchmark_asset)) %>% 
      pivot_wider(names_from = symbol, values_from = daily_return) %>% 
      na.omit()
    
    req(input$focus_asset %in% colnames(rolling_data))
    req(input$benchmark_asset %in% colnames(rolling_data))
    
    # Calculate Rolling Correlation using TTR::runCor()
    res <- rolling_data %>% 
      mutate(
        rolling_corr = TTR::runCor(
          get(input$focus_asset), 
          get(input$benchmark_asset), 
          n = input$roll_window
        )
      ) %>% 
      na.omit()
    
    # Generate Rolling Corr Chart
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

# Portfolio Backtesting (Using Tidyquant Portfolio)
  
  # Weight Input
  output$weight_inputs <- renderUI({
    req(input$tickers)
    
    # Filtering out commodities and indexes for now but we could put back in
    benchmarks <- c("CL=F", "NG=F", "BZ=F", "XLE")
    equities <- input$tickers[!input$tickers %in% benchmarks]
    
    if (length(equities) == 0)
      return(helpText("Please select at least one equity asset to build a portfolio."))
    
    # Set Default Weight
    default_weight <- round(100 / length(equities), 1)
    
    tagList(
      lapply(equities, function(ticker) {
        # Adds new weight selection box for each selected stock
        numericInput(paste0("weight_", ticker),
                     label = paste(clean_ticker_names(ticker), "(%)"),
                     value = default_weight, min = 0, max = 100)
      })
    )
    
  })
  
 # Calculate Portfolio Performance
  backtest_results <- eventReactive(input$run_backtest, {
    req(returns_data())
    benchmarks <- c("CL=F", "NG=F", "BZ=F", "XLE")
    equities <- input$tickers[!input$tickers %in% benchmarks]
    
    # Get Weights
    weights <- sapply(equities, function(t) input[[paste0("weight_", t)]])
    if (sum(weights) == 0) 
      return(NULL)
    
    # Normalize Weights
    weights_norm <- weights / sum(weights)
    
    # Make portfolio_returns df for tidyquant portfolio
    portfolio_returns <- returns_data() %>% 
      filter(symbol %in% equities) %>% 
      tq_portfolio(
        assets_col = symbol,
        returns_col = daily_return,
        weights = weights_norm,
        col_rename = "investment_return",
        rebalance_on = "quarters"    # Rebalances Monthly (can maybe make this changeable later)
      ) %>% 
      # Calculate Investment Return
      mutate(cum_return = cumprod(1 + investment_return) * 100,
             type = "Custom Portfolio")
    
    # Benchmark against WTI
    wti_returns <- returns_data() %>% 
      filter(symbol == "CL=F") %>% 
      mutate(cum_return = cumprod(1 + daily_return) * 100, type = "WTI Crude Oil")
    
    # Benchmark against XLE Index (if selected)
    xle_returns <- returns_data() %>% 
      filter(symbol == "XLE") %>% 
      mutate(cum_return = cumprod(1 + daily_return) * 100, type = "XLE Energy Index")
    
    # Combine
    bind_rows(
      portfolio_returns %>% 
        select(date, cum_return, type),
      wti_returns %>% 
        select(date, cum_return, type),
      xle_returns %>% 
        select(date, cum_return, type)
    )
  })
  
  # Generate Portfolio Chart
  output$backtest_plot <- renderPlotly({
    req(backtest_results())
    
    p <- ggplot(backtest_results(), aes(x = date, y = cum_return, color = type)) +
      geom_line(size = 1) +
      theme_minimal() +
      theme(
        text = element_text(color = "white"),
        axis.text = element_text(color = "white"),
        panel.grid.major = element_line(color = "#444")) +
      labs(
        title = "Portfolio Backtesting (Growth of $100)",
        subtitle = "Comparison vs WTI & XLE",
        y = "Cumulative Holdings Value ($)",
        x = "") +
      scale_color_manual(
        values = c(
          "Custom Portfolio" = "#EBF38B",
          "WTI Crude Oil" = "#77AADD",
          "XLE Energy Index" = "#e67e22")
        )
    
    ggplotly(p) %>% 
      layout(paper_bgcolor = 'rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)')
  })
}
