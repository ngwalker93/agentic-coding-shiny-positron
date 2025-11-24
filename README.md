# ADS 506 - Week 5 Assignment 
# Storytelling with Shiny Apps

This repository contains the code and resources for the Week 5 Assignment of ADS 506, focusing on storytelling with the Shiny web application framework in R.

## Data Source: 
Australian Wine Sales dataset provided in the course module as a CSV file. 
 - AustralianWines.csv

## Objective:
Create an interactive Shiny application that visualizes the Australian Wine Sales data and incorporates data storytelling techniques to communitate insigts. 

## Contents of this Repository:
- `app.R`: The main Shiny application file that contains the UI and server logic.
- `AustralianWines.csv`: The Data file used for analysis and visualization in the Shiny app.
- `ARIMA_24MonthForecast`: Screenshot image showing the ARIMA 24-Month Forecast visualization.
- `StorytellingWithShiny.qmd`: Full R code used to create the Shiny app.
- `Week5_Submission.qmd`: The Quarto file containing the assignment submission.
- `gitignore`: Specifies files and directories to be ignored by Git.
- `README.md`: This file, providing an overview of the project.

## How to Run the Shiny App:
1. Ensure R and RStudio are installed on your machine.
2. Install the required packages:
   ```R
   install.packages(c("shiny", "ggplot2", "dplyr", "forecast"))
   ```
3. Open `app.R` in RStudio.
4. Click the "Run App" button in RStudio to launch the Shiny application.
5. Interact with the app to explore the Australian Wine Sales data and visualizations.

## Highlights:
- Interactive visualizations of Australian wine sales data.
- ARIMA model for 24-month sales forecasting.
- User-friendly interface for data exploration.
- Storytelling elements integrated into the Shiny app to enhance user engagement.