********************************************************************************
********************************* RDD EXAMPLE **********************************
********************************************************************************

global dir "/Users/jaakko/Dropbox/teaching/research_seminar_S2020/seminar_s2020/stata_examples"

use "$dir/data/HMSTT_data_22082017.dta", clear

// The data comes from the replication files of Hyytinen et al. (2018) "When Does
// Regression Discontinuity Design Work? Evidence from Random Election Outcomes,"
// published in Quantitative Economics. You can download these data following the
// link on Canvas.

********************************************************************************

// In this example, we will estimate the impact of getting elected today on
// getting elected in the next election. In many contexts, incumbents tend to
// outperform the nonincumbent challengers (``incumbency advantage'').

// We will be using data from Finnish local government elections in this example.
// One curiosity about the Finnish electoral system is that each voter has to cast
// a vote directly to a candidate with some party affiliation. Out of these candidates,
// 13-85 people get elected depending on their personal and party total votes (and the
// votes of other parties).

// Council seats are first distributed to parties based on their total votes. Within
// the parties, seats are allocated to individual candidates based on their personal
// votes. Sometimes, two or more candidates tie in votes for the last seat that a
// party acquires. Then, a lottery decides who gets elected.

// We will use these lotteries to causally estimate the effects of election. This is,
// in fact, what regression discontinuity design targets! Let us in particular see
// if RDD is able to recover the experimental benchmark and when...

********************************************************************************

* Lottery analysis

reg electednextelection 1.elected if vmargin == 0, cluster(munid)

// No personal incumbency advantage in the lotteries. What does the RDD say?

********************************************************************************

* Install rdrobust package

ssc install rdrobust, replace

********************************************************************************

* What does the RDD graph look like? Let us plot local linear and local quadratic
* fits within the optimal bandwidth for the local linear specification

rdbwselect electednextelection vmargin if vmargin!=0, p(1)
local h_MSE=e(h_mserd)

binscatter electednextelection vmargin if abs(vmargin)<=`h_MSE' & vmargin!=0, line(lfit) ///
	rd(0)

* The graph suggests a jump -- however, there appears to be curvature close to the
* cutoff that the linear polynomial does not adjust to...

rdbwselect electednextelection vmargin if vmargin!=0, p(1)
local h_MSE=e(h_mserd)

binscatter electednextelection vmargin if abs(vmargin)<=`h_MSE' & vmargin!=0, line(qfit)

* The jump goes away when we use a quadratic fit! Fitting a polynomial p+1 within
* the optimal bandwidth for p is what Calonico et al. call the bias-corrected robust
* approach.

********************************************************************************

* Run RDD regressions - local linear estimation with MSE-optimal bandwidth

est clear // clear the stored estimates

eststo: rdrobust electednextelection vmargin if vmargin!=0, p(1) all rho(1) vce(cluster munid)

* Try also local quadratic and local cubic specifications

eststo: rdrobust electednextelection vmargin if vmargin!=0, p(2) all rho(1) vce(cluster munid)
eststo: rdrobust electednextelection vmargin if vmargin!=0, p(3) all rho(1) vce(cluster munid)

* Print the results from RDD

esttab est1 est2 est3, b(%9.3f) se(%9.3f) scalar(N_h_l N_h_r h_l) sfmt(%9.0f %9.2f %9.2f) star(* 0.1 ** 0.05 *** 0.01) nogaps nomtitles brackets keep(Conventional Robust)

* Also p = 2 and p = 3 seem to perform poorly (in terms of recovering the experimental
* benchmark) when using larger bandwidths.

/*

* It's useful to know how to create Latex tables on Stata! Below a quick example of
* how you could do that in this context. You may need to install additional packages.

* Export RDD results in .tex format

esttab est1 est2 est3 using "$dir/tables/rdd_v1.tex", replace b(%9.3f) se(%9.3f) scalar(N_h_l N_h_r h_l) sfmt(%9.0f %9.2f %9.2f) star(* 0.1 ** 0.05 *** 0.01) nogaps nomtitles brackets keep(Conventional Robust)

* Export RDD results in a nicer-looking 

esttab est1 est2 est3 using "$dir/tables/rdd_v2.tex", replace booktabs mlabels(none) ///
	mgroups("Linear" "Quadratic" "Cubic", pattern(1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}) ) ///
	compress lines star(* .1 ** .05 *** .01) label ///
	b(%9.3f) se(%9.3f) stats(N_h_l N_h_r h_l, labels("\textit{N} (left of cutoff)" "\textit{N} (right of cutoff)" "Bandwidth") ///
	fmt(0 0 2)) nodepvars nomtitle keep(Conventional Robust) ///
	prehead(\begin{tabular}{l*{4}{c}} \toprule) ///
	postfoot(\bottomrule \end{tabular})
	
*/

********************************************************************************

* Global polynomials are a terrible idea!!!

est clear

eststo: reg electednextelection c.vmargin##1.elected if vmargin != 0, cluster(munid) // Linear
eststo: reg electednextelection c.vmargin##c.vmargin##1.elected if vmargin != 0, cluster(munid) // Quadratic
eststo: reg electednextelection c.vmargin##c.vmargin##c.vmargin##1.elected if vmargin != 0, cluster(munid) // Cubic
eststo: reg electednextelection c.vmargin##c.vmargin##c.vmargin##c.vmargin##1.elected if vmargin != 0, cluster(munid) // Quartic
eststo: reg electednextelection c.vmargin##c.vmargin##c.vmargin##c.vmargin##c.vmargin##1.elected if vmargin != 0, cluster(munid) // Quintic

esttab est1 est2 est3 est4 est5, b(%9.3f) se(%9.3f) scalar(N) sfmt(%9.0f %9.2f %9.2f) star(* 0.1 ** 0.05 *** 0.01) nogaps nomtitles brackets keep(1.elected)

* RDD estimates acquired using global polynomials drastically differ from the experimental
* benchmark estimates of the personal incumbency advantage. Why? Give a large weight
* to observations far away from the cutoff, adjust poorly to curvature close to the
* cutoff?

********************************************************************************

* Replication data and code for Hyytinen et al. (2018) contains some other useful
* things for doing RDDs -- density tests, robustness to alternative bandwidths,
* placebo cutoff tests... etc. You can download the replication materials here:
* 
