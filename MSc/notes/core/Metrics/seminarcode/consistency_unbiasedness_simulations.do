* Simulate sample mean estimators
set seed 123123
global xbar = 40
global sd = 10

* Draw sample 1000 times, each time with sample size = 1
clear 
matrix define storage_n1 = J(1000,2,.)
matrix colnames storage_n1 = "FirstObs" "SampAvg"
forvalues iterations = 1(1)1000 {
	clear
	qui set obs 1
	gen X = rnormal($xbar,$sd)
	mat storage_n1[`iterations',1] = X[1]
	qui sum X
	mat storage_n1[`iterations',2] = r(mean)
}

* Plotting
svmat storage_n1, names(col)
hist FirstObs, subtitle("FirstObs, n=1") name(FirstObs_n1,replace) nodraw
hist SampAvg, subtitle("SampAvg, n=1") name(SampAvg_n1,replace) nodraw

* Draw sample 1000 times, each time with sample size = 5
clear 
matrix define storage_n5 = J(1000,2,.)
matrix colnames storage_n5 = "FirstObs" "SampAvg"
forvalues iterations = 1(1)1000 {
	clear
	qui set obs 5
	gen X = rnormal($xbar,$sd)
	mat storage_n5[`iterations',1] = X[1]
	qui sum X
	mat storage_n5[`iterations',2] = r(mean)
}

* Plotting
svmat storage_n5, names(col)
hist FirstObs, subtitle("FirstObs, n=5") name(FirstObs_n5,replace) nodraw
hist SampAvg, subtitle("SampAvg, n=5") name(SampAvg_n5,replace) nodraw

* Draw sample 1000 times, each time with sample size = 50
clear
matrix define storage_n50 = J(1000,2,.)
matrix colnames storage_n50 = "FirstObs" "SampAvg"
forvalues iterations = 1(1)1000 {
	clear
	qui set obs 50
	gen X = rnormal($xbar,$sd)
	mat storage_n50[`iterations',1] = X[1]
	qui sum X
	mat storage_n50[`iterations',2] = r(mean)
}

* Plotting
svmat storage_n50, names(col)
hist FirstObs, subtitle("FirstObs, n=50") name(FirstObs_n50,replace) nodraw
hist SampAvg, subtitle("SampAvg, n=50") name(SampAvg_n50,replace) nodraw

* Compare n=1, n=3 and n=50 for Theta1 and Theta2
graph combine FirstObs_n1 FirstObs_n5 FirstObs_n50 SampAvg_n1 SampAvg_n5 SampAvg_n50, row(2) xcommon ycommon



