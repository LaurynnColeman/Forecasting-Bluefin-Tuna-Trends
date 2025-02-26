library("fpp3")
library("GGally")

#Group 4 - Tammie Beckett, Tom Cerreto, Romontae Thornhill, Laurynn Coleman, Justin Elwell

####DATA CLEANUP####

#Load dataset (from Kaggle)
tuna <- read.csv("tokyo_wholesale_tuna_prices.csv")
View(tuna)

#Creating date column to set up for tsibble
tuna <- tuna %>%
  mutate(date = yearmonth(paste(year, month))) %>%
  select(-year, -month)

tuna


#Convert to tsibble
tuna_ts <- as_tsibble(tuna, key = c(species, state, fleet, measure), index = date)

tuna_ts

#A tsibble with 2016 monthly observations
#Looking specifically at the price of fresh Bluefin Tuna from the Japanese Fleet
bluefin <- tuna_ts %>% 
  filter(species == "Bluefin Tuna", 
         fleet == "Japanese Fleet", 
         state == "Fresh",
         measure == "Price")
#1a. visualize and describe the data
#1b. do appropriate diagnostics/visualizations that lead you to the type of models you try
####QUICK EDA####

#Distribution of Bluefin prices
ggplot(bluefin, aes(x = value)) +
  geom_histogram(binwidth = 500, fill = "steelblue", color = "black") +
  labs(title = "Distribution of Bluefin Tuna Prices (Japanese Fleet)",
       x = "Price (¥ per Kg)",
       y = "Frequency") +
  theme_minimal()

#Monthly price trend
bluefin %>%
  mutate(Month = month(date, label = TRUE)) %>%
  ggplot(aes(x = Month, y = value)) +
  geom_boxplot(fill = "steelblue") +
  labs(title = "Monthly Price Variation of Bluefin Tuna (Japanese Fleet)",
       x = "Month",
       y = "Price (Yen per Kg)") +
  theme_minimal()

####VISUALIZE DATA####
bluefin %>% 
  autoplot(value)+
  labs(y = "Price (Yen per Kg)", 
       title = "Fresh Bluefin Tuna Caught by the Japanese Fleet")

#The data appears to have seasonality and might have stationarity if it wasn't for the seasonality. We need to take a closer look to appropriately describe the data.

#STL decomposition
dcmp <- bluefin %>%
  model(STL(value))

components(dcmp) %>%
  autoplot() +
  labs(x = "Year")

#Starting with a trend window of 12 since the data is monthly and has monthly seasonality.
bluefin %>%
  model(STL(value ~ trend(window=12) + season(window='periodic'),
            robust = TRUE)) %>%
  components() %>%
  autoplot()

#Note that the remainder is not random which confirms that this is multiplicative.

#Visualize the data with gg_season to better visualize the seasonality.
bluefin %>% 
  gg_season(value) +
  labs(y = "Price (Yen per Kg)",
       title = "Seasonal plot: Value of Bluefin Tuna")

####DESCRIBE DATA####
#There is evidence of monthly multiplicative seasonality. The trend is positive from start to finish but difficult to call it linear. There is a severe decline in 2009 that will likely need to be accounted for if we go with a regression model. We are starting to get a better idea, but it is still hard to clearly identify the peak and valley within the monthly seasonality so we needed to take a closer look with ggseason. The seasonal plot reveals a peak in December with a valley in June. It appears the secondary peak is generally in March.


#2. try at least 3 models on training data, and choose at least 2 to assess with cross-validation
####TRAINING DATA####
blue_train <- bluefin %>% 
  filter(row_number() <= n()-24) #this is using all of the data except the last two years

####MODELS####
#We are looking for a medium forecast horizon and our data is non-stationary which eliminates a number of models. 
# Justification for Model Choices:
# - Auto ARIMA: Good for capturing seasonality and trend automatically.
# - TSLM: Includes external variable (recession) and seasonal effects.
# - ETS: Suitable for time series with trend and seasonality.
blue_fit_train <- blue_train %>% 
  mutate(recession = year(date) == 2009) %>% 
  model(auto_ETS = ETS(value),
        auto_ARIMA = ARIMA(value),
        TSLM = TSLM((log(value)) ~ trend() + season() + recession)
  )


