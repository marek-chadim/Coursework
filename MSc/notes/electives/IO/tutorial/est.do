clear all
set seed 12345
use "data_obs.dta"

gen msize = 1

xtset product market

mergersim init, price(p) quantity(s) ///
	marketsize(msize) firm(firm)

* Price is endogenous so OLS is biased
reg M_ls p i.product

* Use distance to production site as an instrument for price (cost shifter)
ivregress 2sls M_ls (p = dist_to_production) i.product

* Pre-Merger conditions
mergersim market

* Merger Simulation
mergersim simulate, buyer(1) seller(3) method(fixedpoint) maxit(40) dampen(0.5) detail