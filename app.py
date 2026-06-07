import streamlit as st

st.title("Auto Insurance Premium Calculator")

age=st.selectbox("Driver Age", ["18-21","22-24","25-29","30-39","40-59","60+"])
bm=st.slider("BonusMalus Score", 50,150,60)
veh_age=st.selectbox("Vehicle Age (years)", ["0-2","3-4","5-9","10-14","15+"])
veh_power=st.selectbox("Vehicle Power", ["4","5","6","7","8","9","10","11","12","13","14","15"])
area=st.selectbox("Area", ["A","B","C","D","E","F"])

freq_age={"18-21":1.341, "22-24":1.0659, "25-29":0.8974, "30-39":1.0,"40-59":1.3444,"60+":1.3178}
sev_age={"18-21":1.7326, "22-24":1.0105, "25-29":1.025, "30-39":1.0,"40-59":0.9522,"60+":1.1.1585}
freq_va={"0-2":1.6044,"3-4":1.0868,"5-9":1.1347,"10-14":1.0,"15+":0.7625}
sev_va={"0-2":1.0688,"3-4":1.0673,"5-9":1.037,"10-14":1.0,"15+":1.0543}
freq_vp={"4":1.068,"5":1.2312,"6":1.2487,"7":1.1896,"8":1.0,"9":1.4319,"10":1.4046,"11":1.2724,"12":1.1066,
         "13":1.1958,"14":1.2934,"15":1.0374}
sev_vp={"4":1.0837,"5":0.9929,"6":1.1673,"7":1.1282,"8":1.0,"9":1.085,"10":1.3129,"11":1.0712,"12":1.4515,
         "13":1.321,"14":1.5683,"15":0.7466}
freq_ar={"A":1.0,"B":1.0524,"C":1.0887,"D":1.1855,"E":1.2585,"F":1.2647}
sev_ar={"A":1.0,"B":0.8617,"C":0.8549,"D":0.9193,"E":0.9244,"F":0.6819}

if st.button("Calculate Premium"):
    bm_excess=bm-60
    freq=0.0135*freq_age[age]*freq_va[veh_age]*freq_vp[veh_power]*freq_ar[area]*(1.0231**bm_excess)
    sev=1578.5276*sev_age[age]*sev_va[veh_age]*sev_vp[veh_power]*sev_ar[area]*(1.0022**bm_excess)
    premium=freq*sev
    st.metric("Pure Premium", f"€{premium:.0f}")
    st.write(f"Frequency: {freq:.4f} claims/year | Severity: €{sev:.0f} per claim")