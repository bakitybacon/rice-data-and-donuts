library(tidyverse)
library(lubridate)
library(tis)
library(timeDate)
library(forecast)
library(tseries)
library(prophet)
library(keras)
library(tensorflow)

pickups <- read_csv("uber-raw-data-janjune-15.csv")

# Exploratory Data Analysis

daydata <- pickups %>%
  mutate(day=yday(Pickup_date)) %>%
  group_by(day) %>%
  summarize(count=n())

daydata %>%
  ggplot() +
  geom_point(mapping=aes(day, count)) +
  geom_line(mapping=aes(day, count)) +
  labs(title="Uber Pickups by Day of Year between January and June 2015", y="Pickup Count", x="Day")

pickups %>%
  mutate(month=month(Pickup_date)) %>%
  group_by(month) %>%
  summarize(count=n()) %>%
  ggplot() +
  geom_point(mapping=aes(month, count)) +
  geom_line(mapping=aes(month, count))  +
  labs(title="Uber Pickups by Month between January and June 2015",  y="Pickup Count", x="Month")

pickups %>%
  mutate(day=day(Pickup_date)) %>%
  group_by(day) %>%
  summarize(count=n()) %>%
  ggplot() +
  geom_point(mapping=aes(day, count)) +
  geom_line(mapping=aes(day, count))  +
  labs(title="Uber Pickups by Day of Month between January and June 2015",  y="Pickup Count", x="Month")

pickups %>%
  mutate(hour=hour(Pickup_date)) %>%
  group_by(hour) %>%
  summarize(count=n()) %>%
  ggplot() +
  geom_point(mapping=aes(hour, count)) +
  geom_line(mapping=aes(hour, count))  +
  labs(title="Uber Pickups by Hour of Day between January and June 2015",  y="Pickup Count", x="Hour")

# Checking the trend

linearmod <- lm("count ~ day", daydata)
linearfit <- predict.lm(linearmod)

daydata %>%
  ggplot() +
  geom_point(mapping=aes(day, count)) +
  geom_line(mapping=aes(day, count)) +
  geom_line(mapping=aes(day, linearfit), color="red") +
  labs(title="Uber Pickups by Day between January and June 2015 with Trend",  y="Pickup Count", x="Day")

daydata %>%
  mutate(detrended=count-linearfit) %>%
  ggplot() +
  geom_point(mapping=aes(day, detrended)) +
  geom_line(mapping=aes(day, detrended)) +
  labs(title="Uber Pickups by Day between January and June 2015, Detrended",  y="Pickup Count", x="Day")

# Messing around with holidays

some_holidays <- tribble(
  ~name, ~datestr,
  "New Year's Day", "20150101",
  "MLK Day", "20150119",
  "Valentine's Day", "20150214",
  "Presidents' Day", "20150216",
  "Memorial Day", "20150525"
)

some_holidays$date <- as_date(some_holidays$datestr)

holidays <- pickups %>%
  mutate(date=as_date(Pickup_date)) %>%
  filter(date %in% as_date(some_holidays$date)) %>%
  mutate(day=yday(Pickup_date)) %>%
  group_by(day) %>%
  summarize(total=n())

notholidays <- pickups %>%
  mutate(date=as_date(Pickup_date)) %>%
  filter(!(date %in% as_date(some_holidays$date))) %>%
  mutate(day=yday(Pickup_date)) %>%
  group_by(day) %>%
  summarize(total=n())

holidaysvsnot <- tribble(
  ~holidays, ~pickupsperday,
  "Yes", sum(holidays$total) / nrow(holidays),
  "No", sum(notholidays$total) / nrow(notholidays)
)

holidaysvsnot %>%
  ggplot() +
  geom_col(mapping=aes(holidays, pickupsperday)) +
  labs(y="Pickups Per Day")

# Differencing

difforders = c(1, 7)

