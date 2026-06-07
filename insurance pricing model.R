#Auto Insurance Premium Calculator
#French Motor TPL Dataset (freMTPL2)

#Phase 1: Data Loading
#loading package
library(tidyverse)

#reading data
freq<-read.csv("data/freMTPL2freq.csv")
sev<-read.csv("data/freMTPL2sev.csv")


#Phase 2: EDA
#checking data
dim(freq)
dim(sev)
skim(freq)
skim(sev)

#clip outliers
freq<-freq%>%
  mutate(
    ClaimNb=pmin(ClaimNb,4),
    Exposure=pmin(Exposure,1)
  )
sev<-sev%>%
  mutate(
    ClaimAmount=pmin(ClaimAmount,200000)
  )
#verification
max(freq$ClaimNb)
max(sev$ClaimAmount)
max(freq$Exposure)

#distribution of claim numbers
freq %>%
  count(ClaimNb) %>%
  mutate(pct=round(n/sum(n)*100,2))
   
ggplot(freq, aes(x=factor(ClaimNb)))+geom_bar(fill="blue")+labs(title="distribution of claims",x="number of claims",y="policy count")   

#distribution of claim amount
ggplot(sev, aes(x=ClaimAmount))+geom_histogram(bins=100,fill="red")+labs(title="claim severity-raw scale")   
ggplot(sev, aes(x=log(ClaimAmount)))+geom_histogram(bins=60,fill="red")+labs(title="claim severity-log scale")  
summary(sev$ClaimAmount)

#join tables
sev_agg<-sev%>%
  group_by(IDpol)%>%
  summarise(ClaimAmount=sum(ClaimAmount), .groups="drop")

df<-freq%>%
  left_join(sev_agg, by="IDpol")%>%
  mutate(ClaimAmount=replace_na(ClaimAmount,0))

#verify
nrow(df)       
sum(df$ClaimAmount>0)
head(df)
sum(is.na(df$ClaimAmount))


#portfolio benchmark
df_claims<-df%>%
  filter(ClaimNb>0, ClaimAmount>0)

#claim frequency
round(sum(df$ClaimNb) / sum(df$Exposure), 4)

#Zero-claim rate
round(mean(df$ClaimNb == 0) * 100, 1)
#Average severity
round(sum(df_claims$ClaimAmount) / sum(df_claims$ClaimNb), 0)
#Pure premium
round(sum(df$ClaimAmount) / sum(df$Exposure), 0)

#claim freq by driver age
df %>%
  mutate(AgeBand = cut(DrivAge,
                       breaks = c(18,22,25,30,40,50,60,70,100),
                       right  = FALSE)) %>%
  filter(!is.na(DrivAge), DrivAge <100) %>% 
  group_by(AgeBand) %>%
  summarise(AvgFreq = sum(ClaimNb) / sum(Exposure)) %>%
  ggplot(aes(x = AgeBand, y = AvgFreq)) +
  geom_col(fill = "blue") +
  labs(title = "Claim Frequency by Driver Age",
       y = "Claims per Policy-Year", x = "Age Band")

#claim freq by BonusMalus
df %>%
  mutate(BMBand = cut(BonusMalus,
                      breaks = c(50,60,70,80,100,120,150,350),
                      right  = FALSE)) %>%
  group_by(BMBand) %>%
  summarise(AvgFreq = sum(ClaimNb) / sum(Exposure)) %>%
  ggplot(aes(x = BMBand, y = AvgFreq)) +
  geom_col(fill = "red") +
  labs(title = "Claim Frequency by BonusMalus",
       y = "Claims per Policy-Year")

#claim freq by vehicle power
df %>%
  group_by(VehPower) %>%
  summarise(AvgFreq = sum(ClaimNb) / sum(Exposure)) %>%
  ggplot(aes(x = factor(VehPower), y = AvgFreq)) +
  geom_col(fill = "green") +
  labs(title = "Claim Frequency by Vehicle Power",
       x = "Vehicle Power", y = "Claims per Policy-Year")

