# Forecasting Tokyo Wholesale Tuna Prices

## Overview
This project applies time series forecasting techniques to analyze and predict the price of fresh Bluefin Tuna in the Tokyo wholesale market.

## Key Features
- **Data Cleaning & Preparation:** Converted raw data into a `tsibble` format.
- **Exploratory Data Analysis (EDA):** Seasonal decomposition (`STL`), trend analysis, and visualization.
- **Forecasting Models Tested:**
  - `ETS` (Error, Trend, Seasonality)
  - `ARIMA` (Auto-Regressive Integrated Moving Average)
  - `TSLM` (Time Series Linear Model with external regressors)
- **Cross-Validation & Model Selection:** Evaluated models using RMSE, MAE, and MAPE.
- **Final Forecast:** Used `auto_ARIMA` to generate 12-month projections.

## Dataset
- **Source:** [Kaggle - Tokyo Wholesale Tuna Prices](https://www.kaggle.com/datasets/tcashion/tokyo-wholesale-tuna-prices)
- **Timeframe:** Monthly data from **2003 to 2017**
- **Variables:**
  - `date`: Year-month format (e.g., `2010 Jan`)
  - `species`: Type of fish (Filtered for `Bluefin Tuna`)
  - `fleet`: Source of the catch (`Japanese Fleet`)
  - `state`: `Fresh` or `Frozen`
  - `measure`: Price per Kg (in Yen)

![Project Overview Slide](images/bluefin%20ppt%20screenshot.png)

For a detailed walkthrough of the analysis, view the full presentation:
[View the full presentation here](Final%20Bluefin%20Forecast%20Presentation.pdf)

### If you have suggestions for enhancing the code or the project overall, please feel free to open an issue or submit a pull request. Your contributions are greatly appreciated!
