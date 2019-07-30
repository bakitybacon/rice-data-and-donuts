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
  ~name, ~date,
  "New Year's Day", ymd("2015-01-01"),
  "MLK Day", ymd("2015-01-19"),
  "Valentine's Day", ymd("2015-02-14"),
  "Presidents' Day", ymd("2015-02-16"),
  "Memorial Day", ymd("2015-05-25"))

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
