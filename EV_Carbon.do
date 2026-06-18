clear all 
set more off
set maxvar 30000, permanently 
cd "D:\desktop\research\electric vehicle\Code and Data"

**Descriptive statistics Table S1
use EV_Carbon, clear
estpost summarize co2 sales gdp popu temp stp wdsp prcp flowin flowout stnum r2001 fossilele
esttab using sum.xls, cells(" count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) max(fmt(%12.2f))") title("Descriptive Statistics") replace

**benchmark Table1 
clear all
use EV_Carbon,clear
xtset id ym
xtreg lnco2 ln_ev i.ym, fe vce(cluster id) 
est store result01
xtreg lnco2  ln_ev lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout i.ym i.id_pro#year, fe vce(cluster id)
est store result02
xtreg ln_ev lnstn lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout i.ym, fe vce(cluster id)
est store result03
ivreghdfe lnco2 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn), absorb (id ym) cluster (id)
est store result04
outreg2 [result01 result02 result03 result04] using benchmark.doc, replace

**mechanism Table 2
use EV_Carbon, clear
xtset id ym

ivreghdfe lnco2 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn), absorb (id ym) cluster (id)
est store ivreg
ivreghdfe lnfossilele lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn), absorb (id ym) cluster (id)
est store pathway1
ivreghdfe lnflowin lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowout (ln_ev =lnstn), absorb (id ym) cluster (id)
est store pathway2
outreg2 [ivreg pathway1 pathway2] using mechanism.doc, replace

**Heterogeneity regions Table 4
use EV_Carbon,clear
xtset id ym
gen area=""

replace area = "East" if inlist(province, "Beijing", "Tianjin", "Hebei", "Shanghai", "Jiangsu","Zhejiang")
replace area = "East" if inlist(province, "Fujian", "Shandong", "Guangdong", "Hainan")
replace area = "Central" if inlist(province, "Shanxi", "Anhui", "Jiangxi", "Henan", "Hubei", "Hunan","Inner Mongolia")
replace area = "West" if inlist(province, "Guangxi", "Chongqing", "Sichuan", "Guizhou", "Yunnan","Shaanxi")
replace area = "West" if inlist(province, "Tibet", "Gansu", "Qinghai", "Ningxia", "Xinjiang")

ivreghdfe lnco2 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn)  if area == "East", absorb (id ym) cluster(ym)
est store East
ivreghdfe lnco2 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn)  if area == "Central", absorb (id ym) cluster(ym)
est store Central
ivreghdfe lnco2 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn)  if area == "West", absorb (id ym) cluster(ym)
est store West
outreg2 [East Cnetral West] using regions.doc, replace

**Heterogeneity cleanratio Table S2
use EV_Carbon,clear
xtset id ym

ivreghdfe lnco2 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn)  if  cleanratio<=0.2, absorb (id ym) cluster (id)
est store c1
ivreghdfe lnco2 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn)  if  cleanratio>0.2 & cleanratio<0.5, absorb (id ym) cluster (id)
est store c2
ivreghdfe lnco2 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn)  if  cleanratio>=0.5, absorb (id ym) cluster (id)
est store c3
outreg2 [c1 c2 c3] using clean.doc, replace

**Heterogeneity capacity Table S3 columns (1) & (2)
reghdfe lnco2 ln_ev lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout if capacitymw<300, absorb (id ym) vce(cluster id)
est store lowcap
reghdfe lnco2 ln_ev lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout if capacitymw>=300, absorb (id ym) vce(cluster id)
est store highcap 

**Heterogeneity income Table S3 columns (3) & (4)
gen per_gdp = gdp/popu
egen median_gdp = median(per_gdp)
reghdfe lnco2 ln_ev lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout if per_gdp<median_gdp, absorb (id ym) vce(cluster id)
est store lowincome
reghdfe lnco2 ln_ev lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout if per_gdp>=median_gdp, absorb (id ym) vce(cluster id)
est store highincome
outreg2 [lowcap highcap lowincome highincome] using hetero.doc, replace

