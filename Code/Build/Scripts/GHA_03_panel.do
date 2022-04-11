/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Ghana Build Panel.do		
AUTHORS: 		Sam Marshall, Min Byung Chae
VERSION:		1.0.1
CREATED:		5/1/2019
MODIFIED:		7/15/2019
DESC: 			combine all files for Ghana and build
ORG:			SECTION 1: Wave 1	
				SECTION 2: Wave 2
				SECTION 3: Panel
INPUTS: 				
OUTPUTS: 		gha_wave1.dta gha_wave2.dta	gha_panel.dta	 
NOTE:			
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Wave 1
****************************************************************/

use "${GHAbuild}/intermediate/wave1_chars.dta", clear
merge 1:1 hhno hhmid using "${GHAbuild}/intermediate/wave1_income.dta", nogen
merge m:1 hhno using "${GHAbuild}/intermediate/wave1_consumption.dta", nogen

gen pidlink = strofreal(hhno, "%12.0g") + string(hhmid)

merge 1:1 pidlink using "${GHAbuild}/intermediate/pidlink.dta", keep(3) nogen

gen wave = 1

save "${GHAbuild}/gha_wave1.dta", replace


/****************************************************************
	SECTION 2: Wave 2
****************************************************************/

use "${GHAbuild}/intermediate/wave2_chars.dta", clear
merge 1:1 FPrimary hhmid using "${GHAbuild}/intermediate/wave2_income.dta", nogen
merge m:1 FPrimary using "${GHAbuild}/intermediate/wave2_consumption.dta", nogen
gen pid_w2 = FPrimary + string(hhmid)

merge 1:1 pid_w2 using "${GHAbuild}/intermediate/pidlink.dta", keep(1 3)


gen wave = 2

gen migrant = pid_w2 != pidlink
label var migrant "individual migrated between wave 1-2"

save "${GHAbuild}/gha_wave2.dta", replace

/****************************************************************
	SECTION 3: Panel
****************************************************************/

use "${GHAbuild}/gha_wave1.dta", clear
append using "${GHAbuild}/gha_wave2.dta"
gen pid = pidlink //harmonizing across datasets
egen hhid = group(id1 id2 id3 id4)

drop if age < 16


duplicates tag pidlink, gen(N)
egen nwave = count(wave), by(pidlink)
bysort pidlink (wave): gen inw1 = wave[1] ==1
keep if nwave > 1 & !mi(urban)



***************		Wave 1 Community
bysort pidlink (wave): gen commcode_W1 = id3[1]
bysort pidlink (wave): replace commcode_W2 = commcode_W2[2]


preserve
use "${GHAraw}/Wave 2/comm_matching_nonPII.dta", clear
rename commcode_W1 cc1w1
merge m:1 commcode_W2 using "${GHAraw}/Community Waves 1-2 Key", gen(_mcom)
rename commcode_W1 cc1w2
recode cc1w2 (. = 99999) if _mcom == 1
compare cc1w1 cc1w2
gen moved = cc1w1 != cc1w2 | inlist(., cc1w1, cc1w2)
gen ccsame = cc1w1 == cc1w2 if !mi(cc1w2) & !mi(cc1w1)
drop wave
gen wave = 2
tempfile moved
save `moved'
restore 

merge m:1 FPrimary using `moved', gen(_mMov) keep(1 3)
replace moved = 1 if _mMov == 1
bysort pid (wave): replace moved = moved[2]
bysort pid (wave): replace ccsame = ccsame[2]

bysort pidlink (wave): replace urban = urban[1] if moved == 0
bysort pidlink (wave): gen urbandif = urban[1] != urban[2]

bysort pidlink (wave): gen switcher2 = urban[1] != urban[2]
tab switcher2

gen logcons = ln(consumption) 

bys pidlink (wave): gen startUrban = urban[1]

gen logearnings = ln(earnings)
gen consumption_pa = consumption / nadult 
gen logcons_pa = ln(consumption_pa) 
gen loghours =ln(hours)
gen loghours2 = loghours^2
gen educ2 = educ^2

***** create migration variables *****
bysort pid (wave): gen rural_leaver = urban[_n] == 0 & urban[_n+1] == 1 if _n != _N

bysort pid: egen ever_urban = max(urban)
bysort pid: egen ever_rural = min(urban)
replace ever_rural = 1 - ever_rural

* labels for use in regressions
label var loghours "Log hours"
label var loghours2 "Log hours squared"
label var logearnings "Log Earnings"

gen ea = id3
bysort pid (wave): replace ea = ea[1]

* load countries code
encode pid, gen(pidN)
drop pid
ren pidN pid
bysort pid (wave): gen rgn = id1[1]
egen gr = group(id1 id2 id3)
gen loghourssq = asinh(hours^2)

do "${bldcode}/Support/cross_country_vars.do"

gen ctry_str = "Ghana"
drop year
recode wave (1 = 2010) (2 = 2013), gen(year)
*replace year = 2009 if wave == 1 //CV edit 1/25/2022

save "${GHAbuild}/gha_panel.dta", replace
save "${xcbuild}/Ghana.dta", replace



