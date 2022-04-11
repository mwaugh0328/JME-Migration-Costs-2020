/*****************************************************************
PROJECT: 	Rural-Urban Migration 			
TITLE:		Build Tanzania Panel		
AUTHOR: 	Sam Marshall
CREATED:	5/17/2019
DESC: 		combine all files for Tanzania and build
ORG:		SECTION 1: Create pidlink	
			SECTION 2: Wave 1
			SECTION 3: Wave 2
			SECTION 4: Wave 3
			SECTION 5: Panel
INPUTS: 				
OUTPUTS: 	tza_panel.dta			
NOTE:		Requires program geodist
******************************************************************/

* ssc install geodist 
* initiate globals if not done already

/****************************************************************
	SECTION 1: Create pidlink
****************************************************************/
* get hhid and memno var, unchanged from w1 and make pidlink
use "${TZAraw}/Wave 1 2008-2009/SEC_B_C_D_E1_F_G1_U.dta", clear
keep hhid sbmemno
gen firstwave = 1
gen pidlink = hhid + "-" + string(sbmemno)
save "${TZAbuild}/intermediate/pidlink.dta", replace  // 16,709

* update pidlink and make second version for merging the next wave
use "${TZAraw}/Wave 2 2010-2011/HH_SEC_B.dta", clear
gen pidlink = hhid_2008 + "-" + string(hh_b06)
	replace pidlink = y2_hhid + "-" + string(indidy2) if hh_b06 == 99
keep y2_hhid indidy2 pidlink	
merge 1:1 pidlink using "${TZAbuild}/intermediate/pidlink.dta"
replace firstwave = 2 if _merge == 1
gen pidlinkw2 = y2_hhid + "-" + string(indidy2)
	replace pidlinkw2 = hhid + "-" + string(sbmemno) if _merge == 2
save "${TZAbuild}/intermediate/pidlink.dta", replace  // 21,671

use "${TZAraw}/Wave 3 2012-2013/HH_SEC_B.dta", clear
gen pidlinkw2 = y2_hhid + "-" + string(hh_b06)
	replace pidlinkw2 = y3_hhid + "-" + string(indidy3) if hh_b06 == 99 | y2_hhid == ""
keep y3_hhid indidy3 pidlinkw2
merge 1:1 pidlinkw2 using "${TZAbuild}/intermediate/pidlink.dta", gen(_merge2)
replace firstwave = 3 if _merge == 1

* adjust master pidlink
replace pidlink = pidlinkw2 if pidlink == ""
label var pidlink "crosswave unique individual identifier"

drop pidlinkw2 _merge _merge2

save "${TZAbuild}/intermediate/pidlink.dta", replace 

/****************************************************************
	SECTION 2: Wave 1
****************************************************************/

use "${TZAbuild}/intermediate/wave1_chars.dta", clear
merge 1:1 hhid sbmemno using "${TZAbuild}/intermediate/wave1_income.dta", nogen
merge m:1 hhid using "${TZAbuild}/intermediate/wave1_consumption.dta", nogen
merge 1:m hhid sbmemno using "${TZAbuild}/intermediate/pidlink.dta", keep(match) nogen

gen wave = 1

save "${TZAbuild}/tza_wave1.dta", replace


/****************************************************************
	SECTION 3: Wave 2
****************************************************************/

use "${TZAbuild}/intermediate/wave2_chars.dta", clear
merge 1:1 y2_hhid indidy2 using "${TZAbuild}/intermediate/wave2_income.dta", nogen
merge m:1 y2_hhid using "${TZAbuild}/intermediate/wave2_consumption.dta", nogen
merge 1:m y2_hhid indidy2 using "${TZAbuild}/intermediate/pidlink.dta", keep(match) nogen

gen wave = 2

save "${TZAbuild}/tza_wave2.dta", replace


/****************************************************************
	SECTION 4: Wave 3
****************************************************************/

