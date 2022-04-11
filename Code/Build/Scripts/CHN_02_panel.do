/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Build China Panel
AUTHORS: 		Sam Marshall, Min Byung Chae, John Mori		
CREATED:		9/4/2019
DESC: 			Create panel for China
ORG:			SECTION 1: Wave Files
				SECTION 2: Panel		
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Wave Files
****************************************************************/
forvalues i = 1/4 {
	use "${CHNbuild}/intermediate/w`i'_demog.dta", clear
	merge m:1 fid using "${CHNbuild}/intermediate/w`i'_consumption.dta", nogen
	gen wave = `i'

	save "${CHNbuild}/chn_wave`i'.dta", replace
}

/****************************************************************
	SECTION 2: Panel
****************************************************************/
use "${CHNbuild}/chn_wave1.dta", clear
append using "${CHNbuild}/chn_wave2.dta"
append using "${CHNbuild}/chn_wave3.dta"
append using "${CHNbuild}/chn_wave4.dta"

***** add price data *****
recode wave (1 = 2010) (2 = 2012) (3 = 2014) (4 = 2016), gen(year)
merge m:1 year using "${pxbuild}/CPI_GDPPC.dta", keep(match) nogen
drop *malawi *uganda *tanzania *indonesia *south_africa

***** select sample *****
keep if age > 15
drop if non_chinese == 1
gen hhid = fid

***** adjustments *****
rename income_ earnings
rename *_ *

rename employed lfs
gen employed = lfs == 1

***** create outcome variables *****
gen logearnings = ln(earnings)
gen logfearnings = ln(fincome)

gen agesq = age^2
gen educ2 = educ^2

***** make real earnings variables *****
sum CPI_china if year == 2016
local base = r(mean)
gen logearnings_real = ln(earnings * `base' / CPI_china)
gen logfearnings_real = ln(fincome * `base' / CPI_china)
gen logcons = ln(consumption * `base' / CPI_china)
gen logcons_pa = ln(consumption / nadult * `base' / CPI_china)

***** create migration variables *****

bysort pid (wave): gen cidDif = cid[_n] != cid[_n-1] if !inlist(., cid[_n], cid[_n -1])
bysort pid (wave): gen urbanDif = urban[_n] != urban[_n-1] if !inlist(., urban[_n], urban[_n -1])
bysort pid (wave): replace urban = urban[_n-1] if cidDif == 0 & urbanDif == 1

gen food_share = food/consumption

bysort pid: egen ever_urban = max(urban)
bysort pid: egen ever_rural = min(urban)
replace ever_rural = 1 - ever_rural

bysort pid (wave): gen rural_leaver = urban[_n+1] == 1 if urban[_n] == 0


recode hukou (3 = 0)

gen ea = psu
bysort pid (wave): replace ea = ea[1]

* load countries code
bysort pid (wave): gen rgn = provcd[1]
*bys pid (wave): gen ea = psu[1]
bys pid (wave): gen startUrban = urban[1]
bysort pid (wave): gen fprov = provcd[1]


do "${bldcode}/Support/cross_country_vars.do"

label var logearnings "Log Earnings"
lab var wave "Wave"
label var logearnings "Log earnings, nominal"
lab var logearnings_real "Log earnings, real"
label var logcons "Log consumption, real"
label var weight "longitudinal weight, person level"
label var hukou "Agricultural Hukou"
label var rgn "Province Code first interview round"
label var fprov "Province Code first interview round"

gen ctry_str = "China"

drop if fid == .  
save "${CHNbuild}/chn_panel.dta", replace
save "${xcbuild}/China.dta", replace
