
************************************************************************
*Markups and Public Procurement
*bakalářská práce
*Institut ekonomických studií
*Matěj Bajgar, D.Phil.
*Marek Chadim
************************************************************************
clear
cd "C:\Users\chadi\Dropbox\Code_and_data" 

//cd "C:/Users/mbajgar/Dropbox/IES/Thesis supervision/Marek Chadim"
// "C:/Users/ThinkPad/Dropbox/IES/Thesis supervision/Marek Chadim"

************************************************************************
*                                DATA                                  *
************************************************************************

* PREPARE ANALYSIS 

* RATIOS
import delimited using "ratios1.csv", clear
save "ratios", replace
forvalues i=2/3{
    import delimited using "ratios`i'.csv", clear
	append using "ratios"
	save "ratios.dta", replace
}

* FINANCIAL
import delimited using "financial1.csv", clear
save "financial", replace
forvalues i=2/6{
    import delimited using "financial`i'.csv", clear
	append using "financial"
	save "financial.dta", replace
}

merge m:m id year using "ratios.dta", nogenerate

rename ccosts costs
rename fafixedassets assets
rename salsalesoutputs sales
rename wvawagesvalueadded wva
rename wswagessales ws
rename lplabourproductivity lp
rename cmiiicontributionmargin cm 

duplicates drop
duplicates drop id year, force
save "analysis", replace

************************************************************************

* PREPARE SELECTIONS 

import delimited using "selections1.csv", clear
save "selections", replace
forvalues i=2/5{
    import delimited using "selections`i'.csv", clear
	append using "selections"
	save "selections.dta", replace
}

rename idièo id
rename typeofsubject subject_type
rename legalform legal_form
rename institutionalsectorsesa2010 inst_sector
rename numberofemployees empl_num
rename numberofemployeesclassificationc empl_cat
drop empl_cat-v28
rename v29 empl_cat
rename mainnacecode nace


duplicates drop
save "selections", replace



************************************************************************

* MERGE & CLEAN

use "analysis", clear
merge m:1 id using "selections", nogenerate

duplicates drop 
duplicates drop id year, force 

*correct sales
sum sales,d
sum sales if sales<0,d
replace sales = . if sales<0   // if negative
sum sales if sales>10000000000,d



*correct ws and define as a share
sum ws,d
sum ws if ws<1,d
replace ws = ws * 100 if ws<1 & ws>0 // if 100 times too low
replace ws = . if ws<0 // if negative
replace ws = . if ws>100 // if very high
replace ws = ws/100 // define as a share
sum ws,d

*correct wva and define as a share
sum wva if wva<1,d
replace wva = wva * 100 if wva<1 & wva>0 // if 100 times too low
replace wva = . if wva<0 // if negative
replace wva = . if wva>500 // if very high
replace wva = wva/100 // define as a share
sum wva,d

*correct cm and define as a share
sum cm if cm<1,d
replace cm = cm * 100 if cm<1 & cm>0 // if 100 times too low
replace cm = . if cm<0 // if negative
replace cm = . if cm>200 // if very high
replace cm = cm/100 // define as a share
sum cm,d

*gen cs (a ratio of costs to sales)
gen cs = costs / sales
sum cs,d
replace cs = . if cs<0 // if negative
replace cs = . if cs>10 // if very high
sum cs,d

*generate iis
//gen iis = cm-ws
gen iis = cs - ws
replace iis = . if iis<0
sum iis, d

*generate cogss
gen cogss = 1-cm
replace cogss = . if cogss<0 // if negative
sum cogss, d


*correct lp if 1000 times too large
sum lp if lp<10^8,d
sum lp if lp>10^8,d
replace lp = lp/1000 if lp>10^8
sum lp,d

*generate variables
gen GO = sales
gen W = ws * sales
gen II = iis * sales
gen COGS= cogss*sales
gen VA = GO - II 
gen L = VA / lp if VA/lp>0
gen K = assets


sum VA GO COGS II W K L

sort id year

//entry year
egen int entryYr = min(year), by(id)
egen int exitYr = max(year), by(id)

// dummies for entry and exit year
gen byte entry = (year==entryYr)
gen byte exit = (year==exitYr)

//number of entries, exits per year
tabstat entry exit , stats(sum) by(year)

*correct
replace GO = . if GO<0
replace COGS = . if COGS<0
replace II = . if II<0
replace W = . if W<0
replace K = . if K<0

*deflate

/*
import delimited "deflators.csv", clear
save "deflators",replace
*/

gen nace2 = floor(nace/10000)
merge m:1 year nace2 using "deflators", nogenerate
duplicates drop id year, force

gen rGO = GO/deflatorprdp, 
gen rVA = VA/deflatorvalp
gen rII = II/deflatorintp
gen rW = W/deflatorcpi
gen rK = K/deflatorgfcp
gen rCOGS = COGS/deflatorintp

*gen log variables
gen go = ln(rGO)
gen w = ln(rW)
gen ii = ln(rII)
gen va = ln(rVA)
gen l = ln(L)
gen k = ln(rK)
gen cogs = ln(rCOGS)

save "magnus", replace


************************************************************************

* PREPARE TENDERS

/*
insheet using "master_tender_analytics_202207251530.csv", names clear
save "master_tender_analytics_202207251530", replace
*/

use "master_tender_analytics_202207251530", clear


*id
rename bidder_id id
drop if length(id)==2 // foreign bidders
destring id, replace


*prep for analysis
rename bid_final_price zakazky
tabulate src
collapse (sum) zakazky, by(id year)


save "tenders", replace

************************************************************************

*MERGE FIRM AND TENDER DATA
use "magnus", replace

merge 1:1 id year using "tenders"

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                       199,736
        from master                    38,716  (_merge==1)
        from using                    161,020  (_merge==2)

    matched                            14,370  (_merge==3)

    -----------------------------------------
*/

drop if _merge==2


replace zakazky = 0 if zakazky==.
bysort id (year): gen zakazky_l1 = zakazky[_n-1]
bysort id (year): gen zakazky_l2 = zakazky[_n-2]

egen zakazky_last3 = rowmean(zakazky zakazky_l1 zakazky_l2)
gen zakazky_last3_dummy = zakazky_last3>0



