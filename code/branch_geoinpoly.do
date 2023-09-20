clear all
set more off
global output = "C:\Users\ccerl\OneDrive\geodata_stata\output"
global data = "C:\Users\ccerl\OneDrive\geodata_stata\data"

//use shp2dta to convert 
shp2dta using "$data\us_county\cb_2019_us_county_500k.shp", ///
database("$data\us_county\usdb.dta") ///
coordinates("$data\us_county\uscoord.dta") ///
genid(_ID) replace

//use geoinpoly
use "$data\branch_2019.dta", clear
drop if sims_latitude == . | sims_longitude == .
geoinpoly sims_latitude sims_longitude using "$data\us_county\uscoord.dta"
merge m:1 _ID using "$data\us_county\usdb.dta", keep(1 3) nogen

//check
destring GEOID, gen(fips) force
gen correct = stcntybr == fips
tab correct