#claim freq by vehicle age
df %>%
  mutate(VehageBand=cut(VehAge, breaks=c(1,3,5,10,15,20,100),right=FALSE))%>%
  filter(!is.na(VehageBand), VehAge < 20) %>% 
  group_by(VehageBand) %>%
  summarise(AvgFreq = sum(ClaimNb) / sum(Exposure)) %>%
  ggplot(aes(x = factor(VehageBand), y = AvgFreq)) +
  geom_col(fill = "orange") +
  labs(title = "Claim Frequency by Vehicle Age",
       x = "Vehicle Age Band", y = "Claims per Policy-Year")


#severity analysis
df_claims <- df %>% filter(ClaimNb > 0, ClaimAmount > 0)

df_claims %>%
  mutate(AvgClaimCost = ClaimAmount / ClaimNb,
         AgeBand = cut(DrivAge, breaks = c(18,25,35,50,65,100),
                       right = FALSE)) %>%
  filter(!is.na(AvgClaimCost), DrivAge<100)%>%
  group_by(AgeBand) %>%
  summarise(AvgSeverity = mean(AvgClaimCost)) %>%
  ggplot(aes(x = AgeBand, y = AvgSeverity)) +
  geom_col(fill = "coral") +
  labs(title = "Average Claim Severity by Driver Age",
       y = "Average Cost per Claim (€)", x = "Age Band")


#correlation matrix
num_vars <- df %>%
  select(DrivAge, VehAge, VehPower, BonusMalus, Density)

corrplot(cor(num_vars, use = "complete.obs"),
         method      = "color",
         addCoef.col = "black",
         tl.col      = "black",
         title       = "Correlation Matrix",
         mar         = c(0,0,2,0))



#Phase 3: Feature Engineering
#banding
df <- df %>%
  mutate(DrivAgeBand = cut(DrivAge,
                           breaks = c(18,22,25,30,40,60,100),
                           right  = FALSE,
                           labels = c("18-21","22-24","25-29",
                                      "30-39","40-59","60+")))

df <- df %>%
  mutate(VehAgeBand = cut(VehAge,
                          breaks = c(0,3,5,10,15,100),
                          right  = FALSE,
                          labels = c("0-2","3-4","5-9","10-14","15+")))
table(df$VehAgeBand, useNA = "always")

df <- df %>%
  mutate(VehPower = factor(VehPower))
levels(df$VehPower)
table(df$VehPower)

df <- df %>%
  mutate(Area = factor(Area))

levels(df$Area)
table(df$Area)

df <- df %>%
  mutate(
    DrivAgeBand = relevel((DrivAgeBand), ref = "30-39"),
    VehAgeBand  = relevel((VehAgeBand),  ref = "10-14"),
    VehPower    = relevel((VehPower),     ref = "8"),
    Area        = relevel((Area),         ref = "A")
  )
levels(df$DrivAgeBand)  # "40-59" must be first
levels(df$VehAgeBand)   # "5-9" must be first
levels(df$VehPower)     # "7" must be first
levels(df$Area)         # "A" must be first

#split into frequency and severity datasets
df_freq <- df %>%
  select(IDpol, ClaimNb, Exposure,
         DrivAgeBand, VehAgeBand, VehPower,
         BonusMalus, Area)

df_sev <- df %>%
  filter(ClaimNb > 0, ClaimAmount > 0) %>%
  mutate(AvgClaimCost=ClaimAmount/ClaimNb)%>%
  select(IDpol, ClaimAmount, ClaimNb, AvgClaimCost,
         DrivAgeBand, VehAgeBand, VehPower,
         BonusMalus, Area)

nrow(df_freq)   
nrow(df_sev)    

#dropping na
df_freq<-df_freq%>% filter(complete.cases(.))
df_sev<-df_sev%>% filter(complete.cases(.))



