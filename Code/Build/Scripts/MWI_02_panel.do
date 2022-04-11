/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Build Malawi Panel		
AUTHOR: 		Sam Marshall
CREATED:		5/23/2019
MODIFIED:		9/03/2019
DESC: 			combine all files for Malawi and build
ORG:			SECTION 1: Wave 1 		
				SECTION 2: Wave 2 
				SECTION 3: Wave 3 	
				SECTION 4: Panel
INPUTS: 					
OUTPUTS: 					
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Wave 1
****************************************************************/

use "${MWIbuild}/intermediate/wave1_chars.dta", clear
merge 1:1 PID using "${MWIbuild}/intermediate/wave1_income.dta", nogen
merge m:1 HHID using "${MWIbuild}/intermediate/wave1_consumption.dta", nogen

gen wave = 1

rename qx_type temp
encode temp, gen(qx_type)
drop temp

save "${MWIbuild}/mwi_wave1.dta", replace

/****************************************************************
	SECTION 2: Wave 2
****************************************************************/

use "${MWIbuild}/intermediate/wave2_chars.dta", clear
merge 1:1 PID using "${MWIbuild}/intermediate/wave2_income.dta", nogen
merge m:1 y2_hhid using "${MWIbuild}/intermediate/wave2_consumption.dta", nogen

gen wave = 2

rename ward ward_w2

save "${MWIbuild}/mwi_wave2.dta", replace

/****************************************************************
	SECTION 3: Wave 3
****************************************************************/

use "${MWIbuild}/intermediate/wave3_chars.dta", clear
merge 1:1 PID using "${MWIbuild}/intermediate/wave3_income.dta", nogen
merge m:1 case_id using "${MWIbuild}/intermediate/wave3_consumption.dta", gen(_mc3) //Have to merge by PID to link across filetypes

gen wave = 3

save "${MWIbuild}/mwi_wave3.dta", replace

/****************************************************************
	SECTION 4: Panel
****************************************************************/

use "${MWIbuild}/mwi_wave1.dta", clear
append using "${MWIbuild}/mwi_wave2.dta"
rename HHID HHID_IHS3
append using "${MWIbuild}/mwi_wave3.dta"
gen pid = PID //harmonizing across datasets
compress

tostring(HHID_IHS3), gen(y1_hhid)
gen hhid = y1_hhid if wave == 1
replace hhid = y2_hhid if  wave == 2
replace hhid = y3_hhid if  wave == 3
bysort pid (wave): gen hhid_lag = hhid[_n -1]
*gen hhswitch = hhid != hhid_lag if !mi(hhid_lag)
*tab hhswitch if wave == 3

recode wave (1 = 2010) (2 = 2013) (3 = 2016), gen(year)
merge m:1 year using "${pxbuild}/CPI_GDPPC.dta", keep(match) nogen
drop *south_africa *uganda *tanzania *indonesia *china

* select sample
keep if age > 15
encode pid, gen(pidN)
drop pid
ren pidN pid
egen nadult = count(pid), by(hhid wave)

* make real earnings variables
sum CPI_malawi if year == 2016
local base = r(mean)
gen logearnings_real = ln(earnings * `base' / CPI_malawi)
gen logcons_pa = ln(consumption/nadult * `base' / CPI_malawi)
gen logcons = ln(consumption)
gen logearnings = ln(earnings)
gen agesq = age^2
gen loghours =ln(hours)
gen loghours2 = loghours^2
gen educ2 = educ^2

* employed in this context is positive earnings
gen employed = earnings > 0 & ~mi(earnings)

* move reason with fewer categories
recode movereason (1 2 5 6 = 4) (7 8 10 11 = 9) (12 = 13)

bysort pid (wave): gen rural_leaver = urban[_n] == 0 & urban[_n+1] == 1 if _n != _N

*indicator for urban rural at first interview
bysort PID: egen ever_urban = max(urban)
bysort PID: egen ever_rural = min(urban)
replace ever_rural = 1 - ever_rural

recode baseline_rural (2 = 0), gen(baseline_urban)

replace panelweight = panelweight_2016 if year == 2016
drop panel*13 panel*16

* labels for use in regressions
label var loghours "Log hours"
label var loghours2 "Log hours squared"
lab var logearnings_real "Log earnings, real"
label var logcons "Log consumption pca"

encode ea_id, gen(ea)

* load countries code
gen miReas = 1-mi(movereason)
bysort pid (miReas wave ): replace movereason = movereason[_N]
label define move_reason 1 "work" 2 "education" 3 "family" 4 "other"
recode movereason (9= 1) (4 = 3) (3 = 2) (13 = 4), gen(mreason)
label var mreason move_reason

bysort pid (wave): gen rgn = district[1]
gen logconsumption = asinh(consumption_ae)

gen loghourssq = loghours2
bys pid (wave): gen startUrban = urban[1]



do "${bldcode}/Support/cross_country_vars.do"

gen ctry_str = "Malawi"

* bysort pid (wave): replace ea = ea[1]  // SMM commented and replaced on 2/3/2022
replace ea = . if wave == 3  // SMM added on 2/3/2022, to count only eas in first two waves


save "${MWIbuild}/mwi_panel.dta", replace
save "${xcbuild}/Malawi.dta", replace