gen zakazky_last3_share = zakazky_last3/sales
sum zakazky_last3_share, d
sum zakazky_last3_share if zakazky_last3_share>1, d
replace zakazky_last3_share = 1 if zakazky_last3_share>1
sum zakazky_last3_share,d


************************************************************************

*restrict sample to years with enough data, known industry and pp engagement

drop if year<2006 | year>2021
keep if nace2 == 41 | nace2 == 42 | nace2 == 43

save "data", replace


************************************************************************
************************************************************************

use "data", replace

* SUMMARY STATISTICS
gen GO_mil = rGO/1000000
gen VA_mil = rVA/1000000
gen K_mil = rK/1000000
gen II_mil = rII/1000000
gen W_mil = rW/1000000
gen COGS_mil = rCOGS/1000000

tabstat GO_mil COGS_mil II_mil K_mil W_mil L if !missing(COGS_mil,K_mil,II_mil), stat(mean median sd min max count  ) format(%9.2f)

bys zakazky_last3_dummy  : tabstat GO_mil COGS_mil K_mil  if !missing(GO_mil, COGS_mil,K_mil)  , stat(mean median sd min max count  ) format(%9.2f)

bys zakazky_last3_dummy  : tabstat GO_mil COGS_mil K_mil  if !missing(GO_mil, COGS_mil,K_mil) & nace2==41 , stat(mean median sd min max count  ) format(%9.2f)
bys zakazky_last3_dummy  : tabstat GO_mil COGS_mil K_mil  if !missing(GO_mil, COGS_mil,K_mil) & nace2==42 , stat(mean median sd min max count  ) format(%9.2f)
bys zakazky_last3_dummy  : tabstat GO_mil COGS_mil K_mil  if !missing(GO_mil, COGS_mil,K_mil) & nace2==43 , stat(mean median sd min max count  ) format(%9.2f)


tabstat zakazky_last3_dummy, by(year) stat(N sum)
tabstat zakazky_last3_share if zakazky_last3_dummy == 1, by(year) stat(N mean)

************************************************************************
*                              ESTIMATION                              *
************************************************************************
use "data", replace
set seed 42


*setting panel structure
xtset id year, yearly
gen proxy=cogs

*-------------------------------------OLS-----------------------------------------------*

reg go k cogs i.year if nace2==41,  cluster(id)
estimates store ols41
gen bwols41=_b[cogs]
gen bkols41=_b[k]
gen markup_OLS41=_b[cogs]/cogss
sum markup_OLS41,d
replace markup_OLS41 = . if markup_OLS41<r(p1) | markup_OLS41>r(p99)
tabstat markup_OLS41, statistics(mean median sd)


reg go k cogs i.year if nace2==42,  cluster(id)
estimates store ols42
gen bwols42=_b[cogs]
gen bkols42=_b[k]
gen markup_OLS42=_b[cogs]/cogss
sum markup_OLS42,d
replace markup_OLS42 = . if markup_OLS42<r(p1) | markup_OLS42>r(p99)
tabstat markup_OLS42, statistics(mean median sd)


reg go k cogs  i.year if nace2==43,  cluster(id)
estimates store ols43
gen bwols43=_b[cogs]
gen bkols43=_b[k]
gen markup_OLS43=_b[cogs]/cogss
sum markup_OLS43,d
replace markup_OLS43 = . if markup_OLS43<r(p1) | markup_OLS43>r(p99)
tabstat markup_OLS43, statistics(mean median sd)


estout ols41 ols42 ols43, cells(b(star fmt(3)) se(par fmt(3))) ///
   legend label varlabels(_cons Constant) ///
   stats(N)
 
 gen markup_OLS = markup_OLS41 if nace2==41
 replace markup_OLS = markup_OLS42 if nace2==42
 replace markup_OLS = markup_OLS43 if nace2==43
 
 
 sum markup_OLS,d
tabstat markup_OLS, statistics( median )
tabulate zakazky_last3_dummy, summarize(markup_OLS)	
 
/* plot the graph */
tw (kdensity markup_OLS if nace2 == 41, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_OLS if nace2  == 42, lw(medthick) lp(-) lc(maroon)) /*
	*/ (kdensity markup_OLS if nace2  == 43, lw(medthick) lp(.-.) lc(forest_green))  /*
	*/ if markup_OLS > 0 & markup_OLS < 3, ytitle("Density") xtitle("mu_OLS") legend(order( 1 "Sector 41" 2 "Sector 42" 3 "Sector 43") cols(4))

   
gen lmu_OLS= ln(markup_OLS)
	

*-------------------------------------fixed effects-------------------------------------*

xtreg go cogs k i.year, fe  cluster(id)

gen bcogsolsfe_gocogs=_b[cogs]
gen bkolsfe_vaw=_b[k]
gen markup_OLSfe_gocogs=_b[cogs]/cogss
sum markup_OLSfe_gocogs,d
replace markup_OLSfe_gocogs = . if markup_OLSfe_gocogs<r(p1) | markup_OLSfe_gocogs>r(p99)
tabstat markup_OLSfe_gocogs, statistics( median ) 
tabulate nace2, summarize(markup_OLSfe_gocogs)	
tabulate year, summarize(markup_OLSfe_gocogs)

tabulate zakazky_last3_dummy, summarize(markup_OLSfe_gocogs)	


tw (kdensity markup_OLSfe_gocogs if nace2 == 41, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_OLSfe_gocogs if nace2  == 42, lw(medthick) lp(-) lc(maroon)) /*
	*/ (kdensity markup_OLSfe_gocogs if nace2  == 43, lw(medthick) lp(.-.) lc(forest_green))  /*
	*/ if markup_OLSfe_gocogs > 0 & markup_OLSfe_gocogs < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "41" 2 "42" 3 "43") cols(4))

  
	
*------------------------ prodest: LP(2003) + ACF(2015) ---------------------------------*



*CD, cogs
*sector
prodest go if nace2==41, va free(cogs) proxy(proxy) state(k) acf endogenous(proxy zakazky_last3_dummy) control(year zakazky_last3_dummy)  
estimates store cf41
prodest go if nace2==42, va free(cogs) proxy(proxy) state(k) acf endogenous(proxy zakazky_last3_dummy) control(year zakazky_last3_dummy)  
estimates store cf42
prodest go if nace2==43, va free(cogs) proxy(proxy) state(k) acf endogenous(proxy zakazky_last3_dummy) control(year zakazky_last3_dummy)  
estimates store cf43