difference_plot <- function(order) {
  daydata %>%
    mutate(differenced=count-lag(count, order)) %>%
    drop_na() %>%
    ggplot() +
    geom_point(mapping=aes(day, differenced)) +
    geom_line(mapping=aes(day, differenced)) +
    labs(title=str_c("Difference Order: ", as.character(order)))
}

difforders %>%
  map(difference_plot)

daydata %>%
  mutate(differenced=count-lag(count, 7)) %>%
  drop_na() %>%
  mutate(differenced=differenced-lag(differenced)) %>%
  drop_na() %>%
  ggplot() +
  geom_point(mapping=aes(day, differenced)) +
  geom_line(mapping=aes(day, differenced)) +
  labs(title="Difference Orders: 1 and 7")

# Lagged scatterplots

lag_scatter_map <- function(datavector, maxlag) {
  1:maxlag %>%
    map(~ lag_scatter(daydata$count, .x))
}

lag_scatter <- function(datavector, laglevel) {
  print(laglevel)
  ggplot() +
    geom_point(mapping=aes(datavector, lag(datavector, laglevel))) +
    geom_smooth(mapping=aes(datavector, lag(datavector, laglevel)), method = "loess", size = 1.5) +
    labs(y=str_c("Lagged Pickups of Order ",as.character(laglevel)),
         x="Day of Year")
}

lag_scatter_map(daydata$count, 9)

# Plotting moving averages

maorders = c(1, 3)

ma_plot <- function(order) {
  daydata %>%
    mutate(ma=ma(count, order, centre=FALSE)) %>%
    drop_na() %>%
    ggplot() +
    geom_point(mapping=aes(day, ma)) +
    geom_line(mapping=aes(day, ma)) +
    labs(title=str_c("Moving Average Difference Order: ", as.character(order)))
}

maorders %>%
  map(ma_plot)

# Autocorrelation plot

confbound <- qnorm((1 + 0.95)/2)/sqrt(nrow(daydata))

acf_vector <- as.vector(acf(daydata$count, plot=FALSE)$acf)
acftibble <- tibble(lag=0:(length(acf_vector)-1), acf=acf_vector)
acftibble %>%
  mutate(minconf=-confbound) %>%
  mutate(maxconf=confbound) %>%
  ggplot() +
  geom_bar(stat="identity", mapping=aes(lag, acf)) +
  geom_ribbon(mapping=aes(x=lag, ymin=minconf, ymax=maxconf), fill="blue", alpha=0.2) +
  labs(title="Autocorrelation Plot")

# Partial autocorrelation plot

pacf_vector <- as.vector(pacf(daydata$count, plot=FALSE)$acf)
pacftibble <- tibble(lag=0:(length(pacf_vector)-1), pacf=pacf_vector)
pacftibble %>%
  mutate(minconf=-confbound) %>%
  mutate(maxconf=confbound) %>%
  ggplot() +
  geom_bar(stat="identity", mapping=aes(lag, pacf)) +
  geom_ribbon(mapping=aes(x=lag, ymin=minconf, ymax=maxconf), fill="blue", alpha=0.2) +
  labs(title="Partial Autocorrelation Plot")

# Splitting data to evaluate forecasting ability

daydata_train <- daydata %>%
  filter(day < 150)

daydata_test <- daydata %>%
  filter(day >= 150)

# Sample arima model + plot

arimamodel <- arima(daydata_train$count, order=c(26,1,0), seasonal=c(1, 1, 24))
arimafit <- as.vector(forecast(arimamodel, h=32))

arimamre <- mean((daydata_test$count - arimafit$mean)/daydata_test$count)

ggplot() +
  geom_point(mapping=aes(daydata$day, daydata$count)) +
  geom_line(mapping=aes(daydata$day, daydata$count)) +
  geom_point(mapping=aes(daydata_test$day, arimafit$mean), color="red") +
  geom_line(mapping=aes(daydata_test$day, arimafit$mean), color="red") +
  geom_ribbon(mapping=aes(x=daydata_test$day, ymin=as.vector(arimafit$lower[,1]), ymax=as.vector(arimafit$upper[,1])), color="gray", fill="red", alpha=0.2) +
  geom_vline(mapping=aes(xintercept=150), color="blue") + 
  labs(title="A Fitted Arima Model", y="Pickup Count", x="Day")

