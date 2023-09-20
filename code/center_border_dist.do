clear all
set more off

**# state border 2000 #
cd "C:\Users\ccerl\OneDrive\mortgage broker\border\tl_2010_us_state00"

shp2dta using "tl_2010_us_state00.shp", genid(_ID) data("state00.dta") coor("state00_coor.dta") replace

use "state00_coor.dta", clear
drop if mi(_Y,_X)
merge m:1 _ID using "state00.dta", keep(3) nogen
destring STATEFP00, gen(state_code)
save "border_points.dta", replace

**# all state borders (two-way) #
use "C:\Users\ccerl\OneDrive\mortgage broker\border\county_border_distance.dta", clear
gduplicates drop st1 st2, force
gen st21 = st2
gen st22 = st1
expand 2, gen(new)
replace st1 = st21 if new == 1
replace st2 = st22 if new == 1
keep st1 st2 border
sort st1 st2
gegen border_idx = group(border)
save "C:\Users\ccerl\OneDrive\mortgage broker\border\all_state_borders.dta", replace

**# puma center #1
import delimited "C:\Users\ccerl\OneDrive\mortgage broker\border\geocorr2000_06MAY1949418.csv", clear
rename v1 state_code
rename v2 puma
rename v3 state
rename v4 lon
rename v5 lat
drop v6 v7
drop in 1/2
destring lon lat, replace
destring state_code, replace
save "C:\Users\ccerl\OneDrive\mortgage broker\border\puma2000_center.dta", replace

clear 
gen t = .
tempfile out
save `out', replace 

use "C:\Users\ccerl\OneDrive\mortgage broker\border\all_state_borders.dta", clear
levelsof st1, local(states)

foreach state of local states {
	use "C:\Users\ccerl\OneDrive\mortgage broker\border\puma2000_center.dta", clear
	keep if state_code == `state'
	rename state_code orig_state
	tempfile tmp
	save `tmp', replace

	use "C:\Users\ccerl\OneDrive\mortgage broker\border\all_state_borders.dta", clear
	keep if st1 == `state'
	keep st2
	rename st2 state_code 
	merge 1:m state_code using "border_points.dta", keep(3) nogen
	cross using `tmp'
	geodist lat lon _Y _X, miles sphere generate(distance)
	gcollapse (min) distance, by(orig_state puma state_code)
	append using `out' 
	save `out', replace
	
}
drop t
save "C:\Users\ccerl\OneDrive\mortgage broker\border\puma_border_distance.dta", replace


**# county #2
import delimited "C:\Users\ccerl\OneDrive\mortgage broker\border\geocorr2000_06MAY2011529.csv", clear
rename v1 fips
rename v3 lon
rename v4 lat
drop v*
drop in 1/2
destring fips lon lat, replace
gen state_code = (fips - mod(fips, 1000)) / 1000
save "C:\Users\ccerl\OneDrive\mortgage broker\border\county2000_center.dta", replace

clear 
gen t = .
tempfile out
save `out', replace 

use "C:\Users\ccerl\OneDrive\mortgage broker\border\all_state_borders.dta", clear
levelsof st1, local(states)

foreach state of local states {
	use "C:\Users\ccerl\OneDrive\mortgage broker\border\county2000_center.dta", clear
	keep if state_code == `state'
	rename state_code orig_state
	tempfile tmp
	save `tmp', replace

	use "C:\Users\ccerl\OneDrive\mortgage broker\border\all_state_borders.dta", clear
	keep if st1 == `state'
	keep st2
	rename st2 state_code 
	merge 1:m state_code using "border_points.dta", keep(3) nogen
	cross using `tmp'
	geodist lat lon _Y _X, miles sphere generate(distance)
	gcollapse (min) distance, by(fips state_code)
	append using `out' 
	save `out', replace
	
}
drop t
rename state_code out_state
save "C:\Users\ccerl\OneDrive\mortgage broker\border\county_border_distance_new.dta", replace


**# zcta5 #3
import delimited "C:\Users\ccerl\OneDrive\mortgage broker\border\geocorr2000_06MAY2012676.csv", clear 
rename v1 zcta5
rename v3 lon
rename v4 lat
drop v*
drop in 1/2
destring zcta5 lon lat, replace
destring zcta5, replace force
drop if zcta5 == .
//add one step: which state?
geoinpoly lat lon using "state00_coor.dta"
merge m:1 _ID using "state00.dta"
keep if _merge == 3
drop _merge
destring STATEFP00, gen(state_code)
keep zcta5 lon lat state_code
sort state_code
save "C:\Users\ccerl\OneDrive\mortgage broker\border\zcta2000_center.dta", replace

clear 
gen t = .
tempfile out
save `out', replace 

use "C:\Users\ccerl\OneDrive\mortgage broker\border\all_state_borders.dta", clear
levelsof st1, local(states)

foreach state of local states {
	use "C:\Users\ccerl\OneDrive\mortgage broker\border\zcta2000_center.dta", clear
	keep if state_code == `state'
	rename state_code orig_state
	tempfile tmp
	save `tmp', replace

	use "C:\Users\ccerl\OneDrive\mortgage broker\border\all_state_borders.dta", clear
	keep if st1 == `state'
	keep st2
	rename st2 state_code 
	merge 1:m state_code using "border_points.dta", keep(3) nogen
	cross using `tmp'
	geodist lat lon _Y _X, miles sphere generate(distance)
	gcollapse (min) distance, by(zcta5 state_code)
	append using `out' 
	save `out', replace
	
}
drop t
rename state_code out_state
merge m:1 zcta5 using "C:\Users\ccerl\OneDrive\mortgage broker\border\zcta2000_center.dta"
keep if _merge == 3
drop _merge
save "C:\Users\ccerl\OneDrive\mortgage broker\border\zcta5_border_distance.dta", replace

**# county center xc xy #
use "C:\Users\ccerl\OneDrive\mortgage broker\border\county2000_center.dta", clear
//y: lat, x: lon
gegen xbar = mean(lon) 
gegen ybar = mean(lat) 
gen xc = lon - xbar
gen yc = lat - ybar
drop xbar ybar

gen xc2 = xc^2
gen xc3 = xc^3
gen xc4 = xc^4
gen xcyc = xc * yc
gen yc2 = yc^2
gen yc3 = yc^3
gen yc4 = yc^4
gen xc2yc = xc2 * yc
gen xcyc2 = xc * yc2
gen xcyc3 = xc * yc3
gen xc2yc2 = xc2 * yc2
gen xc3yc = xc3 * yc

save "C:\Users\ccerl\OneDrive\mortgage broker\border\county2000_center_xcyc.dta", replace