blue_fit_train

#ETS is a ANA model. ARIMA is (1,0,0)(2,1,0)[12].

#generate forecasts (forecasting test set)
future_scenario_blue <- scenarios(
  blue_forecast = new_data(blue_train, 24) %>%
    mutate(recession = year(date) == 2009),
  names_to = "Scenario")

#forecasts
blue_train_fc <- forecast(blue_fit_train, new_data = future_scenario_blue) 

bluefin %>%
  autoplot(value) +
  autolayer(blue_train_fc, level = NULL) +
  labs(y = "Price (Yen per Kg)",  
       title = "Forecast on Test Set for Value of Fresh Bluefin Tuna")

accuracy(blue_train_fc, bluefin) %>% 
  arrange(RMSE)

#We chose to proceed with auto_ARIMA and TSLM based on RMSE, MAE and MAPE accuracy measures. 

####CROSS-VALIDATION####
# Blue_cv <- bluefin %>%
#   stretch_tsibble(.init = 60, .step = 3)
# 
# blue_fit_cv <- blue_cv %>%
#   mutate(recession = year(date) == 2009) %>%
#   model(auto_ARIMA = ARIMA(value),
#        TSLM = TSLM((log(value)) ~ trend() + season() + recession)
#   )

#"Warning message:In sqrt(diag(best$var.coef)) : NaNs produced" occurs due to lack of variation among the data. Need to increase.init to increase the variation.

####CROSS-VALIDATION####
blue_cv <- bluefin %>%
  stretch_tsibble(.init = 80, .step = 3)

#With 168 observations in the dataset, we have 30 different training periods tested for cross validation. 

#models
blue_fit_cv <- blue_cv %>%  
  mutate(recession = year(date) == 2009) %>% 
  model(auto_ARIMA = ARIMA(value),
        TSLM = TSLM((log(value)) ~ trend() + season() + recession)
  )

#Forecast ahead and view accuracy measures to choose a model
future_scenario_blue_cv <- scenarios(
  blue_forecast_cv = new_data(blue_cv, 1) %>%
    mutate(recession = year(date) == 2009),
  names_to = "Scenario")

#forecasts
blue_cv_fc <- forecast(blue_fit_cv, new_data = future_scenario_blue_cv) 

accuracy(blue_cv_fc, bluefin) %>% 
  arrange(RMSE)

#auto_ARIMA is the better option by all three accuracy measures. 

#3. choose a final model and justify your choice

####FINAL MODEL####
blue_final_mod <- bluefin %>% 
  model(auto_ARIMA = ARIMA(value))

####ESTIMATE AND EVALUATE####
report(blue_final_mod)

tidy(blue_final_mod)
augment(blue_final_mod)

#All autoregressive terms are statistically significant.

####CHECK RESIDUALS####
blue_final_mod %>% 
  gg_tsresiduals()

#The residuals appear to be homoskedastic and normally distributed. There is one significant autocorrelation at lag 9, but it is not large enough to be a major concern and not in lags 1 or 2.

####FINAL FORECAST####
blue_mod_fc <- blue_final_mod %>%
  forecast(h = 12)

#view of just the final forecast
autoplot(blue_mod_fc) +
  labs(y = "Price (Yen per Kg)",  
       title = "2017 Forecast for Value of Fresh Bluefin Tuna")

bluefin %>% 
  autoplot(value)+
  autolayer(blue_mod_fc, level = NULL) +
  labs(y = "Price (Yen per Kg)",  
       title = "Value of Fresh Bluefin Tuna with Forecast")

#table of prediction intervals for reference
fc_blue_ints <- blue_mod_fc %>%
  hilo() %>%
  unpack_hilo(c(`95%`, `80%`)) ##need to use unpack_hilo

View(fc_blue_ints)


#The End