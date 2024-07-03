********************************************************************************
************** IV EXAMPLE: ACEMOGLU, JOHNSON, AND ROBINSON (2011) **************
********************************************************************************

clear all

* In this example, we will replicate some results from the paper by Acemoglu,
* Johnson, and Robinson (2011) on settler mortality, property rights, and comparative
* economic development. Follow the link on Canvas to download two files needed for
* replication. These files are "maketable2.dta" and "maketable4.dta".

********************************************************************************

* Set up the working directory

global dir "/Users/jaakko/Dropbox/teaching/research_seminar_S2020/seminar_s2020/stata_examples/"

********************************************************************************

// Let us first run some OLS regressions with and without controls, and let us
// also visualize the relationship a little bit.

* Open the data for this exercise

use "$dir/data/maketable2.dta", clear

* Run a simple OLS regression without control variables (with robust standard errors)

reg logpgp95 avexpr, robust

* Run a simple OLS regression with geographical control variables (with robust standard errors)

reg logpgp95 avexpr africa lat_abst asia, robust

// How would you interpret these results?

* Illustrate the connection graphically
* This is an ugly graph

twoway (scatter logpgp95 avexpr) (lfit logpgp95 avexpr)

* This is a pretty graph (or at least prettier than the graph above...)

ssc install binscatter, replace // We will use the binscatter command to draw a prettier graph

binscatter logpgp95 avexpr, xtitle("Log(GDP per capita, 1995)") ytitle("Average protection against expropriation") // This plots the graph

* Want a cooler color scheme? Here you go:

ssc install schemepack, replace // Install some cool color schemes

binscatter logpgp95 avexpr, xtitle("Log(GDP per capita, 1995)") ytitle("Average protection against expropriation") scheme(swift_red) // This plots the graph using a color scheme inspired by the much-celebrated album "Red" by Taylor Swift

* Save the pretty graph

graph save "$dir/figures/binscatter.gph", replace
graph export "$dir/figures/binscatter.pdf", as(pdf) replace

********************************************************************************

// Let us now move on to the IV analyses.

* Open the data for this exercise

use "$dir/data/maketable4.dta", clear

* Install a package for running IV regressions

ssc install ivreg2, replace

* Run IV regression without controls (with robust standard errors)

ivreg2 logpgp95 (avexpr=logem4), robust

* Run IV regression without controls but also reporting the first stage

ivreg2 logpgp95 (avexpr=logem4), robust first

* Run IV regression with controls (robust standard errors + first stage)

ivreg2 logpgp95 (avexpr=logem4) africa lat_abst asia, robust first

// How would you interpret these results? What is different relative to the OLS?

// NB. Learning how to turn the regression output into pretty tables that you
// can directly incorporate in a .tex file is a useful skill. Check out e.g.
// the esttab and estout commands on Stata (R users may want to check out "stargazer").
// The future you will thank the past you if you choose to learn how to do this!

********************************************************************************

// What about Hausman test mentioned in the lecture notes?

ivreg2 logpgp95 (avexpr=logem4) africa lat_abst asia, robust first endogtest(avexpr)

// Remember: Hausman test compares the IV and OLS estimates to determine whether
// they are "close enough". If they are, there is insufficient evidence to reject
// the null hypothesis --  which states that an OLS estimator of the same equation would yield
// consistent estimates. That is, any endogeneity among the regressors would not
// have deleterious effects on OLS estimates.
