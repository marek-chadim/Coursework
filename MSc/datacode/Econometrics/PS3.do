********************************************************************************
******************** 5304 Econometrics Autumn 2023 PS3	  	 *******************
******************** G15: Xuan Min, Dylan, Elias, Marek      *******************
********************************************************************************

/*The dataset from this assignment comes from Campante and Do (2014), which investigates whether corruption increases if the capital city of a U.S. state is "isolated", in the sense of being located far from the most populous regions of the state.2 The idea here, is that state capitals that are geographically far from the populous regions are subject to less scrutiny and accountability, which increases the likelihood of corruption. In this assignment, we are going to go through their identification strategy step by step.*/

********************************************************************************
*********************** PRELIMINARIES AND LOADING DATA *************************
********************************************************************************

clear all
set more off
global root "C:\Users\chadi\Dropbox\Econometrics\PS3"
capture mkdir ".\Output"
global output "$root\Output"
log using "PS3G15", replace 

* Loading data
use "PS3_Campante2014.dta", clear

********************************************************************************
**************************  Part 1: IVs in practice  ***************************
********************************************************************************

*1. The data is a panel starting in 1970. In this analysis, we are going to use geographical information about city location, which has not changed since the start of the panel. Hence, we restrict our current analysis only to the year of 1970 – drop all other years.

keep if year == 1970

*2. Plot the relationship between corruption and ALDmean1970, which is the average log distance of the population from the state capital city, in a scatter plot with a fitted line. What is the slope of the line? What does this imply about the relationship between state capital isolation and corruption, and what might be possible sources of omitted variable bias in this "naïve" specification?

twoway (scatter corruptrate_avg ALDmean1970, mlabel(state_code) xtitle("Average Log Distance")legend(label(1 "Corruption")))(lfit corruptrate_avg ALDmean1970 )

graph export "$output/scatter.pdf", as(pdf) replace 

/*graph twoway ///
	(scatter corruptrate_avg ALDmean1970, mlabel(state_code) ) ///
	(lfit corruptrate_avg ALDmean1970, lwidth(medthick) color(blue)), ///
	scheme(swift_red) graphregion(color(white)) /// 
	xtitle("Distance from state capital") ytitle("Corruption rate") /// 
	title("State capital distance and corruption relationship") /// 
	legend(label(1 "Scatterplot") label(2 "Linear fit")) */
	   
reg corruptrate_avg ALDmean1970
scalar slope = _b[ALDmean1970]
display "Slope of the fitted line is " slope "

*One unit increase in the average log distance of the population from the state capital city is associated with a 0.44 unit increase the average corruption rate.

*The location of the capital city is an institutional decision and it affects the spatial distribution of population. Both of these could be correlated with omitted variables that are also associated with corruption. For instance, corruption and the location of the capital city could be jointly determined, with relatively corrupt states choosing to isolate their capital cities. Alternatively, it could be the case that corruption affects the population flows that determine how isolated the capital city will ultimately be, by pushing economic activity and population away from the capital. 

*3. In order to address endogeneity issues, the author proposes the following IV strategy: while the exact location of state capital cities are likely endogenous, the norm was to place them close to the center of the state for political reasons unrelated to other factors. If the location of thecenter of a state (called the state centroid) is exogenous, there is a plausible instrument: the average log distance of the population from the state centroid, centr_ALDmean1970.In the paper, the author makes the point that it is crucial for the validity of the instrument to control for the average size and shape of the state. Why?


*The authors argue that the centroid is an essentially arbitrary location and should not affect any relevant outcomes in and of itself once the territorial limits of each state are set. Because of that, they eventually control, in all of their specifications, for the geographical size of the state, to guard against the possibility that a correlation between omitted variables and the expansion or rearrangement of state borders might affect the results

*4. Report the following estimations in a table: 1) the naïve OLS regression of corruption on ALDmean1970, 2) the first stage and 2SLS estimate of corruption on ALDmean1970, using centr_ALDmean1970 as an instrument, with and without controlling for state size (logarea) and shape (logMaxDistSt). Write out the specifications of the OLS (without controls), as well as the first and second stage equations of the 2SLS (with controls).