#Phase 4: Poisson GLM (Frequency)
#fitting poisson glm
glm_freq<-glm(ClaimNb~DrivAgeBand+BonusMalus+VehPower+VehAgeBand+Area,
              family=poisson(link="log"),
              offset=log(Exposure),
              data=df_freq)
AIC(glm_freq)
summary(glm_freq)
round(exp(coef(glm_freq)),4)


#check significance
coef_summary<-summary(glm_freq)$coefficients
coef_summary[coef_summary[,4]>0.05,]

# Pseudo R-squared (deviance explained)
null_dev <- glm_freq$null.deviance
res_dev  <- glm_freq$deviance

pseudo_r2 <- 1 - (res_dev / null_dev)
round(pseudo_r2 * 100, 3)


#check for overdispersion
dispersion <- glm_freq$deviance / glm_freq$df.residual
round(dispersion, 3)


#generating prediced frequecies
df_freq <- df_freq %>%
  mutate(PredFreq = predict(glm_freq, type = "response") / Exposure)

#check — weighted average should match portfolio benchmark
#Predicted avg frequency
round(sum(df_freq$PredFreq * df_freq$Exposure)/sum(df_freq$Exposure),6)
#Actual avg frequency
round(sum(df_freq$ClaimNb) / sum(df_freq$Exposure), 4)



#Phase 5: Gamma GLM (Severity)
#fit gamma glm
glm_sev<-glm(AvgClaimCost~DrivAgeBand+ BonusMalus+ VehPower+ VehAgeBand + Area,
             family=Gamma(link="log"),
             data=df_sev)
summary(glm_sev)
round(exp(coef(glm_sev)),4)

#checking p values
sev_coef_summary<-summary(glm_sev)$coefficients
sev_coef_summary[sev_coef_summary[,4]>0.05,]

#deviance explained
sev_pseudor<-1-(glm_sev$deviance/glm_sev$null.deviance)
round(sev_pseudor*100,2)

#generating predicted severities
df_sev<-df_sev%>%
  mutate(Predsev=predict(glm_sev,type="response"))

#check
#predicted avg severity
round(mean(df_sev$Predsev),0)
#actual avg severity
round(mean(df_sev$AvgClaimCost),0)

#plot of average vs predicted
df_sev%>%
  group_by(DrivAgeBand)%>%
  summarise(
    Actual=mean(AvgClaimCost),
    Predicted=mean(Predsev)
  )%>%
  pivot_longer(cols=c(Actual,Predicted))%>%
  ggplot(aes(x=DrivAgeBand, y=value, fill=name))+
  geom_col(position="dodge")+
  labs(title = "Actual vs Predicted Severity by Driver Age",
       y = "Average Cost per Claim (€)", fill = "")


# Build comparison table
freq_relativ <- round(exp(coef(glm_freq)), 4)
sev_relativ  <- round(exp(coef(glm_sev)), 4)

# Extract DrivAge bands only
drivage_comparison <- data.frame(
  Band      = c("18-21","22-24","25-29","40-59","60+"),
  Frequency = freq_relativ[paste0("DrivAgeBand", c("18-21","22-24","25-29","40-59","60+"))],
  Severity  = sev_relativ[paste0("DrivAgeBand", c("18-21","22-24","25-29","40-59","60+"))]
)

drivage_comparison



#Phase 6 : Pure Premium
#pure premium
df_final <- df_freq %>%
  mutate(PredSev = predict(glm_sev, 
                           newdata = df_freq,   
                           type    = "response"))

summary(df_final$PredSev)

df_final<-df_final%>%
  mutate(purePrem=PredFreq*PredSev)
summary(df_final$purePrem)

actual_pp <- sum(df$ClaimAmount) / sum(df$Exposure)
actual_pp
predicted_pp <- sum(df_final$purePrem * df_final$Exposure) / sum(df_final$Exposure)
predicted_pp

