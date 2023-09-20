clear all
set more off
cd "C:\Users\ccerl\OneDrive\mortgage broker\border\ipums_conspuma"

**# neighboring PUMA2000 #1
shp2dta using "ipums_conspuma.shp", genid(_ID) data("conspuma.dta") coor("conspuma_coor.dta") replace

use "conspuma_coor.dta", clear
* remove duplicates within countries and missing coordinates which
* indicate the start of a new polygon
bysort _Y _X _ID: keep if _n == 1 & !mi(_Y,_X)

* reduce to coordinates that appear in more than one country
by _Y _X: keep if _N > 1

* switch to wide form and reduce to one obs per conterminous country set
by _Y _X: gen j = _n
greshape wide _ID, i(_Y _X) j(j)
keep _ID*
bysort _ID*: keep if _n == 1

* switch back to long form and form all pairwise combinations within the set
gen set = _n
greshape long _ID, i(set)
drop if mi(_ID)
drop _j
save "puma_sets.dta", replace
rename _ID _ID_pair
joinby set using "puma_sets.dta"
drop if _ID == _ID_pair

* remove duplicates and merge with database to get the name
bysort _ID _ID_pair: keep if _n == 1
merge m:1 _ID using "conspuma.dta", assert(match using) keep(match) nogen
    
rename (_ID _ID_pair CONSPUMA STATEFIP State) (_ID_pair _ID CONSPUMA1 STATEFIP1 State1) 
merge m:1 _ID using "conspuma.dta", assert(match using) keep(match) nogen
rename (CONSPUMA STATEFIP State) (CONSPUMA2 STATEFIP2 State2) 

* final list
isid CONSPUMA1 CONSPUMA2, sort
save "neighboring_conspuma.dta", replace

keep if STATEFIP1 != STATEFIP2
save "bordering_conspuma.dta", replace