* Naïve OLS Regression
reg corruptrate_avg ALDmean1970, robust
estimates store ols
estadd local Controls "No"

* First stage regression without controls
reg ALDmean1970 centr_ALDmean1970, robust
estimates store first_stage_no_controls
estadd local Controls "No"

* First stage regression with controls
reg ALDmean1970 centr_ALDmean1970 logarea logMaxDist, robust
estimates store first_stage_with_controls
estadd local Controls "Yes"

* Second stage (2SLS) regression without controls
ivreg2 corruptrate_avg (ALDmean1970 = centr_ALDmean1970), robust 
estimates store second_stage_no_controls
estadd local Controls "No"

* Second stage (2SLS) regression with controls
ivreg2 corruptrate_avg (ALDmean1970 = centr_ALDmean1970) logarea logMaxDist, robust
estimates store second_stage_with_controls
estadd local Controls "Yes"

* Table of regression results
esttab ols first_stage_no_controls  second_stage_no_controls first_stage_with_controls second_stage_with_controls, mtitles("OLS" "1st stage" "2SLS" "1st stage" "2SLS") replace label se ///
keep ("ALDmean1970" "centr_ALDmean1970") ///
stats(Controls N r2 F, label("Controls" "Observations" "R-squared" "F-statistic")) ///
	addnotes("Robust standard errors in brackets. Dependent variable: Corruption = federal convictions for corruption-related crime relative to population, average 1976–2002. Independent variable: Average log distance of the population from the state capital city,  IV: Average log distance of the population from the state centroid, Control variables Average size and shape3 of the state.") ///
title("Corruption and Isolation of the Capital City")

esttab ols first_stage_no_controls second_stage_no_controls first_stage_with_controls second_stage_with_controls using "$output\regression_table.tex", mtitles("OLS" "1st stage" "2SLS" "1st stage" "2SLS") replace label se ///
keep ("ALDmean1970" "centr_ALDmean1970") ///
stats(Controls N r2 F, label("Controls" "Observations" "R-squared" "F-statistic")) ///
	addnotes("Robust standard errors in brackets. Dependent variable: Corruption = federal convictions for corruption-related crime relative to population, average 1976–2002. Independent variable: Average log distance of the population from the state capital city,  IV: Average log distance of the population from the state centroid, Control variables Average size and shape3 of the state.") ///
title("Corruption and Isolation of the Capital City")

*5. Interpret the coefficient on isolation of the state centroid in the first stage (what does it mean intuitively?). Does the instrument seem to be relevant?

*  0.948*** (0.0572) without and 1.185*** (0.322) with controls show that centr_ALDmean1970 is indeed a significant predictor of ALDmean1970

*6. Interpret the 2SLS estimates (focus on the signs). How do they differ from the OLS estimate? Does the controls seem to matter in this case?

* OLS without controls 0.444** (0.140) > 2SLS without controls  0.187 (0.132) (not significant)
* OLS without controls 0.444** (0.140) < 2SLS with controls  1.169** (0.417)

* controls matter                           

*7. A friend points out that an IV analysis with only 48 observations might not be very credible – in particular, the result could be very sensitive to outliers. Conduct a leave- one-out analysis: make a loop of 48 iterations that, for each iteration, excludes one of the states and runs the full IV specification (with controls) and stores the point estimate. What is the range of point estimates that you obtain? Does the result seem to be sensitive to single outliers?

*exclude states with missing values
misstable  summarize, generate(miss_)
drop if miss_centr_ALDmean1970 == 1

*generate empty matrix to store estimates
mat def storage = J(48, 1, .)

*run regressions
forvalues i =1(1)48{
	qui: ivreg2 corruptrate_avg (ALDmean1970 = centr_ALDmean1970) logarea logMaxDist if _n!=`i', robust
	mat storage[`i',1]=_b[ALDmean1970]
}

*summarize
matrix list storage
svmat storage
sum storage

scalar max = r(max)
scalar min = r(min)
scalar range = max - min

display "The range of point estimates is " range

graph box storage1
ttest storage1 == 1.169
* results robust to single outliers


save "results", replace