estout ols41 cf41 ols42 cf42 ols43 cf43, cells(b(star fmt(3)) se(par fmt(3))) ///
   legend label varlabels(_cons Constant) ///
   stats(N) keep(cogs k)
   
 *+ market
prodest go if zakazky_last3_dummy==1 & nace2==41, va free(cogs) proxy(proxy) state(k) acf endogenous(proxy  zakazky_last3_dummy) control(year) 
estimates store cf41pp1
prodest go if zakazky_last3_dummy==0 & nace2==41, va free(cogs) proxy(proxy) state(k) acf endogenous(proxy  zakazky_last3_dummy) control(year) 
estimates store cf41pp0

prodest go if zakazky_last3_dummy==1 & nace2==42, va free(cogs) proxy(proxy) state(k) acf endogenous(proxy  zakazky_last3_dummy) control(year)
estimates store cf42pp1
prodest go if zakazky_last3_dummy==0 & nace2==42, va free(cogs) proxy(proxy) state(k) acf endogenous(proxy  zakazky_last3_dummy) control(year) 
estimates store cf42pp0

prodest go if zakazky_last3_dummy==1 & nace2==43, va free(cogs) proxy(proxy) state(k) acf endogenous(proxy  zakazky_last3_dummy) control(year) 
estimates store cf43pp1
prodest go if zakazky_last3_dummy==0 & nace2==43, va free(cogs) proxy(proxy) state(k) acf endogenous(proxy  zakazky_last3_dummy) control(year) 
estimates store cf43pp0


estout cf41pp1 cf41pp0  cf42pp1 cf42pp0 cf43pp1 cf43pp0, cells(b(star fmt(3)) se(par fmt(3))) ///
   legend label varlabels(_cons Constant) ///
   stats(N) keep(k cogs)
   
  
  
*Translog, cogs
prodest go if nace2==41,va translog method(lp) free(cogs) proxy(proxy)  state(k) acf endogenous(proxy zakazky_last3_dummy) control(year zakazky_last3_dummy)  
predict, parameters
prodest go if nace2==42,va translog method(lp) free(cogs) proxy(proxy)  state(k) acf endogenous(proxy zakazky_last3_dummy) control(year zakazky_last3_dummy) 
predict, parameters
prodest go if nace2==43,va translog method(lp) free(cogs) proxy(proxy)  state(k) acf endogenous(proxy zakazky_last3_dummy) control(year zakazky_last3_dummy) 
predict, parameters

*--------------------------------- prodest: Wooldridge (WRDG, 2009)-------------------------------------*



*Cobb-Douglas
prodest go, va method(wrdg) free(cogs) state(k) proxy(proxy) endogenous(proxy zakazky_last3_dummy) control(year zakazky_last3_dummy nace2) attrition over
gen bcogswrdg_gocogs=_b[cogs] 
gen bkwrdg_gocogs=_b[k] 
gen markup_wrdg_gocogs=_b[cogs]/cogss
sum markup_wrdg_gocogs,d
replace markup_wrdg_gocogs= . if markup_wrdg_gocogs <r(p1) | markup_wrdg_gocogs >r(p99)
tabstat markup_wrdg_gocogs, statistics( median )
tabulate year, summarize(markup_wrdg_gocogs)
tabulate nace2, summarize(markup_wrdg_gocogs)

tw (kdensity markup_wrdg_gocogs if nace2 == 41, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_wrdg_gocogs if nace2  == 42, lw(medthick) lp(-) lc(maroon)) /*
	*/ (kdensity markup_wrdg_gocogs if nace2  == 43, lw(medthick) lp(.-.) lc(forest_green))  /*
	*/  if markup_wrdg_gocogs > 0 & markup_wrdg_gocogs < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "41" 2 "42" 3 "43") cols(4))


*TRANS
prodest go if zakazky_last3_dummy ==1, va method(wrdg) free(cogs) state(k) proxy(proxy) endogenous(proxy zakazky_last3_dummy)  control(year zakazky_last3_dummy nace2)  attrition over
predict, parameters



  

*--------------------------------- markupest: De Loecker and Warzynski (DLW, 2012)-------------------------------------*
*/

*ACF Cobb-Douglas
bys nace2: markupest markup_dlw_gocogs,method(dlw) output(go) inputvar(cogs) free(cogs) state(k) proxy(proxy) verbose corrected  prodestopt(" acf va attrition endogenous(proxy zakazky_last3_dummy) control(year zakazky_last3_dummy)")
sum markup_dlw_gocogs,d
replace markup_dlw_gocogs= . if markup_dlw_gocogs<r(p1) | markup_dlw_gocogs >r(p99)
tabstat markup_dlw_gocogs, statistics( median )
tabulate year, summarize(markup_dlw_gocogs)
tabulate nace2, summarize(markup_dlw_gocogs)


/* plot the graph */
tw (kdensity markup_dlw_gocogs if nace2 == 41, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogs if nace2  == 42, lw(medthick) lp(-) lc(maroon)) /*
	*/ (kdensity markup_dlw_gocogs if nace2  == 43, lw(medthick) lp(.-.) lc(forest_green))  /*
	*/ 	  if markup_dlw_gocogs > 0 & markup_dlw_gocogs < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "41" 2 "42" 3 "43") cols(4))

	
	
*ACF Translog
bys nace2: markupest markup_dlw_gocogst1,method(dlw) output(go) inputvar(cogs) free(cogs) state(k) proxy(proxy) verbose corrected  prodestopt(" acf va attrition translog endogenous(proxy zakazky_last3_dummy) control(year zakazky_last3_dummy) ")
sum markup_dlw_gocogst,d
replace markup_dlw_gocogst= . if markup_dlw_gocogst<r(p1) | markup_dlw_gocogst >r(p99)
tabstat markup_dlw_gocogst, statistics( median )
tabulate year, summarize(markup_dlw_gocogst)
tabulate nace2, summarize(markup_dlw_gocogst)


/* plot the graph */
tw (kdensity markup_dlw_gocogst if nace2 == 41, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogst if nace2  == 42, lw(medthick) lp(-) lc(maroon)) /*
	*/ (kdensity markup_dlw_gocogst if nace2  == 43, lw(medthick) lp(.-.) lc(forest_green))  /*
	*/if markup_dlw_gocogst > 0 & markup_dlw_gocogst < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "41" 2 "42" 3 "43") cols(4))




