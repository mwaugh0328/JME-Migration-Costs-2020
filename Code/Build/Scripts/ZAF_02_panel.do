/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Build South Africa Panel	
AUTHORS: 		Sam Marshall, Liana Wang, Sebastian Quaade			
CREATED:		7/11/2019
DESC: 			combine all files for South Africa and build
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Wave Files
****************************************************************/
forvalues i = 1/5 {
	use "${ZAFbuild}/intermediate/wave`i'_chars.dta", clear
	
	merge 1:1 pid using "${ZAFbuild}/intermediate/wave`i'_income.dta", nogen keep(match)

	gen wave = `i'

	save "${ZAFbuild}/saf_wave`i'.dta", replace
}

/****************************************************************
	SECTION 2: Panel
****************************************************************/

use "${ZAFbuild}/saf_wave1.dta", clear
append using "${ZAFbuild}/saf_wave2.dta"
append using "${ZAFbuild}/saf_wave3.dta"
append using "${ZAFbuild}/saf_wave4.dta"
append using "${ZAFbuild}/saf_wave5.dta"

compress

***** add price data *****
recode wave (1 = 2008) (2 = 2010) (3 = 2012) (4 = 2015) (5 = 2017), gen(year)
merge m:1 year using "${pxbuild}/CPI_GDPPC.dta", keep(match) nogen
drop *malawi *uganda *tanzania *indonesia *china

***** select sample *****
keep if age > 15

***** cap weekly hours and make annual *****
replace hours = 24 * 7 if hours > (24 * 7) & ~mi(hours)
replace hours = 52 * hours

***** create outcome variables *****
egen nadult = count(pid), by(hhid wave)


gen logearnings = ln(earnings)
gen consumption_pc = consumption / hhsize
gen logconsumption_pc = ln(consumption_pc)

gen consumption_pa = consumption / nadult
gen logconsumption_pa = ln(consumption_pa)

gen agesq = age^2
gen loghours =ln(hours)
gen loghourssq = loghours^2
gen educ2 = educ^2

***** make real earnings variables *****
sum CPI_south_africa if year == 2017
local base = r(mean)
gen logearnings_real = ln(earnings * `base' / CPI_south_africa)
gen logcons = ln(consumption * `base' / CPI_south_africa)
gen loghhearnings_pa = ln(hhincome/nadult* `base' / CPI_south_africa)
gen logcons_pa = ln(consumption / nadult * `base' / CPI_south_africa)

***** create migration variables *****
bys pid (wave): gen startUrban = urban[1]

bysort pid: egen ever_urban = max(urban)
bysort pid: egen ever_rural = min(urban)
replace ever_rural = 1 - ever_rural

bysort pid (wave): gen rural_leaver = urban[_n] == 0 & urban[_n+1] == 1 if _n != _N

rename dwgt weight

gen employed = earnings > 0 & ~mi(earnings)



***** other adjustments *****
rename marr_stat married
recode married (-9/-1 = .) (2 = 1) (3 4 = 5)

gen intrv_mo = ym(year(intrv_dt), month(intrv_dt))
format intrv_mo %tm
merge m:1 intrv_mo prov2011 using "${ZAFbuild}/intermediate/CPI.dta", keep(match master) nogen

gen ea = cluster
bysort pid (wave): replace ea= ea[1]


* load countries code
bysort pid (wave): gen rgn = prov2011[1]

do "${bldcode}/Support/cross_country_vars.do"

***** labels for use in regressions *****
label var loghours "Log hours"
label var loghourssq "Log hours squared"
label define lfs -1 "Out of the labor force" 0 "Unemployed" 1 "Employed"
label values lfs lfs
lab var wave "Wave"
label var logearnings "Log earnings, nominal"
lab var logearnings_real "Log earnings, real"
label var logcons "Log consumption, real"
label var consumption "Annual consumption"
label var weight "longitudinal weight, person level"
lab var married "Married"
lab var employed "Employed"

gen ctry_str = "South Africa"

save "${ZAFbuild}/saf_panel.dta", replace
save "${xcbuild}/South Africa.dta", replace

