* CASE 1: SAME REGRESSION
clear all
set seed 333

* Creating simulated dataset
set obs 100
gen x1 = rnormal()
gen x2 = 2 + rnormal()
gen y = 2*x1 + 2.2*x2 + rnormal()

* Running regression and testing equality of b1 and b2
reg y x1 x2
test x1=x2

* CASE 2: DIFFERENT REGRESSIONS
clear all
set seed 333

* Creating simulated dataset
set obs 40
gen sample=0 
replace sample=1 if _n>20

* Creating variables
gen x1 = rnormal() if sample==0
gen x2 = rnormal() if sample==1
gen y1 = 2*x1 + rnormal() if sample==0
gen y2 = 2.2*x2 + rnormal() if sample==1

* Running things separately
reg y1 x1
scalar b1 = _b[x1]
reg y2 x2
scalar b2 = _b[x2]

display "The difference between b2 and b1 is " b2-b1 

* Setting up a Seemingly Unrelated Regression
gen y = y1 if sample==0
replace y = y2 if sample==1
gen x = x1 if sample==0
replace x = x2 if sample==1

* Running regression, allowing beta to vary depending on sample
reg y c.x##i.sample





