library(shiny)

function(input, output, session) {
  
  # Combine all asset type tickers
  combined_tickers <- reactive({
    unique(c(input$equities, input$commodities, input$indexes))
  })

  # Update Focus & Benchmark asset dropdowns (in rolling correlation tab)
  observe({
    tickers <- combined_tickers()
    req(tickers)
    
    # Set clean ticker names
    clean_labels <- clean_ticker_names(tickers)
    asset_choices <- setNames(tickers, clean_labels)
    
    # Set Initial Defaults
    current_focus <- input$focus_asset
    current_benchmark <- input$benchmark_asset
    initial_focus <- if (is.null(current_focus) || current_focus == "") "CVE.TO"
    else current_focus
    initial_benchmark <- if (is.null(current_benchmark) || current_benchmark == "") "CL=F"
    else current_benchmark
    
    updateSelectInput(session, "focus_asset",
                      choices = asset_choices, selected = initial_focus)
    updateSelectInput(session, "benchmark_asset",
                      choices = asset_choices, selected = initial_benchmark)
  })
  
  # Get reactive data
  all_data <- reactive({
    tickers_to_get <- combined_tickers()
    req(tickers_to_get, input$dates)
    
    # Get data for selected tickers (every time it is updated)
    data <- get_data(tickers_to_get, input$dates[1], input$dates[2])
    
    # Check for missing tickers and show warning
    returned_tickers <- unique(data$symbol)
    missing_tickers <- setdiff(tickers_to_get, returned_tickers)
    
    if (length(missing_tickers) > 0) {
      showNotification(
        paste("Missing Data for: ", paste(missing_tickers, collapse = ", ")),
        type = "warning",
        duration = 10)
    }
    data
  })
  
  # Calculate Daily Returns
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
    
    # Calculate Periodic Returns (weekly/monthly)
    returns_data_periodic <- reactive({
      all_data() %>%
        group_by(symbol) %>%
        filter(!is.na(adjusted)) %>% 
        tq_transmute(
          select = adjusted,
          mutate_fun = periodReturn,
          period = input$return_freq,
          col_rename = "periodic_return"
        )
  })
  
# Correlation Matrix
  output$corr_plot <- renderPlot({
    req(returns_data())
    
    # Prepare data
    corr_data <- returns_data() %>%
      pivot_wider(names_from = symbol, values_from = daily_return) %>%
      select(-date) %>%
      na.omit()
    
    # Make sure atleast 2 assets selected
    if (ncol(corr_data) < 2)
      return(NULL)
    
    # Make correlation matrix
    cor_matrix <- cor(corr_data)
    
    # Use clean names
    colnames(cor_matrix) <- clean_ticker_names(colnames(cor_matrix))
    rownames(cor_matrix) <- colnames(cor_matrix)
    
    # Correlation Colouring ramp
    col <- colorRampPalette(c("#BB4444", "#EE9988", "#FFFFFF", "#77AADD", "#4477AA"))
    
    par(bg = "#272b30") # Background Colour
    
    corrplot(cor_matrix, 
             method = "shade",  
             shade.col = NA, 
             tl.col = "white",  # Label Colour
             tl.srt = 45,       # Label Rotation 
             tl.cex = 1.2,      # Label Size
             addCoef.col = "black", # Coefficient Colour
             number.cex = 1.5,  # Coefficient Size
             number.digits = 2, # New, decimal points
             cl.pos = "n",      # Hide Legend
             order = "hclust",  # Groups Similar
             col = col(200),    # Gradient
             mar = c(0, 0, 2, 0)) # Margins
   })
  
# Relative Performance Comparison Plot (Stock price indexed to 100)
  output$relative_plot <- renderPlotly({
    req(all_data())
    
    show_actual_price = TRUE
    
    # Prepare data
    p <- all_data() %>%
      mutate(symbol = clean_ticker_names(symbol)) %>% # Use Clean names
      group_by(symbol) %>%
      filter(!is.na(adjusted)) %>%
      mutate(indexed = (adjusted / first(adjusted)) * 100) %>%
      mutate(
        tip = if (isTRUE(show_actual_price)) {
          paste0(
            # Show actual price and indexed value in tooltip
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
      #  Generate Chart
      ggplot(aes(x = date, y = indexed, color = symbol, group = symbol, text = tip)) +  # <-- group fixes missing lines
      geom_line(alpha = 0.8, size = 0.6) +
      theme_minimal() +
      theme(
        text = element_text(color = "white", size = 12),
        axis.text = element_text(color = "white"),
        panel.grid.major = element_line(color = "#444"),
        panel.grid.minor = element_line(color = "#333")
      ) +
      labs(
        y = "Indexed Value",
        x = "",
        color = NULL)
    ggplotly(p, tooltip = "text") %>%
      layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)", 
             # Margins so all charts line up
             legend = list(orientation = "h", x = 0, y = 1.1, font = list(color = "white"), title = list(text = "")),
             margin = list(l = 70, r = 20, t = 10, b = 0)
      )
  })
  
# Volatility Plot
  output$vol_plot <- renderPlotly({
    req(returns_data())
    
    # Prepare data
    vol_data <- returns_data() %>%
      summarise(stdev = sd(daily_return, na.rm = TRUE) * sqrt(252)) %>%
      mutate(symbol = clean_ticker_names(symbol)) # Use clean names
    
    # Generate Chart
    p <- ggplot(vol_data, aes(x = reorder(symbol, stdev), y = stdev, fill = symbol)) +
      geom_col(show.legend = FALSE) +
      coord_flip() +
      theme_minimal() +
      theme(
        text = element_text(color = "white"),
        axis.text = element_text(color = "white"),
        panel.grid.major = element_line(color = "#444"),
        legend.position = "none") +
      labs(
        x = "", 
        y = "Annualized Standard Deviation")
    
    ggplotly(p) %>% 
      layout(showlegend = FALSE, 
             paper_bgcolor = 'rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
             # Margins so all charts line up
             margin = list(l = 70, r = 20, t = 30, b = 0)
      )
  })
  
# Rolling Correlations Chart
  output$rolling_corr_plot <- renderPlotly({
    req(returns_data(), input$focus_asset, input$benchmark_asset)
    
    # Prepare data
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
      )
    
    avg_corr <- mean(res$rolling_corr, na.rm = TRUE)
    
    # Generate Rolling Corr Chart
    p <- ggplot(res, aes(x = date, y = rolling_corr)) +
      geom_line(color = "#e67e22", size = 1) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "white", alpha = 0.5) +
      geom_hline(yintercept = avg_corr, linetype = "dotted", color = "#EBF38B", alpha = 0.8) +
      theme_minimal() +
      theme(
        text = element_text(color = "white"),
        axis.text = element_text(color = "white"),
        panel.grid.major = element_line(color = "#444")) +
      labs(
        title = paste(clean_ticker_names(input$focus_asset), "vs", clean_ticker_names(input$benchmark_asset), "Rolling Correlation Trend"),
        subtitle = paste(input$roll_window, "Day Rolling Correlation"),
        y = "Correlation",
        x = "")
    
    ggplotly(p) %>% 
      layout(paper_bgcolor = 'rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
             margin = list(l = 70, r = 20, t = 30, b = 0)
      )
  })
  
