********************************************************************************
************************* EXAMPLE: REGRESSION ANALYSIS  ************************
********************************************************************************

// Open the dataset

use "/Users/jaakko/Dropbox/teaching/fall_2023/econometrics/stata_examples/data/HMSTT_data_22082017.dta", clear

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

// We will use these lotteries to causally estimate the effects of election. But
// before doing so, let us focus on the full data...

********************************************************************************

* Let us start by using all the data - not just the lotteries - to estimate the
* relationship between election at t and election at t + 1

reg electednextelection elected

* How would you interpret the regression results? What do the intercept and the
* coefficient for elected tell us? Are the estimates statistically significant?
* What are their CIs and p-values? Does the coefficient for elected have a causal
* interpretation?

********************************************************************************

* What if we wanted to run a one-sided test? This is how it would work:

reg electednextelection elected

test _b[elected] = 0
local sign = sign(_b[elected])
display "Ho: coefficient <= 0  p-value = " ttail(r(df_r),`sign'*sqrt(r(F)))
display "Ho: coefficient >= 0  p-value = " 1-ttail(r(df_r),`sign'*sqrt(r(F)))

* Remember: In real life, one-sided tests are rarely warranted. A two-sided test
* is usually the right choice!

********************************************************************************

* Let us then explore heterogeneity in the relationship between election at t
* and election at t + 1 by gender

gen female = (gender == "N")

reg electednextelection 1.elected##1.female

* How would you interpret the regression results now? Which of the estimates are
* statistically significant and at what levels? Are the estimates jointly
* significant?

********************************************************************************

* Let us also explore the differences between different groups...

* Is the difference between elected women and non-elected women significant?

test 1.elected#1.female = 1.female

* Is the difference between elected women and elected men significant?

test 1.elected#1.female = 1.elected

********************************************************************************

* Let us estimate the effect in the lottery sample

keep if vmargin == 0 // Keep only candidates involved in the lotteries

reg electednextelection 1.elected

* How would you interpret these regression results?

********************************************************************************

* Repeat the same comparisons as above in this restricted/lottery sample

reg electednextelection 1.elected##1.female

test 1.elected#1.female = 1.female
test 1.elected#1.female = 1.elected
