# Forecasting Tokyo Wholesale Tuna Prices

## 📌 Overview
This project applies **time series forecasting** techniques to analyze and predict the **price of fresh Bluefin Tuna** in the Tokyo wholesale market. The dataset comes from **Kaggle**, and the analysis was performed using **R (fpp3 package)**.

## 📊 Key Features
- **Data Cleaning & Preparation:** Converted raw data into a `tsibble` format.
- **Exploratory Data Analysis (EDA):** Seasonal decomposition (`STL`), trend analysis, and visualization.
- **Forecasting Models Tested:**
  - `ETS` (Error, Trend, Seasonality)
  - `ARIMA` (Auto-Regressive Integrated Moving Average)
  - `TSLM` (Time Series Linear Model with external regressors)
- **Cross-Validation & Model Selection:** Evaluated models using RMSE, MAE, and MAPE.
- **Final Forecast:** Used `auto_ARIMA` to generate 12-month projections.

## 🔍 Dataset
- **Source:** [Kaggle - Tokyo Wholesale Tuna Prices]([https://www.kaggle.com/](https://www.kaggle.com/datasets/tcashion/tokyo-wholesale-tuna-prices))
- **Timeframe:** Monthly data from **2003 to 2017**
- **Variables:**
  - `date`: Year-month format (e.g., `2010 Jan`)
  - `species`: Type of fish (Filtered for `Bluefin Tuna`)
  - `fleet`: Source of the catch (`Japanese Fleet`)
  - `state`: `Fresh` or `Frozen`
  - `measure`: Price per Kg (in Yen)

## 📈 Visualizations
### 1️⃣ **Seasonality & Trends**
- `gg_season()` was originally planned but encountered technical issues after package updates.
- Instead, a custom `ggplot2` seasonal visualization was implemented.

```r
tuna %>%
  mutate(Month = month(date, label = TRUE), Year = year(date)) %>%
  ggplot(aes(x = Month, y = value, group = Year, color = as.factor(Year))) +
  geom_line() +
  labs(y = "Price (Yen per Kg)", title = "Seasonal Plot: Value of Bluefin Tuna") +
  theme_minimal()
