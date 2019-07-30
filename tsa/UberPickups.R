library(tidyverse)
library(lubridate)
library(tis)
library(timeDate)
library(forecast)
library(tseries)

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
  labs(title="Uber Pickups by Day between January and June 2015")

pickups %>%
  mutate(month=month(Pickup_date)) %>%
  group_by(month) %>%
  summarize(count=n()) %>%
  ggplot() +
  geom_point(mapping=aes(month, count)) +
  geom_line(mapping=aes(month, count))  +
  labs(title="Uber Pickups by Month between January and June 2015")

pickups %>%
  mutate(day=day(Pickup_date)) %>%
  group_by(day) %>%
  summarize(count=n()) %>%
  ggplot() +
  geom_point(mapping=aes(day, count)) +
  geom_line(mapping=aes(day, count))  +
  labs(title="Uber Pickups by Day of Month between January and June 2015")

pickups %>%
  mutate(hour=hour(Pickup_date)) %>%
  group_by(hour) %>%
  summarize(count=n()) %>%
  ggplot() +
  geom_point(mapping=aes(hour, count)) +
  geom_line(mapping=aes(hour, count))  +
  labs(title="Uber Pickups by Hour between January and June 2015")

# Checking the trend

linearmod <- lm("count ~ day", daydata)
linearfit <- predict.lm(linearmod)

daydata %>%
  ggplot() +
  geom_point(mapping=aes(day, count)) +
  geom_line(mapping=aes(day, count)) +
  geom_line(mapping=aes(day, linearfit), color="red") +
  labs(title="Uber Pickups by Day between January and June 2015 with Trend")

daydata %>%
  mutate(detrended=count-linearfit) %>%
  ggplot() +
  geom_point(mapping=aes(day, detrended)) +
  geom_line(mapping=aes(day, detrended)) +
  labs(title="Uber Pickups by Day between January and June 2015, Detrended")

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

acf_vector <- as.vector(acf(daydata$count, plot=FALSE)$acf)
acftibble <- tibble(lag=0:(length(acf_vector)-1), acf=acf_vector)
acftibble %>%
  ggplot() +
  geom_bar(stat="identity", mapping=aes(lag, acf))

# Partial autocorrelation plot

pacf_vector <- as.vector(pacf(daydata$count, plot=FALSE)$acf)
pacftibble <- tibble(lag=0:(length(pacf_vector)-1), pacf=pacf_vector)
pacftibble %>%
  ggplot() +
  geom_bar(stat="identity", mapping=aes(lag, pacf))

# Hiding data after 150

daydata_train <- daydata %>%
  filter(day < 150)

daydata_test <- daydata %>%
  filter(day >= 150)


# A sample model + plot

arimamodel <- arima(daydata_train$count, order=c(26,1,0), seasonal=c(1, 1, 24))
arimafit <- as.vector(forecast(arimamodel, h=32)$mean)

ggplot() +
  geom_point(mapping=aes(daydata$day, daydata$count)) +
  geom_line(mapping=aes(daydata$day, daydata$count)) +
  geom_point(mapping=aes(daydata_test$day, arimafit), color="red") +
  geom_line(mapping=aes(daydata_test$day, arimafit), color="red") +
  geom_vline(mapping=aes(xintercept=150), color="blue") + 
  labs(title="A Fitted Arima Model", y="Pickup Count", x="Day")