//production function separately for procurement and non-procurement firms


*homogenous production function
*CD
bys nace2: markupest markup_dlw_gocogs,method(dlw) output(go) inputvar(cogs) free(cogs) state(k) proxy(proxy) verbose corrected  prodestopt(" reps(50) acf va attrition control(year zakazky_last3_dummy) endogenous(proxy zakazky_last3_dummy) ") replace
sum markup_dlw_gocogs,d
replace markup_dlw_gocogs= . if markup_dlw_gocogs<r(p1) | markup_dlw_gocogs >r(p99)
bysort year: egen markup_dlw_gocogs_p50 = pctile(markup_dlw_gocogs), p(50)
bysort year: egen markup_dlw_gocogs_p75 = pctile(markup_dlw_gocogs), p(75)
bysort year: egen markup_dlw_gocogs_p90 = pctile(markup_dlw_gocogs), p(90)
tabulate year, summarize(markup_dlw_gocogs)
tabulate nace2, summarize(markup_dlw_gocogs)	
tabulate  nace2, summarize(markup_dlw_gocogs_p50)	
tabulate  nace2, summarize(markup_dlw_gocogs_p75)	
tabulate  nace2, summarize(markup_dlw_gocogs_p90)
tabstat markup_dlw_gocogs, statistics( median )
gen lmu_1=ln(markup_dlw_gocogs) 

/* plot the graph */
tw (kdensity markup_dlw_gocogs if nace2 == 41, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogs if nace2  == 42, lw(medthick) lp(-) lc(maroon)) /*
	*/ (kdensity markup_dlw_gocogs if nace2  == 43, lw(medthick) lp(.-.) lc(forest_green))  /*
	*/ if markup_dlw_gocogs > 0 & markup_dlw_gocogs < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "41" 2 "42" 3 "43") cols(4))

tw (kdensity markup_dlw_gocogs if zakazky_last3_dummy == 1, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogs if zakazky_last3_dummy  == 0, lw(medthick) lp(-) lc(maroon)) /*
	*/ if markup_dlw_gocogs > 0 & markup_dlw_gocogs < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "1" 2 "0" ) cols(4))

*translog
bys nace2: markupest markup_dlw_gocogst,method(dlw) output(go) inputvar(cogs) free(cogs) state(k) proxy(proxy) verbose corrected  prodestopt(" reps(50) acf trans va attrition control(year zakazky_last3_dummy) endogenous(proxy zakazky_last3_dummy) ") replace
sum markup_dlw_gocogst,d
replace markup_dlw_gocogst= . if markup_dlw_gocogst<r(p1) | markup_dlw_gocogst >r(p99)
bysort year: egen markup_dlw_gocogst_p50 = pctile(markup_dlw_gocogst), p(50)
bysort year: egen markup_dlw_gocogst_p75 = pctile(markup_dlw_gocogst), p(75)
bysort year: egen markup_dlw_gocogst_p90 = pctile(markup_dlw_gocogst), p(90)
tabulate year, summarize(markup_dlw_gocogst)
tabulate nace2, summarize(markup_dlw_gocogst)	
tabulate  nace2, summarize(markup_dlw_gocogst_p50)	
tabulate  nace2, summarize(markup_dlw_gocogst_p75)	
tabulate  nace2, summarize(markup_dlw_gocogst_p90)	
tabstat markup_dlw_gocogst, statistics( median )
gen lmu_2=ln(markup_dlw_gocogst) 

/* plot the graph */
tw (kdensity markup_dlw_gocogst if nace2 == 41, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogst if nace2  == 42, lw(medthick) lp(-) lc(maroon)) /*
	*/ (kdensity markup_dlw_gocogst if nace2  == 43, lw(medthick) lp(.-.) lc(forest_green))  /*
	*/ if markup_dlw_gocogst > 0 & markup_dlw_gocogst < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "41" 2 "42" 3 "43") cols(4))

	tw (kdensity markup_dlw_gocogst if zakazky_last3_dummy == 1, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogst if zakazky_last3_dummy  == 0, lw(medthick) lp(-) lc(maroon)) /*
	*/ if markup_dlw_gocogst > 0 & markup_dlw_gocogst < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "1" 2 "0" ) cols(4))

	

*different production function for procurement vs. private
*CD
bys nace2: markupest markup_dlw_gocogs_p1 if zakazky_last3_dummy==1,method(dlw) output(go) inputvar(cogs) free(cogs) state(k) proxy(proxy) verbose corrected  prodestopt(" reps(50) acf va attrition control(year zakazky_last3_dummy) endogenous(proxy zakazky_last3_dummy) ") replace
sum markup_dlw_gocogs_p1,d
replace markup_dlw_gocogs_p1= . if markup_dlw_gocogs_p1<r(p1) | markup_dlw_gocogs_p1 >r(p99)
tabstat markup_dlw_gocogs_p1, statistics( median )
tabulate year, summarize(markup_dlw_gocogs_p1)
tabulate nace2, summarize(markup_dlw_gocogs_p1)
*
bys nace2: markupest markup_dlw_gocogs_p0 if zakazky_last3_dummy==0,method(dlw) output(go) inputvar(cogs) free(cogs) state(k) proxy(proxy) verbose corrected  prodestopt(" reps(50) acf va attrition control(year zakazky_last3_dummy) endogenous(proxy zakazky_last3_dummy) ") replace
sum markup_dlw_gocogs_p0,d
replace markup_dlw_gocogs_p0= . if markup_dlw_gocogs_p0<r(p1) | markup_dlw_gocogs_p0 >r(p99)
tabstat markup_dlw_gocogs_p0, statistics( median )
tabulate year, summarize(markup_dlw_gocogs_p0)
tabulate nace2, summarize(markup_dlw_gocogs_p0)
*
gen 	markup_dlw_gocogs_pp = markup_dlw_gocogs_p1 if zakazky_last3_dummy==1
replace markup_dlw_gocogs_pp = markup_dlw_gocogs_p0 if zakazky_last3_dummy==0
*
sum  markup_dlw_gocogs_pp,d

