********************************************************************************
***************** A SIMPLE DIFFERENCE-IN-DIFFERENCES EXAMPLE *******************
********************************************************************************

global dir "/Users/jaakko/Dropbox/teaching/fall_2023/econometrics/stata_examples/data"

* Open the data

use $dir/panel_commune_2008_2010.dta, clear

* Append with the 2006 data

append using $dir/panel_commune_2006.dta

* Mean outcome variable by year and group (treatment & control)

bysort year treatment: egen mean_outcome=mean(goodroadv)

* Plot mean outcome by year and group

twoway (connected mean_outcome year if treatment==0) (connected mean_outcome year if treatment==1), ///
	graphregion(color(white)) xlabel(2006(2)2010) ylabel(,format(%9.2f)) xtitle("Year") ///
	ytitle("Share with 12-month roads") legend(label(1 "Treatment group") label(2 "Control group")) ///
	xline(2009)
	
// NB. The graph suggests that there are maybe issues with the parallel trends assumption...

* Run DD regression without controls (with standard errors clustered at the region level)

reg goodroadv time##treatment, cluster(tinh)

// NB. Other types of standard errors appear to be smaller (recall our discussion
// in Lecture 5)

reg goodroadv time##treatment
reg goodroadv time##treatment, robust

* A more flexible specification that estimates the treatment effect separately for
* each year (relative to 2008)

reg goodroadv ib2008.year##treatment, cluster(tinh)

// NB. The treatment effect for 2006 is indistinguishable from zero -- suggestive
// evidence supporting the parallel trends assumption! However, the figure we plotted
// earlier is a bit concerning.