# Return Differential Chart
  output$ret_diff_plot <- renderPlotly({
    req(returns_data_periodic(), input$focus_asset, input$benchmark_asset)
    
    # Prepare Data
    spread_data <- returns_data_periodic() %>% 
      filter(symbol %in% c(input$focus_asset, input$benchmark_asset)) %>% 
      pivot_wider(names_from = symbol, values_from = periodic_return) %>% 
      na.omit() %>% 
      mutate(
        # Calculate Spread
        spread = get(input$focus_asset) - get(input$benchmark_asset))
    
    # Generate Chart
    p <- ggplot(spread_data, aes(x = date, y = spread)) +
      geom_area(fill = "#EBF38B", alpha = 0.3) +
      geom_line(color = "#EBF38B", size = 0.5) +
      geom_hline(yintercept = 0, color= "white", alpha = 0.5) +
      theme_minimal() +
      theme(
        text = element_text(color = "white"), 
        axis.text = element_text(color = "white"), 
        panel.grid.major = element_line(color = "#444")) +
      labs(
        x = "",
        y = "Spread (%)")
    ggplotly(p) %>% 
      layout(paper_bgcolor = 'rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
             # Margins so all charts line up
             margin = list(l = 70, r = 20, t = 30, b = 0)
      )
  })
 

