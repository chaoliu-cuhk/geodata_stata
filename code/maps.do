clear all
set more off
global output = "C:\Users\ccerl\OneDrive\geodata_stata\output"
global data = "C:\Users\ccerl\OneDrive\geodata_stata\data"

//use shp2dta to convert 
shp2dta using "$data\us_county\cb_2019_us_county_500k.shp", ///
database("$data\us_county\usdb.dta") ///
coordinates("$data\us_county\uscoord.dta") ///
genid(id) replace

//merge with the variable you want to plot
use "$data\us_county\usdb.dta", clear
destring STATEFP, replace force
drop if STATEFP > 56
drop if STATEFP == 2
drop if STATEFP == 15
destring GEOID, gen(fips) force
merge 1:1 fips using "$data\county_badeng.dta", keep(3) nogen

//use spmap to draw maps
format (badeng) %5.2f
spmap badeng using "$data\us_county\uscoord.dta", ///
id(id) cln(5) fcolor(Blues) ndf(gs13) ///
legend(pos(4) size(medium)) title("Share of LEP Population")
graph export "$output\lepshare.png", as(png) replace
