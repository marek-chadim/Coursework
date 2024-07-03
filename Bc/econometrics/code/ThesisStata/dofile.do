************************************************************************
*Markups and Public Procurement
*bakalářská práce
*Institut ekonomických studií
*Matěj Bajgar, D.Phil.
*Marek Chadim
************************************************************************

*add mph
import delimited mph.csv, clear
rename ič ico
label variable ico "IČO"
rename mphmzdypřidanáhodnota mph
duplicates drop
duplicates drop ico rok, force
save "mph", replace
merge 1:1 ico rok using "magnus500", nogenerate
save "magnus500", replace

*merge 10-499 & 500 firm data
use "analyza499"
merge m:1 ico using "vybery499"
save "magnus499", replace
append using "magnus500"
duplicates drop // 4,214 observations delete
duplicates drop ico rok, force // 24,023 observations deleted

*correct pp if 1000 times too large
sum pp if pp<10^8,d
sum pp if pp>10^8,d
replace pp = pp/1000 if pp>10^8
sum pp,d

*generate variables
gen GO = trzby
gen W = mt * trzby / 100
gen II = naklady - W
replace II = . if II<0
gen VA = GO - II
gen L = VA / pp if VA/pp>0
gen K = aktiva
sum GO W II VA L K

*correct
replace GO = . if GO<0
replace W = . if W<0
replace K = . if K<0

*převedení do stálých cen
tostring nace, replace
gen nace2digit = substr(nace,1,2)
merge m:1 rok nace2digit using "deflators", nogenerate
duplicates drop ico rok, force
// (2,370 observations deleted)
save "Magnus", replace

gen dGO = GO/deflatorPRDP, 
gen dVA = VA/deflatorVALP
gen dII = II/deflatorINTP
gen dK = K/deflatorGFCP
gen dW = W/deflatorCPI


*gen log variables
gen go = ln(dGO)
gen w = ln(dW)
gen ii = ln(dII)
gen va = ln(dVA)
gen l = ln(L)
gen k = ln(dK)

*------------------------------------OLS estimates-----------------------------------------------*
reg go k w ii i.rok
gen bwols=_b[w]
gen bkols=_b[k]
gen alpha_w=mt/100
gen markup_OLS=_b[w]/alpha_w
tabstat markup_OLS, statistics( median ) //1.392014
tabulate rok, summarize(markup_OLS)		// mean(markup_OLS)= 2.4590351 

*fixed effects
xtreg go k w ii i.rok
gen bwolsfe=_b[w]
gen bkolsfe=_b[k]
gen markup_OLSfe=_b[w]/alpha_w
tabstat markup_OLSfe, statistics( median ) // 1.719291
tabulate rok, summarize(markup_OLSfe)	// mean(markup_OLSfe)= 3.0589033  

*------------------------------------WRDG estimates-----------------------------------------------*
*prodest
xtset ico rok
gen bwwrdg=_b[w]
gen bkwrdg=_b[k]
gen markup_wrdg=_b[w]/alpha_w
tabstat markup_wrdg, statistics( median ) //1.141888
tabulate rok, summarize(markup_wrdg)	// mean(markup_wrdg)= 2.0316077

//prodest go, method(wrdg) free(w) proxy(ii) state(k) translog
//predict, parameters
//gen bwwrdgt=
//gen bkwrdgt=
//gen markup_wrdgt=
//tabstat markup_wrdgt, statistics( median ) //
//tabulate rok, summarize(markup_wrdgt)	// mean(markup_wrdgt)= 

*------------------------------------LP estimates-----------------------------------------------*
prodest go, method(lp) free(w) proxy(ii) state(k) 
gen bwlp=_b[w]
gen bklp=_b[k]
gen markup_lp=_b[w]/alpha_w
tabstat markup_lp, statistics( median ) //1.37563
tabulate rok, summarize(markup_wrdg)	// mean(markup_lp)= 2.0316077

*------------------------------------ACF estimates-----------------------------------------------*
prodest va, va method(lp) free(w) proxy(ii) state(k) acf
gen bwacf=_b[w]
gen bkacf=_b[k]
gen markup_acf=_b[w]/alpha_w
tabstat markup_acf, statistics( median ) //5.398242?
tabulate rok, summarize(markup_acf)	// mean(markup_acf)= 9.6043651?

prodest va, va method(lp) free(w) proxy(ii) state(k) acf translog
predict, parameters
//beta_w                                           0.694
//beta_k                                           0.044
gen bwacft=_b[w]
gen bkacft=_b[k]
gen markup_acft=_b[w]/alpha_w
tabstat markup_acft, statistics( median ) // 0.4283148?
tabulate rok, summarize(markup_acft)	// mean(markup_acft)= 0.76204288?

*markupest
markupest markupDLWgo, method(dlw) output(go) inputvar(w) free(w) state(k) proxy(ii) verbose 
markupest markupDLWva, method(dlw) output(va) inputvar(w) free(w) state(k) proxy(ii)  prodestopt("poly(3) acf trans va") corrected verbose

save "Magnus", replace

*merge tenders & firm data
use "Magnus", clear
drop _merge
save "Magnus", replace
use "tenders", clear
merge m:1 ico rok using "Magnus"

// Result                           # of obs.
  //  not matched                       862,492
    //    from master                   830,549  (_merge==1)
    //    from using                     31,943  (_merge==2)
  //  matched                            99,395  (_merge==3)
  
save "tendersmerge", replace
