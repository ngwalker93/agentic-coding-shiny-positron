library(shiny)
library(fpp3)        # meta-package (loads tsibble, fable, feasts, etc.)
library(readr)
library(stringr)
library(dplyr)
library(tidyr)
library(lubridate)
library(tsibble)
library(fable)
library(fabletools)
library(feasts)
library(ggplot2)
library(gt)
if (requireNamespace("urca", quietly = TRUE)) {
  library(urca)
} else {
  message("Package 'urca' is not installed on this server. ARIMA-related functions may behave differently.")
}

# UI
ui <- fluidPage(
  titlePanel("Australian Wine Sales - Storytelling with Shiny"),
  sidebarLayout(
    sidebarPanel(
      selectInput("varietal", "Varietal:", choices = NULL, multiple = FALSE), 
      selectInput("model", "Model:", choices = c("ARIMA", "ETS", "TSLM"), selected = "ARIMA"),
      sliderInput("h", "Forecast horizon (months):", min = 6, max = 24, step = 6, value = 24),
      sliderInput("zoom_years", "Plot window (start year - end year):", min = 1980, max = 1995, value = c(1990, 1995), step = 1),
      actionButton("fit_btn", "Fit models") # add button to trigger fitting
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Forecasts", br(), plotOutput("forecast_plot", height = "500px"), br(), h4("Validation accuracy"), tableOutput("accuracy_table")),
        tabPanel("About", h3("About this app"), 
        p("The data source for this application is the Australian Wine Sales dataset provided in the course module as a CSV file. 
        Although the fpp3 ecosystem includes a similar dataset, this project was developed using the provided CSV file. 
        The assignment requirements guided the modeling choices, which specified the use of TSLM, ETS, and ARIMA models. 
        Each wine variety behaves differently depending on the underlying patterns and trends in the data. Forecasts were 
        generated over a 24-month horizon to provide a sufficient evaluation period to compare each model. To reproduce the 
        figures and results, refer to the full R code provided in StorytellingWithShiny.qmd. The code includes all necessary 
        steps from data loading and wrangling to model fitting, forecasting, evaluation, and visualization."),
        p(tags$em("Note: In the app, 
        a single seasonal ARIMA specification ARIMA(1,0,1)(0,1,1)[12] with drift was used 
        for simplicity, informed by the per-varietal ARIMA models selected during offline analysis.")))
      )
    )
  )
)

server <- function(input, output, session){
  # Load and wrangle data once in server (non-blocking for UI build)
  aus_wine_raw <- reactive({
    req(file.exists("AustralianWines.csv"))
    read_csv("AustralianWines.csv", na = "*", show_col_types = FALSE) |>
      fill(everything(), .direction = "down") |>
      mutate(Month = mdy(str_replace(Month, "-", "-01-")) |> yearmonth())
  })
  aus_wine_ts <- reactive({req(aus_wine_raw())
    aus_wine_raw() |>
      pivot_longer(cols = -Month, names_to = "Varietal", values_to = "Sales") |>
      mutate(Sales = as.numeric(Sales)) |>
      as_tsibble(index = Month, key = Varietal)
})


  # Update UI choices after data is ready
  observeEvent(aus_wine_ts(), {
    vars <- sort(unique(aus_wine_ts()$Varietal))
    updateSelectInput(session, "varietal", choices = c("All varietals" = "ALL", vars), selected = "ALL")
  }, once = TRUE)

  # Filter reactive (uses input$varietal safely after choices are populated)
  filtered_ts <- reactive({
    req(aus_wine_ts(), input$varietal)

    if (input$varietal == "ALL") {
      aus_wine_ts()
    } else {
      aus_wine_ts() |>
        filter(Varietal == input$varietal)
  }
})

  # Use eventReactive to fit models only when user clicks Fit
  fitted_models <- eventReactive(input$fit_btn, {
    trn <- filtered_ts() |> filter(Month <= yearmonth("1993 Dec")) # replace with your train_end logic
    trn |> model(
      ARIMA = ARIMA(Sales),
      ETS   = ETS(Sales),
      TSLM  = TSLM(Sales ~ trend() + season())
    )
  }, ignoreNULL = FALSE)

  # Forecast generation also should be triggered (or use reactive that depends on fitted_models)
  forecasts <- reactive({
    req(fitted_models())
    fitted_models() |> forecast(h = as.integer(input$h)) |> 
      dplyr::filter(.model == input$model)
  })

  # (Keep plotting and accuracy renderers as before but refer to the reactive objects above.)
 output$forecast_plot <- renderPlot({
   fc <- forecasts()
   req(fc, filtered_ts())
   start_ym <- yearmonth(paste0(input$zoom_years[1], " Jan"))
   end_ym   <- yearmonth(paste0(input$zoom_years[2], " Dec"))
   data_zoom <- filtered_ts() |> filter(Month >= start_ym, Month <= end_ym)
   fc_zoom <- fc |> filter(Month >= start_ym, Month <= end_ym)
   req(nrow(fc_zoom) > 0) # ensure there's something to plot
   
   autoplot(fc_zoom, data_zoom) + theme_minimal() + labs(
      title = if (input$varietal == "ALL")
        "Forecasts for All Varietals"
      else
        paste("Forecasts for", input$varietal)
    )
 })

  output$accuracy_table <- renderTable({
    req(fitted_models())
    val <- filtered_ts() |> filter(Month > yearmonth("1993 Dec"))
    acc <- fitted_models() |> forecast(new_data = val) |> accuracy(val) |> select(Varietal, .model, MAPE, RMSE, MAE) |> arrange(MAPE)
    as.data.frame(acc)
  }, digits = 2)
}

shinyApp(ui, server)