bysort year: egen markup_dlw_gocogs_pp_p50 = pctile(markup_dlw_gocogs_pp), p(50)
bysort year: egen markup_dlw_gocogs_pp_p75 = pctile(markup_dlw_gocogs_pp), p(75)
bysort year: egen markup_dlw_gocogs_pp_p90 = pctile(markup_dlw_gocogs_pp), p(90)
tabulate year, summarize(markup_dlw_gocogs_pp)
tabulate nace2, summarize(markup_dlw_gocogs_pp)	
tabulate  nace2, summarize(markup_dlw_gocogs_pp_p50)	
tabulate  nace2, summarize(markup_dlw_gocogs_pp_p75)	
tabulate  nace2, summarize(markup_dlw_gocogs_pp_p90)	
*
sum  markup_dlw_gocogs markup_dlw_gocogs_pp
cor  markup_dlw_gocogs markup_dlw_gocogs_pp
*
tabstat markup_dlw_gocogs_pp, statistics( median )
gen lmu_1_pp=ln(markup_dlw_gocogs_pp)
*


/* plot the graph */
*sector
tw (kdensity markup_dlw_gocogs_pp if nace2 == 41, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogs_pp if nace2  == 42, lw(medthick) lp(-) lc(maroon)) /*
	*/ (kdensity markup_dlw_gocogs_pp if nace2  == 43, lw(medthick) lp(.-.) lc(forest_green))  /*
	*/ if markup_dlw_gocogs_pp > 0 & markup_dlw_gocogs_pp < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "41" 2 "42" 3 "43") cols(4))

/* plot the graph */
*market
tw (kdensity markup_dlw_gocogs_pp if zakazky_last3_dummy==1, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogs_pp if zakazky_last3_dummy==0, lw(medthick) lp(-) lc(maroon)) /*
	*/ if markup_dlw_gocogs_pp > 0 & markup_dlw_gocogs_pp < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "Procurement active" 2 "Procurement inactive") cols(4))

/* plot the graph */
*sector-market
tw (kdensity markup_dlw_gocogs_pp if nace2 == 41 & zakazky_last3_dummy==0, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogs_pp if nace2 == 41& zakazky_last3_dummy==1, lw(medthick) lp(-) lc(maroon)) /*
	*/ (kdensity markup_dlw_gocogs_pp if nace2 == 42& zakazky_last3_dummy==0 , lw(medthick) lp(.-.) lc(forest_green)) (kdensity markup_dlw_gocogs_pp if nace2 == 42& zakazky_last3_dummy==1, lw(medthick) lp(-.-) lc(sand)) /*
	*/ (kdensity markup_dlw_gocogs_pp if nace2 == 43 & zakazky_last3_dummy==0, lw(medthick) lp(l) lc(navy)) (kdensity markup_dlw_gocogs_pp if nace2 == 43& zakazky_last3_dummy==1, lw(medthick) lp(dot) lc(purple)) /*
	*/ if markup_dlw_gocogs_pp > 0 & markup_dlw_gocogs_pp < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "41" 2 "41_pp" 3 "42" 4 "42_pp" 5 "43" 6 "43_pp" ) cols(4))

	
	
	
*trans
bys nace2: markupest markup_dlw_gocogst_p1 if zakazky_last3_dummy==1,method(dlw) output(go) inputvar(cogs) free(cogs) state(k) proxy(proxy) verbose corrected  prodestopt(" reps(50) acf trans va attrition control(year zakazky_last3_dummy) endogenous(proxy zakazky_last3_dummy) ") replace
sum markup_dlw_gocogst_p1,d
replace markup_dlw_gocogst_p1= . if markup_dlw_gocogst_p1<r(p1) | markup_dlw_gocogst_p1 >r(p99)
tabstat markup_dlw_gocogst_p1, statistics( median )
tabulate year, summarize(markup_dlw_gocogst_p1)
tabulate nace2, summarize(markup_dlw_gocogst_p1)
*
bys nace2: markupest markup_dlw_gocogst_p0 if zakazky_last3_dummy==0,method(dlw) output(go) inputvar(cogs) free(cogs) state(k) proxy(proxy) verbose corrected  prodestopt(" reps(50) acf trans va attrition control(year zakazky_last3_dummy) endogenous(proxy zakazky_last3_dummy) ") replace
sum markup_dlw_gocogst_p0,d
replace markup_dlw_gocogst_p0= . if markup_dlw_gocogst_p0<r(p1) | markup_dlw_gocogst_p0 >r(p99)
tabstat markup_dlw_gocogst_p0, statistics( median )
tabulate year, summarize(markup_dlw_gocogst_p0)
tabulate nace2, summarize(markup_dlw_gocogst_p0)
*
gen 	markup_dlw_gocogst_pp = markup_dlw_gocogst_p1 if zakazky_last3_dummy==1
replace markup_dlw_gocogst_pp = markup_dlw_gocogst_p0 if zakazky_last3_dummy==0
*
sum  markup_dlw_gocogst markup_dlw_gocogst_pp
cor  markup_dlw_gocogs_pp markup_dlw_gocogst_pp
*
tabulate nace2, summarize(markup_dlw_gocogst_pp)
tabstat markup_dlw_gocogst_pp, statistics( median )
gen lmu_2_pp=ln(markup_dlw_gocogst_pp)

/* plot the graph */
tw (kdensity markup_dlw_gocogst_pp if nace2 == 41, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogst_pp if nace2  == 42, lw(medthick) lp(-) lc(maroon)) /*
	*/ (kdensity markup_dlw_gocogst_pp if nace2  == 43, lw(medthick) lp(.-.) lc(forest_green))  /*
	*/ if markup_dlw_gocogst_pp > 0 & markup_dlw_gocogst_pp < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "41" 2 "42" 3 "43") cols(4))


/* plot the graph */
*market
tw (kdensity markup_dlw_gocogst_pp if zakazky_last3_dummy==1, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogst_pp if zakazky_last3_dummy==0, lw(medthick) lp(-) lc(maroon)) /*
	*/ if markup_dlw_gocogst_pp > 0 & markup_dlw_gocogst_pp < 3, ytitle("Density") xtitle("Markup") legend(order( 1 "Procurement active" 2 "Procurement inactive") cols(4))

	
