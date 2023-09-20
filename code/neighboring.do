clear all
set more off
global output = "C:\Users\ccerl\OneDrive\geodata_stata\output"
global data = "C:\Users\ccerl\OneDrive\geodata_stata\data\ipums_puma_2000"

shp2dta using "$data\ipums_puma_2000.shp", genid(_ID) ///
data("$data\puma2000.dta") coor("$data\puma2000_coor.dta") replace

use "$data\puma2000_coor.dta", clear
/* remove duplicates within each polygon and missing coordinates that
indicate the start of a new polygon */
drop if mi(_Y, _X)
gduplicates drop _Y _X _ID, force

/* reduce to coordinates that appear in more than one polygon */
bys _Y _X: keep if _N > 1

/* switch to wide form and reduce to one obs per conterminous country set */
by _Y _X: gen j = _n
greshape wide _ID, i(_Y _X) j(j)
keep _ID*
gduplicates drop _ID*, force

/* switch back to long form and form all pairwise combinations within the set */
gen set = _n
greshape long _ID, i(set)
drop if mi(_ID)
drop _j
save "$data\puma_sets.dta", replace
rename _ID _ID_pair
joinby set using "$data\puma_sets.dta"
drop if _ID == _ID_pair

/* remove duplicates and merge with database to get the name */
bysort _ID _ID_pair: keep if _n == 1
merge m:1 _ID using "$data\puma2000.dta", assert(match using) keep(match) nogen
    
rename (_ID _ID_pair STATEFIP PUMA GISMATCH) (_ID_pair _ID STATEFIP1 PUMA1 GISMATCH1) 
merge m:1 _ID using "$data\puma2000.dta", assert(match using) keep(match) nogen
rename (STATEFIP PUMA GISMATCH) (STATEFIP2 PUMA2 GISMATCH2) 

/* final list */
isid GISMATCH1 GISMATCH2, sort
save "$output\neighboring_puma2000.dta", replace

keep if STATEFIP1 != STATEFIP2
save "$output\bordering_puma2000.dta", replace
