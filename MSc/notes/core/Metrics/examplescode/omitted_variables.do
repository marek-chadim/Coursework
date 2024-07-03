********************************************************************************
************************** EXAMPLE: OMITTED VARIABLES **************************
********************************************************************************

// Let us analyze the replication data from Washington (2008)

clear
use "/Users/jaakko/Dropbox/teaching/fall_2023/econometrics/Lecture 4/basic.dta"

********************************************************************************

* Some variable generation/transformations from the replication code of Washington (2008)

gen srvlngsq=srvlng*srvlng
gen agesq=age*age
qui tab totchi, gen(chid)
qui tab region, gen(regd)
qui tab rgroup, gen(reld)

********************************************************************************

* Replication of Table 2

est clear

eststo: reg nowtot ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 chid2-chid11 regd* demvote  if congress==105
*column 2 (table2), column1 (at3)
eststo: reg aauw ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 chid2-chid11 regd* demvote  if congress==105
*column 3 (table2), column3 (at3)
eststo: reg aauw ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 chid2-chid11 regd* demvote  if congress==106
*column 4 (table2), column5 (at3)
eststo: reg aauw ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 chid2-chid11 regd* demvote  if congress==107
*column 5 (table2), column7 (at3)
eststo: reg aauw ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 chid2-chid12 regd* demvote  if congress==108

esttab, keep(ngirls) star(* .1 ** .05 *** .01) b(%9.3f) se(%9.3f) stats(N r2, fmt(0 2))

// Results match with Table 2 reported in Washington (2008)

********************************************************************************

* What if we did not control for the number of children?

est clear

eststo: reg nowtot ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 regd* demvote  if congress==105
*column 2 (table2), column1 (at3)
eststo: reg aauw ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 regd* demvote  if congress==105
*column 3 (table2), column3 (at3)
eststo: reg aauw ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 regd* demvote  if congress==106
*column 4 (table2), column5 (at3)
eststo: reg aauw ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 regd* demvote  if congress==107
*column 5 (table2), column7 (at3)
eststo: reg aauw ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 regd* demvote  if congress==108

esttab, keep(ngirls) star(* .1 ** .05 *** .01) b(%9.3f) se(%9.3f) stats(N r2, fmt(0 2))

// Everything goes away - but this is a wrong specification anyway...

********************************************************************************

* What about an alternative control - the number of children controlled for linearly insted of the dummies?

est clear

eststo: reg nowtot ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 regd* demvote totchi if congress==105
*column 2 (table2), column1 (at3)
eststo: reg aauw ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 regd* demvote totchi if congress==105
*column 3 (table2), column3 (at3)
eststo: reg aauw ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 regd* demvote totchi if congress==106
*column 4 (table2), column5 (at3)
eststo: reg aauw ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 regd* demvote totchi if congress==107
*column 5 (table2), column7 (at3)
eststo: reg aauw ngirls white female repub  age agesq srvlng srvlngsq reld1 reld3-reld5 regd* demvote totchi if congress==108

esttab, keep(ngirls) star(* .1 ** .05 *** .01) b(%9.3f) se(%9.3f) stats(N r2, fmt(0 2))

// It works pretty much the same way as when we controlled for the dummies.

********************************************************************************

* What about leaving out all the other covariates and only controlling for the total number of children?

est clear

eststo: reg nowtot ngirls totchi if congress==105
*column 2 (table2), column1 (at3)
eststo: reg aauw ngirls totchi if congress==105
*column 3 (table2), column3 (at3)
eststo: reg aauw ngirls totchi if congress==106
*column 4 (table2), column5 (at3)
eststo: reg aauw ngirls totchi if congress==107
*column 5 (table2), column7 (at3)
eststo: reg aauw ngirls totchi if congress==108

esttab, keep(ngirls) star(* .1 ** .05 *** .01) b(%9.3f) se(%9.3f) stats(N r2, fmt(0 2))

// Still works pretty much the same way!