save "data_with_markups", replace



	
/*
RESULTS
*/
use "data_with_results", replace
set seed 42

bys year: summarize(markup_dlw_gocogs_pp) if  zakazky_last3_dummy == 1

bys nace2: summarize(markup_OLS) ,d 
bys nace2: summarize(markup_dlw_gocogs) ,d 
bys nace2: summarize(markup_dlw_gocogs_pp) ,d 


bys zakazky_last3_dummy: summarize(markup_OLS) ,d 
bys zakazky_last3_dummy: summarize(markup_dlw_gocogs) ,d 
bys zakazky_last3_dummy: summarize(markup_dlw_gocogs_pp) ,d 


/* plot the graph */
*market
tw (kdensity markup_OLS if zakazky_last3_dummy==1, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_OLS if zakazky_last3_dummy==0, lw(medthick) lp(-) lc(maroon)) /*
	*/ if markup_OLS > 0 & markup_OLS < 3, ytitle("Density") xtitle("mu_OLS") legend(order( 1 "Procurement active" 2 "Procurement inactive") cols(4))

/* plot the graph */
*market
tw (kdensity markup_dlw_gocogs if zakazky_last3_dummy==1, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogs if zakazky_last3_dummy==0, lw(medthick) lp(-) lc(maroon)) /*
	*/ if markup_dlw_gocogs > 0 & markup_dlw_gocogs < 3, ytitle("Density") xtitle("mu") legend(order( 1 "Procurement active" 2 "Procurement inactive") cols(4))

/* plot the graph */
*market
tw (kdensity markup_dlw_gocogs_pp if zakazky_last3_dummy==1, lw(medthick) lp(_) lc(ebblue)) (kdensity markup_dlw_gocogs_pp if zakazky_last3_dummy==0, lw(medthick) lp(-) lc(maroon)) /*
	*/ if markup_dlw_gocogs_pp > 0 & markup_dlw_gocogs_pp < 3, ytitle("Density") xtitle("mu_pp") legend(order( 1 "Procurement active" 2 "Procurement inactive") cols(4))


/* plot the graph */
*whole industry
tw (kdensity lmu_OLS , lw(medthick) lp(_) lc(ebblue)) /*
	*/ (kdensity lmu_1, lw(medthick) lp(-) lc(maroon))/*
	*/ (kdensity lmu_1_pp , lw(medthick) lp(.-.) lc(forest_green)) /*
	*/ if (lmu_OLS > 0 & lmu_OLS< 1.1)&(lmu_1 > 0 & lmu_1 < 1.1)&(lmu_1_pp > 0 & lmu_1_pp < 1.1), ytitle("Density") xtitle("Logged markup") legend(order( 1 "lmu_OLS" 2  "lmu" 3 "lmu_pp"  ) cols(4))

	summarize(markup_OLS) if markup_OLS>3,d 
	summarize(markup_dlw_gocogs) if markup_OLS>3,d 
	summarize(markup_dlw_gocogs_pp) if markup_OLS>3,d 

correlate markup_dlw_gocogs zakazky_last3_dummy
correlate markup_dlw_gocogs_pp zakazky_last3_dummy

correlate markup_dlw_gocogs zakazky_last3_share 
correlate markup_dlw_gocogs_pp zakazky_last3_share 

tabulate zakazky_last3_dummy if nace2==41, summarize(markup_dlw_gocogs_pp)
tabulate zakazky_last3_dummy if nace2==42, summarize(markup_dlw_gocogs_pp)
tabulate zakazky_last3_dummy if nace2==43, summarize(markup_dlw_gocogs_pp)



graph twoway (tsline average_markup1) (tsline average_markup0), ///
  legend(label(1 1) label(2 0)) 

graph twoway (tsline median_markup1) (tsline median_markup0), ///
  legend(label(1 1) label(2 0)) 

 table year, contents(mean markup_dlw_gocogs_pp) by(zakazky_last3_dummy)
 
 
 
//pooled OLS
eststo clear
foreach j in OLS 1 1_pp {
    
	*dummy
	eststo: xi: qui reg lmu_`j' zakazky_last3_dummy cogs k i.year*i.nace2, cluster(id)
	
	*share
	eststo: xi: qui reg lmu_`j'  zakazky_last3_share  cogs k i.year*i.nace2, cluster(id)
	

}
noi esttab , ///
	cells(b(star fmt(%9.3f)) se(fmt(%9.3f)) ci(fmt(%9.2f))) stats(N, fmt(%9.0g) labels("N" )) starlevels(* 0.10 ** 0.05 *** 0.01)   ///
	label plain collabels(none) depvars numbers replace keep(zakazky_last3_dummy zakazky_last3_share )
	
//fixed effects	
eststo clear
foreach j in  OLS 1 1_pp {

	*dummy
	eststo: xi: qui xtreg lmu_`j'  zakazky_last3_share cogs k i.year*i.nace2  , cluster(id) fe i(id)
	
	

}
noi esttab , ///
	cells(b(star fmt(%9.2f)) se(fmt(%9.3f)) ci(fmt(%9.2f))) stats(N rho,  fmt(%9.0g) labels("N" "rho")) starlevels(* 0.10 ** 0.05 *** 0.01)   ///
	label plain collabels(none) depvars numbers replace keep(zakazky_last3_share )
	

*intensity revisited

gen share2 = zakazky_last3_share^2
xi: reg lmu_1_pp  zakazky_last3_dummy cogs k i.year*i.nace2  , cluster(id) 


//fixed effects	
eststo clear
foreach j in 1 1_pp {


	eststo: xi: qui xtreg lmu_`j'  zakazky_last3_share share2 cogs k i.year*i.nace2  , cluster(id) fe i(id)
	nlcom -_b[zakazky_last3_share]/(_b[share2]*2)
	gen sharestar_`j' = -_b[zakazky_last3_share]/(_b[share2]*2)
	nlcom sharestar_`j'*_b[zakazky_last3_share]+sharestar_`j'^2*_b[share2]
}

noi esttab , ///
	cells(b(star fmt(%9.3f)) se(fmt(%9.3f)) ci(fmt(%9.2f))) stats(N,  fmt(%9.0g) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01)   ///
	label plain collabels(none) depvars numbers replace keep(zakazky_last3_share share2)
	
	
