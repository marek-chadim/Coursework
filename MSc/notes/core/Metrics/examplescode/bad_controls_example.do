********************************************************************************
***************************** EXAMPLE: BAD CONTROLS ****************************
********************************************************************************

// Suppose that we want to estimate the effect of temperature on the prevalence of conflict.
// Let us simulate data to explore how our estimates might behave depending on what
// covariates are included. Suppose that the data generating processes are as follows:
// income = temperature + noise
// coonflict = income + noise

clear
set seed 123
set obs 1000 // we will simulate 1,000 observations

gen temperature = rnormal() // temperature variable
gen e_1 = rnormal() // noise variable 1
gen e_2 = rnormal() // noise variable 2, uncorrelated with e_1

gen income = -temperature + e_1 // temperature and income are negatively related - e.g. Dell et al. (2012)
gen conflict = -income + e_2 // income and conflict are negatively related - e.g. Miguel et al. (2004)

reg conflict temperature
reg conflict income
reg conflict income temperature // coefficient on income is highly significant, coefficient on temperature is not, and point estimate is close to zero

********************************************************************************

