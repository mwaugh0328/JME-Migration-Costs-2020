/*****************************************************************
PROJECT: 		Rural-Urban Migration 				
TITLE:			Build Indonesia Panel	
AUTHOR: 		Min Byung Chae, Sam Marshall
MODIFIED:		7/31/2019 
DESC: 			combine all files for Indonesia and build panel dataset
ORG:				
INPUTS: 		IFLS`i'_demog.dta, IFLS`i'_income.dta, IFLS`i'_reasons.dta				
OUTPUTS: 		idn_panel.dta			
NOTE:			
******************************************************************/

* initiate globals if not done already
version 14.1
/****************************************************************
	SECTION 1: Merging within the waves
****************************************************************/

 forvalues i = 1/5 {
	use "${IDNbuild}/intermediate/IFLS`i'_consumption.dta", clear
	merge 1:1 hhid using "${IDNbuild}/intermediate/IFLS`i'_hhlevelInc.dta", gen(_mhhinc)
	merge 1:m hhid using "${IDNbuild}/intermediate/IFLS`i'_income.dta", nogen
	drop if pidlink == ""
	merge 1:1 pidlink using "${IDNbuild}/intermediate/IFLS`i'_urban.dta", nogen
	noi merge 1:1 pidlink using "${IDNbuild}/intermediate/IFLS`i'_demog.dta", nogen keep(3)
	noi merge 1:1 pidlink using "${IDNbuild}/intermediate/IFLS`i'_weights.dta", nogen keep(3)

	cap confirm variable wave
	if _rc{
		gen wave = `i'
	}
	else {
		replace wave = `i'
	}
	keep if age > 15
	
	save "${IDNbuild}/idn_wave`i'.dta", replace
}

/****************************************************************
	SECTION 2: Creating the panel
****************************************************************/
use "${IDNbuild}/idn_wave1.dta", clear
forvalues i = 2/5 {
	append using "${IDNbuild}/idn_wave`i'.dta"
}

/****************************************************************
* Correcting for outlier ea
****************************************************************/
bysort pid (wave): replace ea = ea[1]
egen m_ea = max(ea), by(hhid wave)
replace ea =m_ea if mi(ea)

bysort pid (wave): gen rural_leaver = urban[_n] == 0 & urban[_n+1] == 1 if _n != _N & !inlist(. , urban[_n], urban[_n+1])

label var rural_leaver "Individual-wave specific rural-urban migration indicator"
egen earl_wave = mean(rural_leaver) , by(ea wave)

merge 1:1 pidlink wave using "${IDNbuild}/intermediate/IFLS_migration.dta", gen(_mmig)
gen mig_wave = _mmig == 3
bysort pidlink (wave): gen switch_wave = urban[_n-1] != urban[_n] if _n != 1 & !mi(urban[_n-1]) & !mi(urban[_n])
egen switch_frac = mean(switch_wave), by(ea wave)
bysort pidlink (wave): replace urban = urban[_n-1] if switch_frac > .7

foreach i in 1 2 3 4 5 {
	bysort pidlink (wave): replace switch_wave = urban[_n-1] != urban[_n] if _n != 1 & !mi(urban[_n-1]) & !mi(urban[_n])
	drop switch_frac
	egen switch_frac = mean(switch_wave), by(ea wave)
	bysort pidlink (wave): replace urban = urban[_n-1] if switch_frac > .7
}

bysort pidlink (wave): gen urban_det_lag = urban_det[_n-1]
replace urban_det = urban_det_lag if urban_det == .

recode urban_det (1 3 = 0) (5 = 1), gen(urban_alt)
recode urban_det (1 = 0) (3 5 = 1), gen(urban_hklm)

merge m:1 year using "${pxbuild}/CPI_GDPPC.dta", keep(match) nogen
drop *south_africa *uganda *tanzania *malawi urban_det_lag *china