**Table S4 DML
set python_exec D:\python\python.exe
use EV_Carbon, clear
global Y lnco2 
global X lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout i.ym i.id 
global D ln_ev 
set seed 42 
ddml init partial, kfolds(2)  
*Random forest
ddml E[D|X]: pystacked $D $X, type(reg) method(rf) 
ddml E[Y|X]: pystacked $Y $X, type(reg) method(rf) 
ddml crossfit
ddml estimate, cluster(id)
*Support vector mechine
use EV_Carbon, clear
global Y lnco2 
global X lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout i.ym i.id 
global D ln_ev 
set seed 42 
ddml init partial, kfolds(2)  
ddml E[D|X]: pystacked $D $X, type(reg) method(svm) 
ddml E[Y|X]: pystacked $Y $X, type(reg) method(svm) 
ddml crossfit
ddml estimate, cluster(id)
*Gradient boosting
use EV_Carbon, clear
global Y lnco2 
global X lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout i.ym i.id 
global D ln_ev 
set seed 42 
ddml init partial, kfolds(2)  
ddml E[D|X]: pystacked $D $X, type(reg) method(gradboost) 
ddml E[Y|X]: pystacked $Y $X, type(reg) method(gradboost) 
ddml crossfit
ddml estimate, cluster(id)
*Neural net
use EV_Carbon, clear
global Y lnco2 
global X lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout i.ym i.id 
global D ln_ev 
set seed 42 
ddml init partial, kfolds(2)  
ddml E[D|X]: pystacked $D $X, type(reg) method(nnet) 
ddml E[Y|X]: pystacked $Y $X, type(reg) method(nnet) 
ddml crossfit
ddml estimate, cluster(id)

**Table S5
use EV_Carbon, clear

ivreghdfe lnn2o lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn), absorb (id ym) cluster (id)
est store n2o
ivreghdfe lnch4 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn), absorb (id ym) cluster (id)
est store ch4
ivreghdfe lnghg lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn), absorb (id ym) cluster (id)
est store ghg
ivreghdfe lnco2m lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn), absorb (id ym) cluster (id)
est store co2m
outreg2 [n2o ch4 ghg co2m] using sub.doc, replace 

**Saptial regression Table3 Columns (1) and (2)
clear all
use EV_Carbon, clear
xtset id ym
xtbalance, range(684,755)
duplicates drop id, force
spwmatrix gecon latitude longitude, wn(wbin) wtype(inv) alpha(1) db(0 500) rowstand
svmat wbin
save web1, replace 
use EV_Carbon, clear
xtset id ym
xtbalance, range(684 755)

foreach var in temp lnpopu lngdp lnstp lnwdsp lnprcp lnflowin lnflowout {
	bysort ym: egen `var'_mean = mean(`var')
    replace `var' = `var'_mean if missing(`var')
    drop `var'_mean
}
save spreg, replace
//LM test Table S6
use web1, clear
spmat dta web1 wbin*, id(id) normalize(row)
spcs2xt wbin*, matrix(kuoda) time(72)
spatwmat using kuodaxt, name(W)
use spreg, clear 
xtset id ym
reg lnco2 ln_ev temp lnpopu lngdp lnstp lnwdsp lnprcp lnflowin lnflowout
spatdiag, weights(W)
//spatial regression 
clear all
use web1, clear
spmat dta web1 wbin*, id(id) normalize(row)
use spreg, clear 
xtset id ym
xsmle lnco2 ln_ev temp lnpopu lngdp lnstp lnwdsp lnprcp lnflowin lnflowout, wmat(web1) fe type(both,leeyu) model(sar) cluster(id)
est store sar
xsmle lnco2 ln_ev temp lnpopu lngdp lnstp lnwdsp lnprcp lnflowin lnflowout, emat(web1) fe type(both,leeyu) model(sem) cluster(id)
est store sem
outreg2 [sar sem] using spreg.doc, replace

spxtregress lnco2 ln_ev temp lnpopu lngdp lnstp lnwdsp lnprcp lnflowin lnflowout, dvarlag(w) fe 
help spxtregress
spxtregress y x1 x2, fe dvarlag(web1)
estat lmdiag

**Saptial regression Table3 Colomns (3) and (4)
clear all
use EV_Carbon, clear
xtset id ym
xtbalance, range(684 755)
duplicates drop id, force
spwmatrix gecon latitude longitude, wn(web2) wtype(bin) db(0 500) rowstand
svmat web2
save web2, replace
use EV_Carbon, clear
xtset id ym
xtbalance, range(684 755)
foreach var in temp lnpopu lngdp lnstp lnwdsp lnprcp lnflowin lnflowout {
	bysort ym: egen `var'_mean = mean(`var')
    replace `var' = `var'_mean if missing(`var')
    drop `var'_mean
}
save spreg2, replace 
//LM test
use web2
spmat dta web2 web2*, id(id) normalize(row)
spcs2xt web2*, matrix(kuoda2) time(72)
spatwmat using kuoda2xt, name(W)
use spreg2, clear 
xtset id ym
reg lnco2 ln_ev temp lnpopu lngdp lnstp lnwdsp lnprcp lnflowin lnflowout
spatdiag, weights(W)
//spatial regression
clear all
use web2
spmat dta web2 web2*, id(id) normalize(row)
use spreg2, clear
xtset id ym
xsmle lnco2 ln_ev temp lnpopu lngdp lnstp lnwdsp lnprcp lnflowin lnflowout, wmat(web2) fe type(both,leeyu) model(sar) cluster(id)
est store sar
xsmle lnco2 ln_ev temp lnpopu lngdp lnstp lnwdsp lnprcp lnflowin lnflowout, emat(web2) fe type(both,leeyu) model(sem) cluster(id)
est store sem
outreg2 [sar sem] using web.doc, replace


**scenario analysis Figure3
use EV_Carbon, clear

collapse (sum) co2 (mean) ev_ratio cleanratio lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout lnstn, by(city year month) 
replace co2=co2/1000
reghdfe co2 c.ev_ratio##c.cleanratio lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout, absorb (city year month) cluster(city)

clear
set obs 21
gen ev_ratio = (_n - 1)/20
tempfile evs
save `evs'