xi: xtreg lmu_1  c.zakazky_last3_share##c.zakazky_last3_share cogs k i.year*i.nace2  , cluster(id) fe i(id)
	margins, dydx(zakazky_last3_share) at(zakazky_last3_share=(0(0.1)1))
	marginsplot
	
xi: xtreg lmu_1_pp  c.zakazky_last3_share##c.zakazky_last3_share cogs k i.year*i.nace2  , cluster(id) fe i(id)
	margins, dydx(zakazky_last3_share) at(zakazky_last3_share=(0(0.1)1))
	marginsplot

	
	save "data_with_results", replace

	*extra
	
* by sector
*OLS
reg   lmu_1  zakazky_last3_dummy cogs k i.year  if nace2==41 , cluster(id) 
reg   lmu_1  zakazky_last3_dummy cogs k i.year  if nace2==42 , cluster(id) 
reg   lmu_1  zakazky_last3_dummy cogs k i.year  if nace2==43 , cluster(id)

reg   lmu_1_pp  zakazky_last3_dummy cogs k i.year  if nace2==41 , cluster(id) 
reg   lmu_1_pp  zakazky_last3_dummy cogs k i.year  if nace2==42 , cluster(id) 
reg   lmu_1_pp zakazky_last3_dummy cogs k i.year  if nace2==43 , cluster(id)  

*FE
 xtreg   lmu_1  zakazky_last3_dummy cogs k i.year  if nace2==41 , cluster(id) fe i(id)
 xtreg   lmu_1  zakazky_last3_dummy cogs k i.year  if nace2==42 , cluster(id) fe i(id)
 xtreg   lmu_1  zakazky_last3_dummy cogs k i.year  if nace2==43 , cluster(id) fe i(id)

 xtreg   lmu_1_pp  zakazky_last3_dummy cogs k i.year  if nace2==41 , cluster(id) fe i(id)
 xtreg   lmu_1_pp  zakazky_last3_dummy cogs k i.year  if nace2==42 , cluster(id) fe i(id)
 xtreg   lmu_1_pp  zakazky_last3_dummy cogs k i.year  if nace2==43 , cluster(id) fe i(id)


//Robustness
	* with estimated productivity included	
use "data_with_markups", clear	
prodest go, va free(cogs) proxy(proxy) state(k) acf endogenous(zakazky_last3_dummy) control(year nace2 zakazky_last3_dummy)  fsresiduals(fs) id(id) t(year)
predict omega, omega
tabulate year, summarize(omega)



xi: xtreg lmu_1_pp omega zakazky_last3_dummy cogs k i.year*i.nace2, cluster(id) fe i(id)
	//pooled OLS
eststo clear
foreach j in OLS 1 1_pp {

	*dummy
	eststo: xi: qui reg lmu_`j' omega zakazky_last3_dummy cogs k i.year*i.nace2, cluster(id)

		*share
	eststo: xi: qui reg lmu_`j' omega  zakazky_last3_share  cogs k i.year*i.nace2, cluster(id)
	
	
}
noi esttab , ///
	cells(b(star fmt(%9.2f)) se(fmt(%9.3f)) ci(fmt(%9.2f))) stats(N, fmt(%9.0g) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01)   ///
	label plain collabels(none) depvars numbers replace keep(zakazky_last3_dummy zakazky_last3_share omega )
	
//fixed effects	
eststo clear
foreach j in OLS 1 1_pp {
	
	*dummy
	eststo: xi: qui xtreg lmu_`j' omega zakazky_last3_dummy cogs k i.year*i.nace2, cluster(id) fe i(id)

		*share
	eststo: xi: qui xtreg lmu_`j' omega zakazky_last3_share  cogs k i.year*i.nace2,cluster(id) fe i(id) 
	
	
}
noi esttab , ///
	cells(b(star fmt(%9.2f)) se(fmt(%9.3f)) ci(fmt(%9.2f))) stats(N, fmt(%9.0g) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01)   ///
	label plain collabels(none) depvars numbers replace keep(zakazky_last3_dummy zakazky_last3_share omega )
	
	
* with estimated productivity only
	
	
		//pooled OLS
eststo clear
foreach j in  1 1_pp {

	*dummy
	eststo: xi: qui reg lmu_`j' omega cogs k i.year*i.nace2, cluster(id)

}
noi esttab , ///
	cells(b(star fmt(%9.2f)) se(fmt(%9.3f)) ci(fmt(%9.2f))) stats(N, fmt(%9.0g) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01)   ///
	label plain collabels(none) depvars numbers replace keep( omega )
	
	save "productivity_result", replace

	
	
	
*cost share, Wooldridge, translog
use "data_with_results", clear	
*cost
gen costshare = COGS/(COGS+K)
sum costshare if zakazky_last3_dummy==0,d
gen markup_costshare=costshare/cogss
sum markup_costshare,d
replace markup_costshare= . if markup_costshare<r(p1) | markup_costshare >r(p99)
sum markup_costshare,d
*/
tabulate year, summarize(markup_costshare)
tabulate nace2, summarize(markup_costshare)	
tabulate zakazky_last3_dummy, summarize(markup_costshare)	
gen lmu_cs = ln(markup_costshare)

*Wooldridge
tabulate year, summarize(markup_wrdg_gocogs)
tabulate nace2, summarize(markup_wrdg_gocogs)
tabulate zakazky_last3_dummy, summarize(markup_wrdg_gocogs)	
gen lmu_wrdg = ln(markup_wrdg_gocogs)

*trans 
tabulate year, summarize(markup_dlw_gocogst)
tabulate nace2,  summarize(markup_dlw_gocogst)
tabulate zakazky_last3_dummy, summarize(markup_dlw_gocogst)	

tabulate year, summarize(markup_dlw_gocogst_pp)
tabulate nace2,  summarize(markup_dlw_gocogst_pp)
tabulate zakazky_last3_dummy, summarize(markup_dlw_gocogst_pp)	


//pooled OLS
eststo clear
foreach j in  cs wrdg 2_pp{

	*dummy
	eststo: xi: qui reg lmu_`j' zakazky_last3_dummy cogs k i.year*i.nace2, cluster(id)
	
	*share
	eststo: xi: qui reg lmu_`j'  zakazky_last3_share  cogs k i.year*i.nace2, cluster(id)
	

}
noi esttab , ///
	cells(b(star fmt(%9.2f)) se(fmt(%9.3f)) ci(fmt(%9.2f))) stats(N, fmt(%9.0g) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01)   ///
	label plain collabels(none) depvars numbers replace keep(zakazky_last3_dummy zakazky_last3_share )
	
//fixed effects	
eststo clear
foreach j in  cs wrdg 2 {

	*dummy
	eststo: xi: qui xtreg lmu_`j'  zakazky_last3_dummy cogs k i.year*i.nace2  , cluster(id) fe i(id)
	
	*share
	eststo: xi: qui xtreg lmu_`j'   zakazky_last3_share cogs k i.year*i.nace2  , cluster(id) fe i(id)
	

}
noi esttab , ///
	cells(b(star fmt(%9.2f)) se(fmt(%9.3f)) ci(fmt(%9.2f))) stats(N rho,  fmt(%9.0g) labels("N" "rho")) starlevels(* 0.10 ** 0.05 *** 0.01)   ///
	label plain collabels(none) depvars numbers replace keep(zakazky_last3_dummy zakazky_last3_share)
	
*intensity revisited


//pooled OLS
eststo clear
foreach j in cs wrdg 2 2_pp {
	eststo: xi: qui reg lmu_`j' zakazky_last3_share share2 cogs k i.year*i.nace2, cluster(id)
	nlcom -_b[zakazky_last3_share]/(_b[share2]*2)
}
noi esttab , ///
	cells(b(star fmt(%9.2f)) se(fmt(%9.3f)) ci(fmt(%9.2f))) stats(N, fmt(%9.0g) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01)   ///
	label plain collabels(none) depvars numbers replace keep(zakazky_last3_share share2)
	
