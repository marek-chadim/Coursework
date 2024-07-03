********************************************************************************
*********** EXAMPLE:  MULTIPLE INSTRUMENTS AND ENDOGENOUS VARIABLES ************
********************************************************************************

// In this example, we will use data from a book by Torsten Persson and Guido
// Tabellini. The investigate how different types of (political) institutions
// affect economic policy outcomes.

// Two institutions they analyze are majoritarian elections (as opposed to proportional 
// representation) -- think (roughly) of two-party competition in several single-member
// districts versus multiparty competition in larger multi-member districts -- and
// presidentialism (as opposed to parlamentiarism) -- think of a presidential system
// with some separation of powers versus a larger governing coalition (and a parliament)
// being responsible for the decisions.

// Persson and Tabellini want to understand the causal effect of institutions on policy.
// But just regressing an economic outcome, such as government spending as a % of GDP
// could be problematic. Persson and Tabellini thus adopt an instrumental variables
// approach where they have two endogenous variables and six instruments. Let us
// have a look at their data and what those data tell us...

********************************************************************************

// Open data

use "/Users/jaakko/Dropbox/teaching/fall_2023/econometrics/Lecture 7/85cross_7nov.dta", clear

********************************************************************************

// What do Persson and Tabellini estimate? They run an IV model with two endogenous
// variables and six instruments. These instruments are dummies for whether a country
// adopted its current form of government and current electoral rule after 1981,
// between 1951-80, between 1921, with before 1921 as the omitted category; two
// language variables indicating the fraction of the population in the country speaking
// one of the major European languages, and the fraction speaking English as a native
// language; and latitude (distance from equator). These variables are con2150, con5180,
// con81, eurfracm, engfrac, and lat01, respectively.

// The reasoning Persson and Tabellini had in mind was this. The three timing variables
// could be relevant for the form of government and for the electoral system because
// there may have been waves (or "fads") in the type of constitutions, and different
// countries fell into different waves depending on when they adopted their constitution
// or declared their independence. This could be arguably exogenous. The two language variables
// and latitude are include as proxies for "European influence" follow ing the arguments in 
// Hall and Charles Jones (1999). Hall and Jones use these variables as instruments for
// the overall quality of institutions (social infrastructure), and Persson and Tabellini
// argue that these  could also have affected the form of government and elector rule.
// There are some concerns about these instruments, but before discussing those,
// let us have a look at some patterns in the data.

// The dependent variable (cgexp) is the central government expenditure on social
// and welfare spending as a share of GDP. The regressions also include a bunch of
// control variables (sometimes), let us ignore the details regarding those.

* OLS results

reg cgexp maj pres, robust // No controls
reg cgexp maj pres age lyp trade prop1564 prop65 gastil federal oecd, robust // Controls included

* IV results

ivreg2 cgexp (maj pres = con2150 con5180 con81 lat01 engfrac eurfrac), robust first
ivreg2 cgexp (maj pres = con2150 con5180 con81 lat01 engfrac eurfrac) age lyp trade prop1564 prop65 gastil federal oecd, robust first

// It appears that both majoritarian and presidential systems have lower spending.
// But how credible is this result? Persson and Tabellini argue: "[As] we are confident
// about the exogeneity of the time dummies for constitutional adoption,
// we can test the validity of the additional instruments by exploiting
// the overidentifying restrictions." However, looking at the first-stage regressions, 
// we would see that something iffy is going on! With the instruments we have, it appears that we
// may have a weak instruments problem and this would also lead to problems with the
// overidentification test.

// Acemoglu (2005) reviews Persson and Tabellini's book and discusses potential
// problems in their analysis in detail. He brings up two issues:

// (1) Dummies for the adoption time of the current form of government and electoral
// rule appear to be weak instruments. Even if the could be plausibly exogenous, they
// might lead to problems...

// => What would happen without them?

ivreg2 cgexp (maj pres = lat01 engfrac eurfrac), robust first
ivreg2 cgexp (maj pres = lat01 engfrac eurfrac) age lyp trade prop1564 prop65 gastil federal oecd, robust first

// Results remain the same. In the first stage, lat01 seems to matter very little,
// though, when we include control variables. Could this be still causing some
// problems with weak instruments? Maybe this doesn't even matter, because...

// (2) It is unlikely that the other instruments (lat01 engfrac eurfrac) satisfy
// the exlusion restriction! Thus, the bias arising from weak instruments could
// lead to big problems. Acemoglu mentions two reasons: The first is that the 
// Hall-Jones instruments are unlikely to be valid for the overall quality of
// institutions (which was the motivation of Hall and Jones) -- Acemoglu discusses
// this argument in further detail. The second is that even if these instruments were 
// valid for the overall quality of institutions, they would by implication be invalid 
// for a specific feature of the institutional structure such as presidentialism or a
// majoritarian electoral system.
