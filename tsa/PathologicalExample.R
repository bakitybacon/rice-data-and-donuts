library(forecast)
library(tseries)
library(tidyverse)

pathdata <- tibble(x = c(1, 2, 3, 4, 5, 6, 7, 8), y = c(-1, 1, -1, 1, -1, 1, -1, 1))

# add some random noise
pathdata$y <- pathdata$y + rnorm(8) * 0.01

linearmodel <- lm(pathdata$y ~ pathdata$x)
linearfit <- predict.lm(linearmodel)

ggplot(pathdata) +
  geom_point(mapping=aes(x, y), color="black") +
  geom_point(mapping=aes(x, linearfit), color="red") +
  labs(title = "Simple Linear Regression Sample Model")

# adf.test(y, alternative="stationary")
arimamodel <- arima(pathdata$y, order=c(1,1,0))
arimafit <- as.vector(forecast(arimamodel, h=8)$mean)

ggplot(pathdata) +
  geom_point(mapping=aes(x, y), color="black") +
  geom_point(mapping=aes(x, arimafit), color="red") +
  labs(title = "Time Series Sample Model")
