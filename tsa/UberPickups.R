library(tidyverse)
library(lubridate)

pickups <- read_csv("uber-raw-data-janjune-15.csv")

daydata <- pickups %>%
  mutate(day=yday(Pickup_date)) %>%
  group_by(day) %>%
  summarize(count=n())

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
