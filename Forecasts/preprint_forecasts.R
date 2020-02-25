library(tidyverse)
library(prophet)
library(lubridate)


preprint_data <- read_csv('/Users/courtneysoderberg/Downloads/preprint_per_day.csv') %>%
                    rename(ds = day, y =count) %>%
                    slice(-1)  #removing the last day since it was a partial day

model <- prophet(preprint_data, seasonality.mode = 'multiplicative')
future <- make_future_dataframe(model, periods = 560)
forecast <- predict(model, future)

plot(model, forecast)
prophet_plot_components(model, forecast)

df_cv <-  cross_validation(model, units = 'days', horizon = 180)
df_p <- performance_metrics(df_cv)
plot_cross_validation_metric(df_cv, metric = 'mape')



### removing the one obviously outlier day that was over 300
preprints_ol_removed <- preprint_data %>% filter(y < 250)
model_nol <- prophet(preprints_ol_removed, seasonality.mode = 'multiplicative')
future_nol <- make_future_dataframe(model_nol, periods = 560)
forecast_nol <- predict(model_nol, future_nol)

plot(model_nol, forecast_nol)
# + add_changepoints_to_plot(model_nol)

prophet_plot_components(model_nol, forecast_nol)

df_cv <-  cross_validation(model_nol, units = 'days', horizon = 180)
df_p <- performance_metrics(df_cv)
plot_cross_validation_metric(df_cv, metric = 'mape')





#logistic model 500 cap
preprints_ol_removed$cap <- 500
log_model5 <- prophet(preprints_ol_removed, growth = 'logistic', seasonality.mode = 'multiplicative')

future5 <- make_future_dataframe(log_model5, periods = 560)
future5$cap <- 500
forecast5 <- predict(log_model5, future5)

plot(log_model5, forecast5)
prophet_plot_components(log_model5, forecast5)

df_cv5 <-  cross_validation(log_model5, units = 'days', horizon = 180)
df_p5 <- performance_metrics(df_cv5)
plot_cross_validation_metric(df_cv5, metric = 'mape')

#logistic model 200 cap
preprints_ol_removed$cap <- 200
log_model2 <- prophet(preprints_ol_removed, growth = 'logistic', seasonality.mode = 'multiplicative')

future2 <- make_future_dataframe(log_model2, periods = 560)
future2$cap <- 200
forecast2 <- predict(log_model2, future2)

plot(log_model2, forecast2)
prophet_plot_components(log_model2, forecast2)

df_cv2 <-  cross_validation(log_model2, units = 'days', horizon = 180)
df_p2 <- performance_metrics(df_cv2)
plot_cross_validation_metric(df_cv2, metric = 'mape')


#logistic model 100 cap
preprints_ol_removed$cap <- 100
log_model1 <- prophet(preprints_ol_removed, growth = 'logistic', seasonality.mode = 'multiplicative')

future1 <- make_future_dataframe(log_model1, periods = 560)
future1$cap <- 100
forecast1 <- predict(log_model1, future1)

plot(log_model1, forecast1)
prophet_plot_components(log_model1, forecast1)

df_cv1 <-  cross_validation(log_model1, units = 'days', horizon = 180)
df_p1 <- performance_metrics(df_cv1)
plot_cross_validation_metric(df_cv1, metric = 'mape')



rounded_forecast_nol <- forecast_nol %>%
                            select(ds, yhat, yhat_lower, yhat_upper) %>%
                            mutate(yhat_round = round(yhat),
                                   lower_round = round(yhat_lower),
                                   upper_round = round(yhat_upper),
                                   date = as_date(ds),
                                   lower_round = case_when(lower_round < 0 ~ 0,
                                                           lower_round >= 0 ~ lower_round)) %>%
                            filter(date >= '2018-08-16')

rounded_forecast_nol %>%
  filter(date > '2019-12-31' & date < '2021-01-01') %>%
  summarize(lower_80 = sum(lower_round), upper_80 = sum(upper_round), middle = sum(yhat_round))





