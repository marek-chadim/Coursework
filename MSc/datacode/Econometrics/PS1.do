** Econometrics PS1 Xuan Min, Dylan, Elias, Marek 

clear all
set more off 

global root "C:\Users\chadi\Desktop\5304 - Econometrics\Assignments\1"
global data "$root\Data"
global output "$root\Output"

cd "$root"

use "$data\PS1_ANES2020", clear

*ssc install binscatter
*ssc install cibar

*** Q1 ***

** Check data editor
browse

** Checking for duplicates within data set
duplicates report respondent_id

** Removal of duplicates 
duplicates drop respondent_id, force


*** Q2 ***

* (a) drop obs with missing values

drop if age<0 | education<0 | working<0 | race<0 | president_vote<0 |conservative< 0| conservative > 100 | education > 10 

* (b)

drop if president_vote != 1 & president_vote != 2

* (c) dummy for at least Bachelor's degree

gen bachelor = 0
replace bachelor = 1 if education > 5

* (d) dummy for being White 

gen white = 0 
replace white = 1 if race == 1

** (e)

gen not_working = 0
replace not_working = 1 if working == 2

** (f) label variables 
label variable bachelor "Attained at least a Bachelor's degree; 0 = False, 1 = True'"
label variable white "Of White ethnicity; 0 = False, 1 = True"
label variable not_working "Not working as of the last week; 0 = False, 1 = True"

*** Q3 
* Whole pooled sample

estpost summarize age conservative white not_working bachelor

* Biden voters
estpost summarize age conservative white not_working bachelor if president_vote == 1 
* Trump voters
estpost summarize age conservative white not_working bachelor if president_vote == 2 

** Table Compilation 
sort(president_vote)
by president_vote: summarize age conservative white not_working bachelor 

estpost tabstat  age conservative white not_working bachelor, by(president_vote) statistics (mean sd) 

eststo clear

eststo Biden: quietly estpost summarize age conservative bachelor white not_working if president_vote == 1
eststo Trump: quietly estpost summarize age conservative bachelor white not_working if president_vote == 1
eststo Pooled: quietly estpost summarize age conservative bachelor white not_working
esttab, cells("mean(fmt(%9.2f)) sd(fmt(%9.2f))") nodepvar b(%9.2f) nonumber nodepvar 

*** Q4
*(a) histogram plot distribution of age variable 
hist age , width(1)

* Check age > 80 
count if age>80
*noone

* Compiling into a graph 
graph export "$output/Age_Histogram.pdf", as(pdf) replace

*(b)
twoway scatter president_vote age
* Scatter on binary variable not very informative
* lfit binscatter
binscatter president_vote age if age < 80 , linetype(lfit) nquantiles(20)
graph export "$output/Binscatter_linear.pdf", as(pdf) replace
* qfit binscatter
binscatter president_vote age if age < 80 , linetype(qfit) nquantiles(20)
graph export "$output/Binscatter_quadratic.pdf", as(pdf) replace


*(c) Economic specification
gen Trump = 0 
replace Trump = 1 if president_vote == 2
logistic Trump age c.age#c.age i.race 

*** Q5 
cibar president_vote, over(not_working) level(95) graphopts(title(Voting Patterns Over Employment Status)) 
graph export "$output/cibar_binary.pdf", as(pdf) replace

* Since binary variable for employment status and presidential voting patterns, then hard to find statistically significant results.

save "$results.dta", replace

