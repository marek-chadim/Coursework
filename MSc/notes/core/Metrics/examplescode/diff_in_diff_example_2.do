********************************************************************************
***************** A DYNAMIC DIFFERENCE-IN-DIFFERENCES EXAMPLE ******************
********************************************************************************

// In this example, we will reproduce one of the main results in a paper by Gutiérrez,
// Rubli, and Meriläinen. They study the impact of exposure to the H1N1 pandemic in
// Mexico on the performance of the incumbent party, PAN. Theories of retrospective
// voting suggest that voters punish the incumbent government when they are hit with
// a negative shock. Gutiérrez et al. measure H1N1 exposure by excess  acute
// respiratory infection diagnoses that occurred during a period before the Mexican
// federal election of 2009. They estimate a difference-in-differences model using
// data from electoral sections, the smallest geographical unit used for election
// purposes. Each electoral section is matched with information on excess ARI cases
// from the closes healthcare facility. Gutiérrez et al. find a negative impact.
// They present further evidence suggesting that the punishment was not irrational
// but rather driven by voters using the pandemic exposure to learn something about
// incumbent competence.

global dir "/Users/jaakko/Dropbox/teaching/fall_2023/econometrics/stata_examples/data"

* Open the data

use "$dir/GMR_data_main.dta", clear

********************************************************************************

* H1N1 and electoral performance of the incumbent

egen munid=group(estado municipio) // generate municipality identifiers
egen cluster=group(clues) // generate a variable for clusters

gen a=1 if change_ari!=. & PAN_voteshare!=. // NB. The analyses in the main text use a balanced panel
bysort id: egen sum_a=sum(a) 
drop if sum_a<6

est clear

reghdfe PAN_voteshare ib2006.year##c.change_ari, absorb(id munid#year) cluster(cluster)

local N1 = e(N)
local N2 = `N1'/6
local N3 = e(N_clust)
coefplot, vertical scheme(plotplain) keep(1997.year#c.c* 2000.year#c.c* 2003.year#c.c* 2006.year 2009.year#c.c* 2012.year#c.c*) ///
	omitted baselevels order(1997.year#c.c* 2000.year#c.c* 2003.year#c.c* 2006.year 2009.year#c.c* 2012.year#c.c*) ///
	coeflabels(1997.year#c.c* = "1997" 2000.year#c.c* = "2000" 2003.year#c.c* = "2003" 2006.year = "2006" 2009.year#c.c* = "2009" 2012.year#c.c* = "2012") ///
	ylabel(,format(%9.2f)) ytitle("Effect of excess cases (1000s)") xtitle("Election") note("Number of observations = `N1'" "Number of sections = `N2'" "Number of clusters = `N3'") yline(0) mlabposition(1) mlabel(string(@b,"%9.3f")) subtitle("Excess cases and PAN vote share", position(11))

test i1997.year#c.change_ari i2000.year#c.change_ari i2003.year#c.change_ari // joint significance of pre-treatment coefficients
test i2009.year#c.change_ari i2012.year#c.change_ari // joint significance of post-treatment coefficients
