library(tidyverse)
library(lubridate)
library(timeDate)
library(tis)

pickups <- read_csv("uber-raw-data-janjune-15.csv")

daydata <- pickups %>%
  mutate(day=yday(Pickup_date)) %>%
  group_by(day) %>%
  summarize(count=n())

daydata %>%
  ggplot() +
  geom_point(mapping=aes(day, count)) +
  geom_line(mapping=aes(day, count)) +
  labs(title="Uber Pickups by Day between January and June 2015")

linearmod <- lm("count ~ day", daydata)
linearfit <- predict.lm(linearmod)

daydata %>%
  ggplot() +
  geom_point(mapping=aes(day, count)) +
  geom_line(mapping=aes(day, count)) +
  geom_line(mapping=aes(day, linearfit), color="red") +
  labs(title="Uber Pickups by Day between January and June 2015 with Trend")

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

daydata %>%
  mutate(detrended=count-linearfit) %>%
  ggplot() +
  geom_point(mapping=aes(day, detrended)) +
  geom_line(mapping=aes(day, detrended)) +
  labs(title="Uber Pickups by Day between January and June 2015, Detrended")

daydata %>%
  mutate(differenced=count-lag(count)) %>%
  drop_na() %>%
  ggplot() +
  geom_point(mapping=aes(day, differenced)) +
  geom_line(mapping=aes(day, differenced)) +
  labs(title="Uber Pickups by Day between January and June 2015, 1st Order Difference")

daydata %>%
  mutate(differenced=count-lag(count, 7)) %>%
  drop_na() %>%
  ggplot() +
  geom_point(mapping=aes(day, differenced)) +
  geom_line(mapping=aes(day, differenced)) +
  labs(title="Uber Pickups by Day between January and June 2015, 7th Order Difference")

daydata %>%
  mutate(differenced=count-lag(count, 7)) %>%
  drop_na() %>%
  mutate(differenced=differenced-lag(differenced)) %>%
  drop_na() %>%
  ggplot() +
  geom_point(mapping=aes(day, differenced)) +
  geom_line(mapping=aes(day, differenced)) +
  labs(title="Uber Pickups by Day between January and June 2015, 1st and 7th Order Difference")

lag_scatter <- function(datavector, laglevel) {
  print(laglevel)
  ggplot() +
    geom_point(mapping=aes(datavector, lag(datavector, laglevel))) +
    geom_smooth(mapping=aes(datavector, lag(datavector, laglevel)), method = "loess", size = 1.5) +
    labs(y=str_c("Lagged Pickups of Order ",as.character(laglevel)),
         x="Day of Year")
  ggsave(str_c("pickupslaggedgg", as.character(laglevel), ".png"),
         width=4, height=4)
}

as.vector(1:9) %>%
  map(~ lag_scatter(daydata$count, .x))
