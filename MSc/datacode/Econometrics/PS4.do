********************************************************************************
******************** 5304 Econometrics Autumn 2023 PS4	  	 *******************
******************** G15: Xuan Min, Dylan, Elias, Marek      *******************
********************************************************************************

/*For the first part of this assignment, we use the data set from Angrist and Lavy (1999). In this paper, the authors investigate the impact of class size on student test performance for fourth-and fifth graders in Israel.,In particular, the twelfth century rabbinic scholar Maimonides proposed a maximum class size of 40 (known as Maimonides' rule) which still lives on today. This rule creates a nonlinear relationship between cohort size, i.e. the number of incoming students in a school year, and actual class size. For example, 40 incoming students should in principle result in one big class, while the addition of one additional students splits the cohort into two classes of (on average) 20.5 students each. We will focus on the sample of fifth graders, which is available in the data set PS4_AngristLavy99.dta.*/

********************************************************************************
*********************** PRELIMINARIES AND LOADING DATA *************************
********************************************************************************
cap log close
log using "PS4G15", replace 

clear all
set more off
global root "C:\Users\chadi\Dropbox\Econometrics\PS4"
capture mkdir ".\Output"
global output "$root\Output"

* Loading data
use "PS4_AngristLavy99", clear

********************************************************************************
**************************  Part 1: IVs in practice  ***************************
********************************************************************************

*1.  Restrict the sample to include only schools with cohort sizes below 160. Plot a linear relationship between actual class size and cohort size, allowing for discontinuities at 41, 81 and 121. Do schools appear to follow Maimonides' rule in class division? Hint: use "binscatter" and its RD option.

browse
describe
keep if cohort_size  <160

*first stage
binscatter classize cohort_size , rd(41 81 121) xtitle("Cohort size") ytitle("Class size") 
graph export "$output/firststage.pdf", as(pdf) replace 

*2. Plot the same kind of relationship as in (2), but now with average reading and math scores on the y-axis, respectively, and discuss briefly what you find.

*reduced forms
binscatter avgverb cohort_size, rd(41,81,121) name(verbscatter, replace) xtitle("Cohort size") ytitle("Average reading scores") 
binscatter avgmath cohort_size, rd(41,81,121) name(mathscatter, replace) xtitle("Cohort size") ytitle("Average math scores") 

graph combine verbscatter mathscatter, row(2) graphregion(color(white))

graph export "$output/reducedform.pdf", as(pdf) replace 

/*We are now going to depart from the exact methodology used in Angrist and Lavy (1999), but the general takeaways are the same. In (1) and (2), you have investigated the first stage and reduced form relationships in a fuzzy regression discontinuity design.2 Now we are going to estimate the effect of class size on test scores with 2SLS, using the discontinuous nature of Maimonides' rule as an instrument. */
	     
*3. Let us focus only on the cutoff around 41 – restrict the sample to only include cohort sizes between 0 and 80.

keep if cohort_size >= 0 & cohort_size <= 80
sum cohort_size


*4. Generate a new variable of the following form:Cohort_Recentered = Cohort_Size − 41. This is simply the cohort size of a given school centered at 41. Further, generate a dummy variable (Above) that equals 1 if a school has a cohort size equal to or greater than 41. Now, write down the following two equations: (i) the first stage equation of class size on the Above dummy as well as the running variable (Cohort_Recentered), allowing the running variable to have different slopes on each side of the cutoff, and (ii) the reduced form equation of math scores on the same variables. Denote the coefficients on Above as γ1 and π1 in the first stage and reduced form equations, respectively. Show the regression estimates of the two equations in a table. What is the interpretation of γ1 and π1? Why do you think we center the cohort size variable at 41, so that it is equal to zero when the discontinuity occurs? Hint: it only simplifies interpretation of the coefficients. Try running the same regressions without re-centering and see what happens!

gen cohort_recentered = cohort_size - 41
gen above = cond(cohort_recentered >= 0,1,0)


est clear

*first stage 
reg classize i.above##c.cohort_recentered, robust cluster(schlcode) 
scalar gamma1 = _b[1.above]
eststo first_stage

*reduced form
reg avgmath i.above##c.cohort_recentered, robust cluster(schlcode) 
scalar pi1 = _b[1.above]
eststo reduced_form

*table
esttab first_stage reduced_form, keep(_cons 1.above cohort_recentered 1.above*c.cohort_recentered) se stats(N , label( "Number of classes")) 

esttab first_stage reduced_form using "$output/regression_table.tex", replace keep(_cons 1.above cohort_recentered 1.above*c.cohort_recentered) se stats(N , label( "Number of classes")) 


*without re-centering
reg classize i.above##c.cohort_size, robust
reg avgmath i.above##c.cohort_size, robust

*5. Using your estimates from the previous question, compute ˆβ1 = ˆπ1/ˆγ1. Further, run a 2SLS regression with Cohort_Recenteredi and Cohort_Recentered×Abovei as exoge- nous regressors, and class size instrumented by Abovei. Report the estimates in a table. Is the estimated effect of class size on math scores the same as ˆβ1? Even if estimates are the same, why should you always use 2SLS in practice?

*Wald estimate
scalar beta1 = pi1 / gamma1
display gamma1
display "beta1: " beta1


*2SLS
gen abovecohort_recentered = above*cohort_recentered
ivreg2 avgmath cohort_recentered abovecohort_recentered (classize = above), robust cluster(schlcode) 
eststo tsls

esttab tsls, label se stats(N , label( "Number of classes")) 
esttab tsls using "$output/regression_table2.tex", replace label se stats(N , label( "Number of classes"))  
save "results", replace

