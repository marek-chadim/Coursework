********************************************************************************
******************** 5304 Econometrics Autumn 2023 PS2	  	 *******************
******************** G15: Xuan Min, Dylan, Elias, Marek      *******************
********************************************************************************

********************************************************************************
*********************** PRELIMINARIES AND LOADING DATA *************************
********************************************************************************
clear all
set more off
global root "C:\Users\chadi\Dropbox\5304\PS2"
capture mkdir ".\Output"
global output "$root\Output"
global data "$root\Data"

* Loading data
use "$data\PS1_ANES2020.dta", clear



********************************************************************************
******************  Part 1: OLS and bad controls in practice  ******************
********************************************************************************

******************       Trump voting and unemployment         *****************

*1. Clean the data and generate variables in exactly the same way as you did in PS1
* Dropping duplicates
duplicates drop respondent_id, force
* Donald Trump dummy
drop if !inlist(president_vote,1,2)
gen donald = cond(president_vote==2,1,0)
label variable donald "Voted for Trump"
* Age
drop if !inrange(age,18,80)
label variable age "Age"
* High education dummy
drop if !inrange(education,1,8)
gen high_educ = cond(education >= 6,1,0)
label variable high_educ "Bachelor or higher education"
label define educ 1 "<High School" 2 "High School" 3 "Some college" 4 "Assoc. degree occupational" 5 "Assoc. degree academic" 6 "Bachelor's degree" 7 "Master's degree" 8 "Professional school degree"
label values education educ
* White dummy
drop if race<0
gen white = cond(race==1,1,0)
label variable white "White"
* Did not work last week
keep if working >= 0
recode working (1=0) (2=1)
ren working not_working
label define work 1 "Not working" 0 "Working"
label values not_working work
label variable not_working "Not working/retired"
* Feeling towards conservatives
keep if inrange(conservative,0,100)
lab var conservative "How conservative"

*2. Regress the Trump voter dummy on not working in the last week. Interpret the coefficient.

regress donald not_working, robust

*3. Add age as a control variable. Why do you think the coefficient on not working changes the way it does?

regress donald not_working age, robust

*4. In PS1 you looked at the relationship between Trump voting and age, which turned out not to be linear. Report specifications that control for 1) a quadratic in age and 2) quintiles of age. Interpret what you find in terms of the functional form of age. Hint: for quintiles, use "xtile"

regress donald not_working c.age##c.age, robust

xtile age_quintiles = age, n(5)

regress donald not_working ibn.age_quintiles, robust noconstant


*5 How many percentage points more likely are the second oldest quintile (4th) of respondents to vote Trump compared to the second youngest (2nd), conditional on the not working dummy? Test the hypothesis that the share of Trump voters in these age groups are equal and report the p-value (use robust standard errors). Do the same for the 5th versus the 1st age quintiles (for very small p-values, interpret the value as virtually zero).

scalar b1 = _b[i1.age_quintiles]
scalar b2 = _b[i2.age_quintiles]
scalar b4 = _b[i4.age_quintiles]
scalar b5 = _b[i5.age_quintiles]

display b4-b2
*.07662094

test _b[i2.age_quintiles] = _b[i4.age_quintiles]
*F(  1,  5357) =   12.28
*Prob > F =    0.0005

display b5-b1
*.15537912

test _b[i5.age_quintiles] = _b[i1.age_quintiles]
* F(  1,  5357) =   33.39
* Prob > F =    0.0000


*6 Choose one of the specifications including a non-linear function of age and include the dummy for being white. Write down the regression specification, and run the regression in Stata. Does the estimated coefficient on not working change, and if so, what does the change imply for the correlation between being white and not working (conditional on age)? It is enough to comment on the sign of the correlation and interpreting what this means.

regress donald not_working white c.age##c.age, robust

*_b[not_working] increased from -.0245 to -.0106 by including white dummy and since _b[white]=.2417 the OVB formula implies negative sign of the correlation between not_working and white

********************************************************************************


*******************       Trump voting and education         *******************
*7 Regress Trump voting on the higher education dummy. Why is the estimated coefficient unlikely to have a causal interpretation? Mention several possible sources of bias.

regress donald high_educ, robust

* The relationship between Trump voting and higher education may be influenced by unobservable variables not included in the model. For example, cultural or regional factors that are correlated with both Trump voting and educational attainment could lead to bias in the coefficient estimate. Other factors that are correlated with both Trump voting and educational attainment, such as income, race, or urban vs. rural residence, can introduce bias if not properly controlled for in the analysis.

* Higher education is not randomly assigned to individuals, so individuals who choose to pursue higher education may have different characteristics than those who do not. This self-selection can lead to endogeneity, as individuals' preferences and abilities can influence both their educational choices and their political preferences.

*8 Let's disregard the problems with omitted variable bias you have just brought up. A friend claims that an interesting link between higher education and Trump voting is that education makes people more interested in factual policy, which makes them less likely to vote for Trump no matter their political views.2 However, higher education may also affect people's political views directly due to them being in a particular social milieu. Your friend asks you to isolate the `factual policy' channel between education and Trump voting, holding any potential effect via political ideology constant. Regress Trump voting on high education and a dummy variable that equals one if feeling towards conservatives exceeds 50 and zero otherwise, as a proxy for being conservative

* Conservative dummy
gen mostly_conservative = cond(conservative>50,1,0)
label variable mostly_conservative "Feeling mostly towards conservatives"

eststo: regress donald high_educ mostly_conservative, robust

esttab using "$output/regression_table.tex", replace label se ///
	 nomtitles keep(high_educ mostly_conservative) ///
	stats(N r2, label("Observations" "R-squared")) ///
	
	
*Using a proxy as a control can weaken the causal interpretation of the relationship. In the context our question, if the proxy variable (feeling towards conservatives) is affected by education itself, it becomes an endogenous variable, which complicates the interpretation of causality.

*Measurement error in the variables used in the model, including self-reported conservative feelings or educational attainment, can lead to violations of the Conditional Independence Assumption.


save "results", replace