//fixed effects	
eststo clear
foreach j in cs wrdg 2 2_pp {
	eststo: xi: qui xtreg lmu_`j'  zakazky_last3_share share2 cogs k i.year*i.nace2  , cluster(id) fe i(id)
	nlcom -_b[zakazky_last3_share]/(_b[share2]*2)
	gen sharestar_`j' = -_b[zakazky_last3_share]/(_b[share2]*2)
	nlcom sharestar_`j'*_b[zakazky_last3_share]+sharestar_`j'^2*_b[share2]
}

noi esttab , ///
	cells(b(star fmt(%9.3f)) se(fmt(%9.3f)) ci(fmt(%9.2f))) stats(N,  fmt(%9.0g) labels("N")) starlevels(* 0.10 ** 0.05 *** 0.01)   ///
	label plain collabels(none) depvars numbers replace keep(zakazky_last3_share share2)
	*/
	
save "alternative_result", replace



//A

/* plot the graph */
*sector-market
tw (kdensity lmu_1_pp if zakazky_last3_dummy==0 , lw(medthick) lp(l) lc(forest_green)) (kdensity lmu_1 if zakazky_last3_dummy==0, lw(medthick) lp(l) lc(ebblue))  /*
	*/ (kdensity lmu_1 if zakazky_last3_dummy==1, lw(medthick) lp(_) lc(maroon)) (kdensity lmu_1_pp if zakazky_last3_dummy==1, lw(medthick) lp(_) lc(sand)) /*
	*/ , ytitle("Density") xtitle("Logged markup") legend(order( 1 "lmu_pp0" 2 "lmu_0" 3  "lmu_1"  4 "lmu_pp1" ) cols(4))

	

tw (kdensity lmu_1 , lw(medthick) lp(_) lc(ebblue)) (kdensity lmu_1_pp , lw(medthick) lp(-) lc(maroon)) /*
	*/ , ytitle("Density") xtitle("Logged markup") legend(order( 1 "lmu_1" 2 "lmu_1_pp") cols(4))


tw  (kdensity markup_dlw_gocogs_pp if zakazky_last3_dummy==0 , lw(medthick) lp(_) lc(forest_green)) (kdensity markup_dlw_gocogs if   zakazky_last3_dummy==0, lw(medthick) lp(l) lc(ebblue)) /*
	*/ (kdensity markup_dlw_gocogs if zakazky_last3_dummy==1, lw(medthick) lp(l) lc(maroon))(kdensity markup_dlw_gocogs_pp if  zakazky_last3_dummy==1, lw(medthick) lp(_) lc(sand)) /*
	*/if(markup_dlw_gocogs > 0 & markup_dlw_gocogs < 3)&(markup_dlw_gocogs_pp > 0 & markup_dlw_gocogs_pp < 3) , ytitle("Density") xtitle("Markup") legend(order( 1 "mu_pp_0" 2 "mu_0" 3 "mu_1" 4 "mu_pp_1" ) cols(4))

	summarize(markup_dlw_gocogs_pp) if zakazky_last3_dummy==1 & markup_dlw_gocogs_pp>3,d
	summarize(markup_dlw_gocogs_pp) if zakazky_last3_dummy ==0& markup_dlw_gocogs_pp>3,d

	summarize(markup_dlw_gocogs) if zakazky_last3_dummy==1 & markup_dlw_gocogs>3,d
	summarize(markup_dlw_gocogs) if zakazky_last3_dummy ==0 & markup_dlw_gocogs>3,d
	

	
	
*diagnostics

	use "data_with_markups", clear	


*OLS

xi: reg lmu_1  c.zakazky_last3_share##c.zakazky_last3_share cogs k i.year*i.nace2 
predict resid, resid 
hist resid
kdensity resid, normal
pnorm resid
qnorm resid

xi: reg lmu_1_pp  zakazky_last3_dummy cogs k i.year*i.nace2 
predict resid_pp, resid
hist resid
kdensity resid_pp, normal
pnorm resid_pp
qnorm	resid_pp

*FE
xtset id year
xi: xtreg lmu_1  zakazky_last3_dummy cogs k i.year*i.nace2  , fe 
estimates store fe
xi: xtreg lmu_1  zakazky_last3_dummy cogs k i.year*i.nace2  , re
xttest0
estimates store re

*reject re
hausman fe re

xi: xtreg lmu_1_pp  zakazky_last3_dummy cogs k i.year*i.nace2  , fe 
estimates store fe_pp
xi: xtreg lmu_1  zakazky_last3_dummy cogs k i.year*i.nace2  , re
xttest0
estimates store re_pp

*reject re
hausman fe_pp re_pp

