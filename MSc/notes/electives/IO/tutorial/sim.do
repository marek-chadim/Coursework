clear all
set seed 12345
use "data_unobs.dta"

* Average marginal cost
bysort product: summarize mc
* Average Lerner
gen lerner = (p - mc)/p
bysort product: summarize lerner

* Merger counterfactual equilibrium prices
gen p_merge = p
forvalues i = 1/10000 {
	replace p_merge = p_merge + marg_profit
	drop s_denominator
	bysort market: egen s_denominator = total(exp(gamma - alpha*p_merge + xi))
	replace s_denominator = s_denominator + 1
	replace s = exp(gamma - alpha*p_merge + xi) / s_denominator
	sort market product
	replace marg_profit = s + (p_merge-mc)*(-alpha*s*(1-s)) ///
		if product == 2
	replace marg_profit = s + (p_merge-mc)*(-alpha*s*(1-s)) + ///
		(p_merge[_n+2] - mc[_n+2])*(alpha*s*s[_n+2]) if product == 1
	replace marg_profit = s + (p_merge-mc)*(-alpha*s*(1-s)) + ///
		(p_merge[_n-2] - mc[_n-2])*(alpha*s*s[_n-2]) if product == 3
}

bysort product: summarize p
bysort product: summarize p_merge