# Portfolio Backtesting (Using Tidyquant Portfolio)
  
  # Portfolio Weights Input
  output$weight_inputs <- renderUI({
    req(input$equities)
    
    tickers <- input$equities
    n <- length(tickers)
    
    # Set Default Weight
    default_weight <- round(100 / length(input$equities), 1)
    
    # Add new weight input box for each selected equity
    tagList(
      lapply(seq_along(tickers), function(i) {
        ticker <- tickers[i]
        label_text <- paste(clean_ticker_names(ticker), "(%)") # Set Clean ticker names
        
        # If equity is the last selected and we have at least 2, lock input (to use as auto balancing plug)
        if(i == n && n > 1) {
          numericInput(paste0("weight_", ticker),
                     label = paste(label_text, "- Auto-Balanced"),
                     value = default_weight, 
                     min = 0, 
                     max = 100) %>% 
            # Add new CSS class to disable interaction
            shiny::tagAppendAttributes(class = "locked-input")
        }
        else {
          # Make weight input boxes for the rest
          numericInput(paste0("weight_", ticker),
                       label = label_text,
                       value = default_weight, 
                       min = 0, 
                       max = 100)
        }
      }))
  })
  
  # Automatic Weight Balancing (Last asset set so total = 100%)
  observe({
    req(input$equities)
    
    # Get # of equities selected
    n <- length(input$equities)
    
    # Make sure at least 2 equities selected
    if (n < 2)
      return()
    
    # Set last selected asset to plug, and the rest as inputs
    last_ticker <- input$equities[n]
    other_tickers <- input$equities[1:(n-1)]
    
    # Calculate sum of inputted weights
    sum_others <- sum(sapply(other_tickers, function(ticker) {
      value <- input[[paste0("weight_", ticker)]]
      # Set blank weights to 0
      if (is.null(value) || is.na(value))
        0
      else
        value
    }))
    
    # Calculate remaining weight
    remaining_weight <- max(0, 100 - sum_others)
    
    # Update/Overwrite last input box value
    updateNumericInput(session, paste0("weight_", last_ticker), value = remaining_weight)
  })

  # Calculate Portfolio Performance
  backtest_results <- eventReactive(input$run_backtest, {
    req(returns_data())
    
    # Filter returns for selected equities
    equity_returns <- returns_data() %>% 
      ungroup() %>% 
      filter(symbol %in% input$equities)
    
    # Check symbols for returns data
    available_tickers <- unique(equity_returns$symbol)
    if (length(available_tickers) == 0)
      return(NULL)
    
    # Get Weights for available equities
    weights <- sapply(input$equities, function(ticker) {
      value <- input[[paste0("weight_", ticker)]]
      if (is.null(value) || is.na(value))
        0
      else
        value
    })
    
    if (sum(weights) == 0) 
      return(NULL)
    
    # Normalize Weights to exactly 1.0
    weights_norm <- weights / sum(weights)
    
    # Setup Tidyquant portfolio
    portfolio_returns <- equity_returns %>% 
      tq_portfolio(
        assets_col = symbol,
        returns_col = daily_return,
        weights = weights_norm,
        col_rename = "investment_return") %>% 
      # Calculate Portfolio Returns
      mutate(cum_return = cumprod(1 + investment_return) * 100,
             type = "User Portfolio",
             category = "Portfolio", # For Chart Legend
             is_benchmark = FALSE) %>% 
      select(date, cum_return, type, category, is_benchmark)
    
    # Prepare Commodity Benchmarks
    comm_bm_returns <- returns_data() %>% 
      ungroup() %>% 
      filter(symbol %in% input$commodities) %>% 
      group_by(symbol) %>% 
      # Calculate Commodity Benchmark Returns
      mutate(cum_return = cumprod(1 + daily_return) * 100,
             type = clean_ticker_names(symbol),
             category = "Commodity Benchmarks", # For Chart Legend
             is_benchmark = TRUE) %>% 
      ungroup() %>% 
      select(date, cum_return, type, category, is_benchmark)
    
    # Prepare Index Benchmarks
    index_bm_returns <- returns_data() %>% 
      ungroup() %>% 
      filter(symbol %in% input$indexes) %>% 
      group_by(symbol) %>% 
      # Calculate Index Benchmark Returns
      mutate(cum_return = cumprod(1 + daily_return) * 100,
             type = clean_ticker_names(symbol),
             category = "Index Benchmarks", # For Chart Legend
             is_benchmark = TRUE) %>% 
      ungroup() %>% 
      select(date, cum_return, type, category, is_benchmark)
      
    # Combine
    res <- bind_rows(portfolio_returns, comm_bm_returns, index_bm_returns)
    
    # Make 'type' into a factor (for legend ordering)
    res$type <- factor(res$type, levels = unique(res$type))
    
    return(res)
  })
  
  # Portfolio Chart
  output$backtest_plot <- renderPlotly({
    req(backtest_results())
    
    # Generate Chart
    p <- ggplot(backtest_results(), aes(
      x = date, y = cum_return, color = type, group = type)) +
      geom_line() +
      theme_minimal() +
      theme(
        text = element_text(color = "white"),
        axis.text = element_text(color = "white"),
        panel.grid.major = element_line(color = "#444")) +
      labs(
        title = "Portfolio Backtesting (Growth of $100)",
        subtitle = "Comparison vs Selected Benchmarks",
        y = "Cumulative Value ($)",
        x = "",
        color = "Legend") +
      scale_color_manual(
        values = c(
          "User Portfolio" = "#EBF38B",
          "WTI" = "#77AADD",
          "NG" = "#EE9988",
          "BRENT" = "#BB4444",
          "XLE" = "#2ECC71",
          "SPY" = "#F1C40F",
          "XEG" = "#9B59B6")
      )
    
    pg <- ggplotly(p)
    
    # Setting up categorized legend (THIS TOOK SO LONG TO GET WORKING I SHOULDNT HAVE EVEN HAD THE IDEA)
    categories_assigned <- c()
    
    # Loops through chart traces to set legend groups and formatting
    for (i in 1:length(pg$x$data)) {
      # Get actual asset name from plotly trace name
      trace_name <- pg$x$data[[i]]$name
      
      # Match trace to category
      trace_info <- backtest_results() %>% 
        filter(type == trace_name) %>% 
        head(1)
      
      # Check to make sure trace has assigned category
      if (nrow(trace_info) > 0) {
        current_category <- trace_info$category
        is_benchmark <- trace_info$is_benchmark
        
        # Set Legend Grouping
        pg$x$data[[i]]$legendgroup <- current_category
        
        # Apply Line Width and Opacity Formatting
        if (is_benchmark) {
          pg$x$data[[i]]$line$width <- 1.5
          pg$x$data[[i]]$opacity <- 0.45
        } else {
          pg$x$data[[i]]$line$width <- 3.5
          pg$x$data[[i]]$opacity <- 1.0
        }
        
        # If first in category, add title
        if (!(current_category %in% categories_assigned)) {
          pg$x$data[[i]]$legendgrouptitle <- list(text = current_category)
          categories_assigned <- c(categories_assigned, current_category)
        }
      }
    }
    
    pg %>% 
      layout(paper_bgcolor = 'rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
             legend = list(
               font = list(color = "white"),
               title = list(text = "") # Remove 'Legend'
             )
      )
  })
}