# Sample prophet model + plot

prophet_train <- daydata_train
prophet_test <- daydata_test

colnames(prophet_train) <- c("ds","y") #because prophet has annoying conventions
colnames(prophet_test) <- c("ds","y") #because prophet has annoying conventions

day1 <- as_date("20150101")
prophet_train$ds <- day1 + days(prophet_train$ds - 1)
prophet_test$ds <- day1 + days(prophet_test$ds - 1)

prophetmodel <- prophet(prophet_train, fit=TRUE, daily.seasonality = TRUE, weekly.seasonality = TRUE)
prophetfit <- predict(prophetmodel, prophet_test)

prophetmre <- mean((daydata_test$count - prophetfit$yhat)/daydata_test$count)

ggplot() +
  geom_point(mapping=aes(daydata$day, daydata$count)) +
  geom_line(mapping=aes(daydata$day, daydata$count)) +
  geom_point(mapping=aes(daydata_test$day, prophetfit$yhat), color="red") +
  geom_line(mapping=aes(daydata_test$day, prophetfit$yhat), color="red") +
  geom_ribbon(mapping=aes(x=daydata_test$day, ymin=prophetfit$yhat_lower, ymax=prophetfit$yhat_upper), color="gray", fill="red", alpha=0.2) +
  geom_vline(mapping=aes(xintercept=150), color="blue") + 
  labs(title="A Fitted Prophet Model", y="Pickup Count", x="Day")

# Seasonal decompose of prophet
prophet_plot_components(prophetfit)

# Tensorflow setup
tf$InteractiveSession()
tf$GPUOptions$allow_growth <- TRUE

tf_train_x <- array_reshape(as.array(daydata_train$day), c(nrow(daydata_train), 1, 1))
tf_train_y <- array_reshape(as.array(daydata_train$count), c(nrow(daydata_train), 1, 1))
tf_test_x <- array_reshape(as.array(daydata_test$day), c(nrow(daydata_test), 1, 1))
tf_test_y <- array_reshape(as.array(daydata_test$count), c(nrow(daydata_test), 1, 1))

# A tensorflow simple RNN model
rnn <- keras_model_sequential()
rnn %>%
  layer_simple_rnn(1, return_sequences=TRUE, input_shape = c(1, 1)) %>%
  layer_activation_relu() %>%
  layer_dense(1)

rnn %>%
  compile(
    optimizer = "adam",
    loss = "mean_absolute_percentage_error"
  )

rnn %>% 
  fit(
    tf_train_x, tf_train_y,
    epochs = 30,
    validation_split = 0.2
  )

rnn %>%
  evaluate(tf_test_x, tf_test_y)

rnnfit <- rnn %>%
  predict(tf_test_x)

ggplot() +
  geom_point(mapping=aes(daydata$day, daydata$count)) +
  geom_line(mapping=aes(daydata$day, daydata$count)) +
  geom_point(mapping=aes(daydata_test$day, as.vector(rnnfit)), color="red") +
  geom_line(mapping=aes(daydata_test$day, as.vector(rnnfit)), color="red") +
  geom_vline(mapping=aes(xintercept=150), color="blue") + 
  labs(title="A Fitted Simple RNN Model", y="Pickup Count", x="Day")

# A tensorflow LSTM model
lstm <- keras_model_sequential()
lstm %>%
  layer_lstm(units=1, return_sequences=TRUE, input_shape = c(1, 1)) %>%
  layer_activation_relu() %>%
  layer_dense(1)

lstm %>%
  compile(
    optimizer = "adam",
    loss = "mean_absolute_percentage_error"
  )

lstm %>% 
  fit(
    tf_train_x, tf_train_y,
    epochs = 30,
    validation_split = 0.2
  )

lstm %>%
  evaluate(tf_test_x, tf_test_y)