clear
set obs 21
gen cleanratio = (_n - 1)/20
tempfile cleans
save `cleans'

use `evs', clear
cross using `cleans'
gen yhat = _b[_cons] ///
          + _b[ev_ratio]*ev_ratio ///
          + _b[cleanratio]*cleanratio ///
          + _b[c.ev_ratio#c.cleanratio]*ev_ratio*cleanratio
twoway (contour yhat cleanratio ev_ratio, levels(15)), ///
    title("Predicted lnCO2 by EV ratio and Clean ratio") ///
    xtitle("Clean Ratio") ytitle("EV Ratio") ///
    scheme(s2color)	
	
**data for figure1 panel c (using excel in paper)
use EV_Carbon, clear
collapse (sum) co2 sales, by (ym)
twoway (line co2 ym, lcolor(blue) lwidth(medium) lpattern(solid)) ///
       (line sales ym, lcolor(red) lwidth(medium) lpattern(dash)), ///
       legend(order(1 "Total CO2" 2 "Total Sales")) ///
       xlabel(, format(%tm) angle(45)) ///
       title("Total CO2 and Sales Over Time") ///
       ytitle("Sum") ///
       xtitle("Year-Month") ///
       graphregion(color(white)) ///
       scheme(s1color)
	   
**data for figure 2 panel d (using excel in paper)
use EV_Carbon, clear
collapse (mean) ev_ratio cleanratio, by(ym)
twoway (line ev_ratio ym, lcolor(blue) lwidth(medium) lpattern(solid)) ///
       (line cleanratio ym, lcolor(red) lwidth(medium) lpattern(dash)), ///
       legend(order(1 "EV Ratio" 2 "Clean Ratio")) ///
       xlabel(, format(%tmMon_YY) angle(45)) ///
       title("EV Ratio and Clean Ratio Over Time") ///
       ytitle("Ratio") ///
       xtitle("Year-Month") ///
       graphregion(color(white)) ///
       scheme(s1color)

	   
//sensitive analysis TableS7
use EV_Carbon,clear
xtset id ym
winsor2 lnco2 ln_ev lngdp lnpopu temp lnstp lnwdsp lnprcp, replace cuts(1 99)
ivreghdfe lnco2 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn), absorb (id ym) cluster (id)
est store sens1
winsor2 lnco2 ln_ev lngdp lnpopu temp lnstp lnwdsp lnprcp, replace cuts(5 95)
ivreghdfe lnco2 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =lnstn), absorb (id ym) cluster (id)
est store sens2
egen id_pro=group(province)
ivreghdfe lnco2 lngdp lnpopu temp lnstp lnwdsp lnprcp (ln_ev =lnstn), absorb (id id_pro#year) cluster (id)
est store sens3
outreg2 [sens1 sens2 sens3] using sens.doc, replace

//extriction rules of IV TableS8
use EV_Carbon,clear
xtset id ym
winsor2 lnco2 ln_ev lngdp lnpopu temp lnstp lnwdsp lnprcp lnstn, replace cuts(5 95)
xtreg lnco2 lnstn lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout i.year, fe vce(cluster id)
est store iv1
xtreg lnco2 lnstn ln_ev lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout i.year, fe vce(cluster id)
est store iv2	  
outreg2 [iv1 iv2] using extriction.doc, replace 

//Alternative IV TableS9
use EV_Carbon,clear
xtset id ym
gen iv1=L.ln_ev#r2001
reghdfe ln_ev iv1 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout, absorb (id ym) cluster (id)
est store iv3
ivreghdfe lnco2 lngdp lnpopu temp lnstp lnwdsp lnprcp lnflowin lnflowout (ln_ev =iv1), absorb (id ym) cluster (id)
est store iv4
outreg2 [iv3 iv4] using alteriv.doc, replace 
