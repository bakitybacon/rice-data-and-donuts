# DATA TYPES EXERCISES


# READING AND WRITING DATA

write.csv(faithful, "faithful.csv", row.names=FALSE)
faith <- read.csv("faithful.csv")


# DATA MANIPULATION


# VISUALIZATION
boxplot(faith$eruptions)
boxplot(faith$waiting)

hist(faith$eruptions, breaks = 10)
hist(faith$waiting, breaks = "scott")

plot(faith$eruptions, faith$waiting)
plot(faith$waiting, faith$eruptions)
plot(faith, main="Old Faithful Eruptions",
     xlab="Duration of Eruptions (minutes)",
     ylab="Interval between Eruptions (minutes)")

# MODELING

model <- lm(faith$waiting ~ faith$eruptions)
abline(model$coefficients, col="blue")
