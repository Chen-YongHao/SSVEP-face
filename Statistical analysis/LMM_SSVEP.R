# packages
library(ez)
library(lme4)
library(lmerTest)
library(readr)
library(zoo)
library(lmtest)

## Fed data into it
Amp_5Hz_Oz <- read_csv("5Hz_Cluster.csv")

#Amp_5Hz_Oz$Amp <- scale(Amp_5Hz_Oz$Amp)
#Amp_5Hz_Oz$Realness_sq <- scale(Amp_5Hz_Oz$Realness^2)
#Amp_5Hz_Oz$Realness <- scale(Amp_5Hz_Oz$Realness)
Amp_5Hz_Oz$Subject <- as.factor(Amp_5Hz_Oz$Subject)
Amp_5Hz_Oz$Emotion <- as.factor(Amp_5Hz_Oz$Emotion)
Amp_5Hz_Oz$Gender <- as.factor(Amp_5Hz_Oz$Gender)


#View(Amp_5Hz_Oz)


#m_fit_lin <- lmer(Amp ~ 1+ Realness + (1+Realness|Subject), data=Amp_5Hz_Oz, REML=F)
#m_fit_con <- lmer(Amp ~ 1+ (1|Subject), data=Amp_5Hz_Oz, REML=F)
#summary(m_fit_con)

m_fit_lin <- lmer(Amp ~ 1+ Realness + (1|Subject), data=Amp_5Hz_Oz, REML=F)

summary(m_fit_lin)
qqnorm(resid(m_fit_lin))
qqline(resid(m_fit_lin))

m_fit_qua <- lmer(Amp ~ I(Realness^2) + Realness + 1 + (1|Subject), data=Amp_5Hz_Oz, REML=F)


summary(m_fit_qua)
#qqnorm(resid(m_fit_qua))
#qqline(resid(m_fit_qua))
anova(m_fit_lin, m_fit_qua)
lrtest(m_fit_lin, m_fit_qua)