use "${TZAbuild}/intermediate/wave3_chars.dta", clear
merge 1:1 y3_hhid indidy3 using "${TZAbuild}/intermediate/wave3_income.dta", nogen
merge m:1 y3_hhid using "${TZAbuild}/intermediate/wave3_consumption.dta", nogen
merge 1:m y3_hhid indidy3 using "${TZAbuild}/intermediate/pidlink.dta", keep(match) nogen

gen wave = 3

save "${TZAbuild}/tza_wave3.dta", replace

/****************************************************************
	SECTION 5: Panel
****************************************************************/

use "${TZAbuild}/tza_wave1.dta", clear
append using "${TZAbuild}/tza_wave2.dta"
append using "${TZAbuild}/tza_wave3.dta"
gen pid = pidlink //harmonizing across datasets

drop ea
bysort pid (wave): gen ea = clusterid[1]

compress

***** add price data *****
recode wave (1 = 2009) (2 = 2011) (3 = 2013), gen(year)
merge m:1 year using "${pxbuild}/CPI_GDPPC.dta", keep(match) nogen
drop *south_africa *uganda *malawi *indonesia *china

* select sample
keep if age > 15

***** create outcome variables *****
encode pid, gen(pidN)
drop pid
ren pidN pid
egen nadult = count(pid), by(hhid wave)

gen logearnings = ln(earnings)
gen logwage = ln(earnings / hours)
gen agesq = age^2
gen loghours =ln(hours)
gen loghourssq = loghours^2
gen educ2 = educ^2

***** make real earnings variables *****
sum CPI_tanzania if year == 2013
local base = r(mean)
gen logearnings_real = ln(earnings * `base' / CPI_tanzania)
gen logcons = ln(consumption * `base' / CPI_tanzania)
gen logcons_pc = ln(consumption / hhsize * `base' / CPI_tanzania)
gen logcons_pa = ln(consumption / nadult * `base' / CPI_tanzania)

***** create migration variables *****

bysort pid (wave): gen latP = lat[_n-1]
bysort pid (wave): gen lonP = lon[_n-1]
geodist latP lonP lat lon, gen(distP)

bysort pid (wave): gen urbanDif = urban[_n] != urban[_n-1] if !inlist(., urban[_n], urban[_n -1])

gen distPS = distP if urbanDif
bysort pid (wave): gen surb = urban[1]
bysort pid (wave): replace urban = urban[_n - 1] if distP == 0
bysort pid (wave): gen rlLast = urban[_n] == 1 if urban[_n-1] == 0
egen swDist = mean(distPS) if surb == 0 & rlLast & !mi(ea), by(ea)

egen rumig = max(rlLast), by(pid)
tab rumig

bysort pidlink (wave): gen rural_leaver = urban[_n+1] == 1 if _n != _N & urban[_n] == 0

bys pidlink (wave): gen start_urban = urban[1]

bysort pidlink: egen ever_urban = max(urban)
bysort pidlink: egen ever_rural = min(urban)
replace ever_rural = 1 - ever_rural

* move reason with fewer categories
recode movereason (4 = 3) (5 = 7)




***** labels for use in regressions *****
label var loghours "Log hours"
label var loghourssq "Log hours squared"
label var logearnings "Log Earnings"

* Movereasons labels
gen miReas = 1-mi(movereason)
bysort pid (miReas wave ): replace movereason = movereason[_N]
label define move_reason 1 "work" 2 "education" 3 "family" 4 "other"
recode movereason (7 = 4) (6 = 1), gen(mreason)
label var mreason move_reason

bysort pid (wave): gen rgn = region[1]
gen flag = rgn == 7 | inlist(rgn,51, 52, 53, 54, 55) //dar el salaam and Zanzibar

bys pid (wave): gen startUrban = urban[1]

do "${bldcode}/Support/cross_country_vars.do"

gen ctry_str = "Tanzania"

save "${TZAbuild}/tza_panel.dta", replace
save "${xcbuild}/Tanzania.dta", replace