rounded_forecast1 <- forecast1 %>%
  select(ds, yhat, yhat_lower, yhat_upper) %>%
  mutate(yhat_round = round(yhat),
         lower_round = round(yhat_lower),
         upper_round = round(yhat_upper),
         date = as_date(ds),
         lower_round = case_when(lower_round < 0 ~ 0,
                                 lower_round >= 0 ~ lower_round)) %>%
  filter(date >= '2018-08-16')

rounded_forecast1 %>%
  filter(date > '2019-12-31' & date < '2021-01-01') %>%
  summarize(lower_80 = sum(lower_round), upper_80 = sum(upper_round), middle = sum(yhat_round))


rounded_forecast2 <- forecast2 %>%
  select(ds, yhat, yhat_lower, yhat_upper) %>%
  mutate(yhat_round = round(yhat),
         lower_round = round(yhat_lower),
         upper_round = round(yhat_upper),
         date = as_date(ds),
         lower_round = case_when(lower_round < 0 ~ 0,
                                 lower_round >= 0 ~ lower_round)) %>%
  filter(date >= '2018-08-16')

rounded_forecast2 %>%
  filter(date > '2019-12-31' & date < '2021-01-01') %>%
  summarize(lower_80 = sum(lower_round), upper_80 = sum(upper_round), middle = sum(yhat_round))


rounded_forecast5 <- forecast5 %>%
  select(ds, yhat, yhat_lower, yhat_upper) %>%
  mutate(yhat_round = round(yhat),
         lower_round = round(yhat_lower),
         upper_round = round(yhat_upper),
         date = as_date(ds),
         lower_round = case_when(lower_round < 0 ~ 0,
                                 lower_round >= 0 ~ lower_round)) %>%
  filter(date >= '2018-08-16')

rounded_forecast5 %>%
  filter(date > '2019-12-31' & date < '2021-01-01') %>%
  summarize(lower_80 = sum(lower_round), upper_80 = sum(upper_round), middle = sum(yhat_round))
  

## how many preprints have gotten DOIs this year
preprint_data %>% filter(ds < '2019-08-16' & ds > '2018-12-31') %>% summarize(n_preprints = sum(y))




#### redoing forecasts ignoring InaRxiv
library(googlesheets4)
library(lubridate)

all_preprint_data <- read_sheet('https://docs.google.com/spreadsheets/d/14K6dlo0G5-PA0W14d2DDg4ZHK8cG40JQ8XybQ9yWQYY/edit?usp=drive_web&ouid=113807395134844022691') %>%
                          select(-keen.created_at) %>%
                          mutate(provider.total = unlist(provider.total),
                                 keen.timestamp = ymd_hms(keen.timestamp))


preprint_data <- all_preprint_data %>%
                      mutate(ds = date(keen.timestamp),
                             y = as.numeric(provider.total),
                             no_inarxiv = case_when(provider.name == 'INA-Rxiv' ~ 0,
                                                    TRUE ~ y),
                             partial_inarxiv = case_when(provider.name == 'INA-Rxiv' ~ round(y * .75),
                                                         TRUE ~ y))

daily_data <- preprint_data %>%
                group_by(ds) %>%
                summarize(daily_total = sum(y, na.rm = T),
                          daily_total_noina = sum(no_inarxiv, na.rm = T),
                          daily_total_partialina = sum(partial_inarxiv, na.rm = T)) %>%
                mutate(dt_increase = daily_total - lag(daily_total),
                       dt_noina_increase = daily_total_noina - lag(daily_total_noina),
                       dt_partialina_increase = daily_total_partialina - lag(daily_total_partialina)) %>%
                filter(dt_increase > -100) %>% #remove spam corrections/keen errors
                filter(dt_increase < 1000) # remove one extreme outlier day
                      
# setting up individual dataframes
dt_increase_data <- as.data.frame(daily_data %>% 
                                    select(ds, dt_increase) %>% 
                                    rename(y = dt_increase))

dt_noina_increase_data <- as.data.frame(daily_data %>% 
                                    select(ds, dt_noina_increase) %>% 
                                    rename(y = dt_noina_increase))

dt_partialina_increase_data <- as.data.frame(daily_data %>% 
                                    select(ds, dt_partialina_increase) %>% 
                                    rename(y = dt_partialina_increase))

