clear all
set seed 12345

* Set the number of observations
set obs 6000

* Create market, product, firm identifiers
gen market = ceil(_n/3)
gen product = 1 + mod(_n - 1, 3)
gen firm = product

* Generate xi from a normal distribution N
gen xi = rnormal(0, 2)

* Generate distance to production site
gen dist_to_production = 0
replace dist_to_production = abs(market - 0) if product == 1
replace dist_to_production = abs(market - 500) if product == 2
replace dist_to_production = abs(market - 1300) if product == 3

* Generate marginal cost
gen mc = product + dist_to_production/1000

* Utility parameters
gen gamma = product 
gen alpha = 1.5


* Code below finds equilibrium prices by first starting at marginal cost and 
*looping until convergence.
gen p = mc
bysort market: egen s_denominator = total(exp(gamma - alpha*p + xi))
replace s_denominator = s_denominator + 1
gen s = exp(gamma - alpha*p + xi) / s_denominator
gen marg_profit = (p-mc)*(-alpha*s*(1-s)) + s
forvalues i = 1/10000 {
	replace p = p + marg_profit
	drop s_denominator
	bysort market: egen s_denominator = total(exp(gamma - alpha*p + xi))
	replace s_denominator = s_denominator + 1
	replace s = exp(gamma - alpha*p + xi) / s_denominator
	replace marg_profit = s + (p-mc)*(-alpha*s*(1-s))
}

* Save data with unobservables
save "data_unobs.dta", replace

* Drop variables unobserved by the econometrician
drop xi mc gamma alpha marg_profit

* Save data with only observables
save "data_obs.dta", replace