lstmfit <- lstm %>%
  predict(tf_test_x)

ggplot() +
  geom_point(mapping=aes(daydata$day, daydata$count)) +
  geom_line(mapping=aes(daydata$day, daydata$count)) +
  geom_point(mapping=aes(daydata_test$day, as.vector(lstmfit)), color="red") +
  geom_line(mapping=aes(daydata_test$day, as.vector(lstmfit)), color="red") +
  geom_vline(mapping=aes(xintercept=150), color="blue") + 
  labs(title="A Fitted LSTM Model", y="Pickup Count", x="Day")

# RNN and LSTM with actually enough data
minutedata <- pickups %>%
  mutate(day=yday(Pickup_date)) %>%
  mutate(hour=hour(Pickup_date)) %>%
  mutate(minute=minute(Pickup_date)) %>%
  group_by_at(vars(day, hour, minute)) %>%
  summarize(count=n())

# preprocess data
#  step 1: differencing by 1 and 7 (day, week)
#  step 2: order 7 moving average
#  step 3: 0-1 scaling

minutedata <- minutedata %>%
  mutate(count=count-lag(count, 1)) %>%
  drop_na() %>%
  mutate(count=count-lag(count, 7)) %>%
  drop_na() %>%
  mutate(count=ma(count, 7, centre=FALSE)) %>%
  drop_na() %>%
  mutate(count=count-min(count)) %>%
  mutate(count=count/max(count))

minutedata_train <- minutedata %>%
  filter(day < 150)

minutedata_test <- minutedata %>%
  filter(day >= 150)

minutedata_train <- rowid_to_column(minutedata_train)
minutedata_test <- rowid_to_column(minutedata_test)
minutedata_test$rowid <- minutedata_test$rowid + nrow(minutedata_train)

min_train_x <- array_reshape(as.array(minutedata_train$rowid), c(nrow(minutedata_train), 1, 1))
min_train_y <- array_reshape(as.array(minutedata_train$count), c(nrow(minutedata_train), 1, 1))
min_test_x <- array_reshape(as.array(minutedata_test$rowid), c(nrow(minutedata_test), 1, 1))
min_test_y <- array_reshape(as.array(minutedata_test$count), c(nrow(minutedata_test), 1, 1))

biglstm <- keras_model_sequential()
biglstm %>%
  layer_lstm(units=100, return_sequences=TRUE, input_shape = c(1, 1)) %>%
  layer_activation_relu() %>%
  layer_lstm(units=100, return_sequences=TRUE) %>%
  layer_activation_relu() %>%
  layer_lstm(units=50, return_sequences=TRUE) %>%
  layer_activation_relu() %>%
  layer_dense(300) %>%
  layer_activation_relu() %>%
  layer_dense(50) %>%
  layer_activation_relu() %>%
  layer_dense(1)

biglstm %>%
  compile(
    optimizer = "adam",
    loss = "mean_absolute_percentage_error"
  )

tensorboard("logs/lstm")

biglstm %>% 
  fit(
    min_train_x, min_train_y,
    epochs = 300,
    validation_split = 0.2,
    callbacks = callback_tensorboard("logs/lstm")
  )

  biglstm %>%
  evaluate(min_test_x, min_test_y)

biglstmfit <- biglstm %>%
  predict(min_test_x)

# sum up to day level
biglstmfit <- array_reshape(biglstmfit, c(24, length(biglstmfit) / 24))
biglstmfit <- colSums(biglstmfit)

ggplot() +
  geom_point(mapping=aes(daydata$day, daydata$count)) +
  geom_line(mapping=aes(daydata$day, daydata$count)) +
  geom_point(mapping=aes(daydata_test$day, as.vector(biglstmfit)), color="red") +
  geom_line(mapping=aes(daydata_test$day, as.vector(biglstmfit)), color="red") +
  geom_vline(mapping=aes(xintercept=150), color="blue") + 
  labs(title="A Fitted LSTM Model", y="Pickup Count", x="Day")
