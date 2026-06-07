# Auto Insurance Premium Calculator

I built this to learn how motor insurance is actually priced. 
The dataset is the French Motor TPL dataset (freMTPL2) — a real industry dataset used in actuarial exams, with 678,013 policies.

## What it does
You enter a driver's age, BonusMalus score, vehicle age, vehicle power, and area. The app calculates an estimated pure premium — the minimum an insurer needs to charge to break even on claims.

## How it works
- Poisson GLM predicts how often a policyholder will claim
- Gamma GLM predicts how much each claim will cost
- Pure premium = frequency × severity
- Python/Streamlit interface applies the model in real time

## Key Findings
- BonusMalus is by far the strongest predictor of claim frequency-each point increase multiplies expected claims by 1.023
- 18-21 year old drivers have 73% more expensive claims than average 
  — not just more frequent ones
- Urban areas have 27% higher claims but 32% lower claim severity than than rural areas 
  — higher traffic but lower speed accidents
- BonusMalus is statistically insignificant for severity (p=0.13) — 
  it predicts frequency only, not claim cost

## Dataset
French Motor TPL — freMTPL2freq and freMTPL2sev  
678,013 policies, 2011-2013  
Source: Kaggle — https://www.kaggle.com/datasets/floser/french-motor-claims-datasets-fremtpl2freq

Note: Data files are not included in this repository. 
Download freMTPL2freq.csv and freMTPL2sev.csv from Kaggle and place them in a /data folder before running the R script.

## Tools
R — tidyverse, ggplot2, corrplot, skimr
Python — streamlit

## Run the app
pip install streamlit  
streamlit run app.py

## Limitations
The model overpredicts pure premium by approximately 34% at portfolio level. 
The relative pricing between policies is correct but the absolute level needs recalibration. BonusMalus also overpredicts at extreme scores above 150, though only 0.03% of policies are affected.
