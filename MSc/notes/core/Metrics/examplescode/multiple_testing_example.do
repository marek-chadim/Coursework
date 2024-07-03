********************************************************************************
*************************** EXAMPLE: MULTIPLE TESTING **************************
********************************************************************************

// Open the dataset

use "/Users/jaakko/Library/CloudStorage/Dropbox/teaching/fall_2023/econometrics/stata_examples/data/HMSTT_data_22082017.dta", clear

// The data comes from the replication files of Hyytinen et al. (2018) "When Does
// Regression Discontinuity Design Work? Evidence from Random Election Outcomes,"
// published in Quantitative Economics.

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

// We will use these lotteries to causally estimate the effects of election.

********************************************************************************

keep if vmargin == 0 // Keep only candidates involved in the lotteries

********************************************************************************

* There is no incumbency effect in the full sample

reg electednextelection elected, robust

* Let us start splitting this by party (three largest parties) - still no statistically
* significant effects

reg electednextelection elected if party == "KESK", robust // Center Party
reg electednextelection elected if party == "SDP", robust // Social Democratic Party
reg electednextelection elected if party == "KOK", robust // National Coalition Party

* Let us then estimate the effect by election year - still no statistically significant
* effects

bysort electionyear: reg electednextelection elected, robust 

* Last, let us run the same regression by party (three largest parties) and election year

bysort electionyear: reg electednextelection elected if party == "KESK", robust // Center Party
bysort electionyear: reg electednextelection elected if party == "SDP", robust // Social Democratic Party
bysort electionyear: reg electednextelection elected if party == "KOK", robust // National Coalition Party

* We found a positive and statistically significant effect for Center Party candidates
* in 1996 and a negative and statistically significant effect for Center Party candidates
* in 2004! But does this actually mean something? Probably not. Running multiple 
* subsample analyses can be problematic... We could similarly run into trouble if 
* we consider multiple different dependent variables.