# models with all data
all_data_model <- prophet(dt_increase_data, seasonality.mode = 'multiplicative')
all_data_future <- make_future_dataframe(all_data_model, periods = 1095)
all_data_forecast <- predict(all_data_model, all_data_future )

plot(all_data_model, all_data_forecast)
prophet_plot_components(all_data_model, all_data_forecast)

df_cv <-  cross_validation(all_data_model, units = 'days', horizon = 180)
df_p <- performance_metrics(df_cv)
plot_cross_validation_metric(df_cv, metric = 'mape')

# models assuming no InaRxiv
noina_data_model <- prophet(dt_noina_increase_data, seasonality.mode = 'multiplicative')
noina_data_future <- make_future_dataframe(noina_data_model, periods = 1095)
noina_data_forecast <- predict(noina_data_model, noina_data_future)

plot(noina_data_model, noina_data_forecast)
prophet_plot_components(noina_data_model, noina_data_forecast)

df_cv <-  cross_validation(noina_data_model, units = 'days', horizon = 180)
df_p <- performance_metrics(df_cv)
plot_cross_validation_metric(df_cv, metric = 'mape')


# models assuming partial InaRxiv
partialina_data_model <- prophet(dt_partialina_increase_data, seasonality.mode = 'multiplicative')
partialina_data_future <- make_future_dataframe(partialina_data_model, periods = 1095)
partialina_data_forecast <- predict(partialina_data_model, partialina_data_future)

plot(partialina_data_model, partialina_data_forecast)
prophet_plot_components(partialina_data_model, partialina_data_forecast)

df_cv <-  cross_validation(partialina_data_model, units = 'days', horizon = 180)
df_p <- performance_metrics(df_cv)
plot_cross_validation_metric(df_cv, metric = 'mape')



#total forecasts
rounded_forecast_total <- all_data_forecast %>%
  select(ds, yhat, yhat_lower, yhat_upper) %>%
  mutate(yhat_round = round(yhat),
         lower_round = round(yhat_lower),
         upper_round = round(yhat_upper),
         date = as_date(ds),
         lower_round = case_when(lower_round < 0 ~ 0,
                                 lower_round >= 0 ~ lower_round)) %>%
  filter(date >= '2018-08-16')

rounded_forecast_total %>%
  filter(date > '2019-12-31' & date < '2022-01-01') %>%
  mutate(year = year(ds)) %>%
  group_by(year) %>%
  summarize(lower_80 = sum(lower_round), upper_80 = sum(upper_round), middle = sum(yhat_round))

#no-inarxiv forecasts
rounded_forecast_noina <- noina_data_forecast %>%
  select(ds, yhat, yhat_lower, yhat_upper) %>%
  mutate(yhat_round = round(yhat),
         lower_round = round(yhat_lower),
         upper_round = round(yhat_upper),
         date = as_date(ds),
         lower_round = case_when(lower_round < 0 ~ 0,
                                 lower_round >= 0 ~ lower_round)) %>%
  filter(date >= '2018-08-16')

rounded_forecast_noina %>%
  filter(date > '2019-12-31' & date < '2022-01-01') %>%
  mutate(year = year(ds)) %>%
  group_by(year) %>%
  summarize(lower_80 = sum(lower_round), upper_80 = sum(upper_round), middle = sum(yhat_round))

#partial-inarxiv forecasts
rounded_forecast_partialina <- partialina_data_forecast %>%
  select(ds, yhat, yhat_lower, yhat_upper) %>%
  mutate(yhat_round = round(yhat),
         lower_round = round(yhat_lower),
         upper_round = round(yhat_upper),
         date = as_date(ds),
         lower_round = case_when(lower_round < 0 ~ 0,
                                 lower_round >= 0 ~ lower_round)) %>%
  filter(date >= '2018-08-16')

rounded_forecast_partialina %>%
  filter(date > '2019-12-31' & date < '2022-01-01') %>%
  mutate(year = year(ds)) %>%
  group_by(year) %>%
  summarize(lower_80 = sum(lower_round), upper_80 = sum(upper_round), middle = sum(yhat_round))