/****************************************************************
	SECTION 3: Earnings Make earnings Real
****************************************************************/
egen earnWage = rowtotal(earn_primary earn_secondary)
egen hhwageInc = sum(earnWage), by(hhid wave)
egen hhselfInc = sum(earn_self), by(hhid wave)
egen hhbusInc = rowmax(hhselfInc busInc)
winsor2 hhwageInc hhselfInc hhlevelInc busInc farmInc consumption, cuts(0.5, 99.5) replace
gen hhearnings = hhwageInc + hhbusInc + farmInc
gen hhearnings2 = hhwageInc + hhselfInc + farmInc
gen hhearnings3 = hhwageInc + busInc + farmInc

label var hhearnings "Household earnings (N.F. Bus = max of self, hh mods)"
label var hhearnings2 "Household earnings (N.F. Bus self mod)"
label var hhearnings3 "Household earnings (N.F. Bus = hh mod)"

***** Number of adults per household ******
encode pidlink, gen(pid)
egen nadult = count(pid), by(hhid wave)

sum CPI_indonesia if year == 2014
local base = r(mean)
gen logearnings_real = ln(earnings * `base' / CPI_indonesia)
gen loghhearnings = log(hhearnings * `base' / CPI_indonesia/nadult)

gen loghhearnings_pa_real = log(hhearnings/nadult * `base' / CPI_indonesia)
gen logcons_pa = ln(consumption / nadult * `base' / CPI_indonesia)


***** nominal values *****
gen logearnings = ln(earnings)

***** other variables *****
gen agesq = (age)^2
gen loghours = asinh(hours)
gen loghours2 = (loghours)^2
gen educ2 = (educ)^2


bysort pidlink: egen ever_urban = max(urban)
bysort pidlink: egen ever_rural = min(urban)
replace ever_rural = 1 - ever_rural

drop  hhid93 hhid97 hhid00 hhid07 hhid14 


/****************************************************************
	SECTION 2.3: FINAL
****************************************************************/

* load countries code
rename urban urban_loc
gen urban = urban_alt
recode urban_det (1 = 0) (3 = 1) (5 = .), gen(urban_small)
recode urban_det (1 = 0) (3 = .) (5 = 1), gen(urban_large)
gen loghhearnings_pa = loghhearnings_pa_real
gen loghourssq = loghours2
encode kabid, gen(kabid1)
bysort pid (wave): replace ea = kabid1[1]
gen mi_urb = mi(urban)
bys pid mi_urb (wave): gen startUrban = urban[1]

do "${bldcode}/Support/cross_country_vars.do"

egen max_urb_hklm = max(urban_hklm), by(pid)
egen min_urb_hklm = min(urban_hklm), by(pid)
bys pid (wave): gen startUrban_hklm = urban[1]
gen switcher_hklm = max_urb_hklm != min_urb_hklm
gen miReas = 1-mi(move_reason)
bysort pid (miReas wave ): replace move_reason = move_reason[_N]
egen mreason = mode(move_reason), min by(pid)
label define move_reason 1 "work" 2 "education" 3 "family" 4 "other"
recode mreason (3 5/99 = 4) (4 = 3)

lab var married "Married"
lab var employed "Employed"
lab var wave "Wave"
label var loghours "Log hours"
label var loghours2 "Log hours squared"
label var logearnings "Log earnings, nominal"
lab var logearnings_real "Log earnings, real"
label var logcons "Log consumption, real"
label var logcons_pa "Log consumption per adult, real"

label define rur 1 "Village" 3 "Small town" 5 "Big city"
label define mv_reas 1 "work" 2 "education" 4 "family" 5 "other"	
label values born_urban_det rur
label values age12_urban_det rur
label values urban_det rur
label values move_reason mv_reas
label var urban_det "Detailed urban code"
label var move_reason "Reason for move"
label var urban_alt "Urban coding from detail"
label var urban_hklm "Urban coding from Hicks et al."
label var own_work "reason for move was own work"

gen ctry_str = "Indonesia"

compress
save "${IDNbuild}/idn_panel.dta", replace
save "${xcbuild}/Indonesia.dta", replace

