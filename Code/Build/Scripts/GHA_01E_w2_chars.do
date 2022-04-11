/*****************************************************************
PROJECT: 		Rural-Urban Migration 
				
TITLE:			A_w2_chars.do
			
AUTHOR: 		Min Byung Chae, Sam Marshall

DATE CREATED:	02/25/2019

LAST EDITED:	5/2/2019

DESCRIPTION: 	Clean Ghana Data and build dataset

ORGANIZATION:	SECTION 1: Demographics
				SECTION 2: Education
				SECTION 3: Medical Care
				SECTION 4: Household Level variables
				
INPUTS: 		s1d.dta s1fi.dta s6a.dta
				
OUTPUTS: 		gha_clean_new.dta
				
NOTE:			Intermediary outputs: wave1_demog.dta wave1_edu.dta
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Demographics
****************************************************************/

use "${GHAraw}/Wave 2/01b2_preroster", clear
replace hhmid = count if hhmid == .

drop if currentmember == 5

merge 1:1 FPrimary hhmid using "${GHAraw}/Wave 2/01b2_roster.dta", nogen

* wave 2 happened during 2014/2015
gen year = year(checkdate)

*Household Size
bysort FPrimary: egen hhsize = count(hhmid)
gen adult = ageyears > 15
egen nadult = sum(adult), by(FPrimary)

gen female = gender == 5

ren ageyears age
gen agesq = (age)^2

rename joinedwhy movereason  //look into this. are the movers in the roster recorded elsewhere?

keep FPrimary hhmid year female age agesq movereason hhsize nadult relationship maritalstatus

save "${GHAbuild}/intermediate/wave2_demog.dta", replace

/****************************************************************
	SECTION 2: Education
****************************************************************/
use "${GHAraw}/Wave 2/01fi_generaleducation.dta", clear


*Side-by-side comparison of education classification available in "${GHAbuild}/intermediate/output/Education Comparison Wave 1 and 2"
gen educ = highestgrade  
rename highestgrade schoolyears
rename highestqual schtype
recode educ 11=1 12=2 13=3 14=4 15=5 16=6 17=7 18=8 19=9 ///
	20=7 21=7 22=8 23=8 24=10 25=11 26=12 27=9 28=10 29=11 30=11 31=12 
replace educ = 14 if (schoolyears == 95) & (schtype == 10)
replace educ = 15 if (schoolyears == 95) & (schtype == 11)
replace educ = 12 if (schoolyears == 95) & (schtype == 4)
replace educ = 10 if (schoolyears == 95) & (schtype == 2)
replace educ = 9 if (schoolyears == 95) & (schtype == 3)
replace educ = 13 if (schoolyears == 95) & (schtype ==5)
replace educ = 14 if (schoolyears == 95) & (schtype ==6)
replace educ = 9 if (schoolyears == 95) & (schtype == 7)
replace educ = 12 if (schoolyears == 95) & (schtype == 8)
replace educ = 14 if (schoolyears == 95) & (schtype == 9)
replace educ = 15 if (schoolyears == 95) & (schtype == 12)
replace educ = 16 if (schoolyears == 95) & (schtype == 13)
replace educ = 17 if (schoolyears == 95) & (schtype == 14)
replace educ = 9 if schoolyears == 95

gen educsq = (educ)^2

keep FPrimary hhmid educ educsq

save "${GHAbuild}/intermediate/wave2_edu.dta", replace

/****************************************************************
	SECTION 2.3: Combine
****************************************************************/

use "${GHAbuild}/intermediate/wave2_demog.dta", clear
merge 1:1 FPrimary hhmid using "${GHAbuild}/intermediate/wave2_edu.dta", nogen
merge m:1 FPrimary using "${GHAraw}/Wave 2/comm_matching_nonPII", ///
	keepusing(urbrur_W2) gen(_merge2) keep(3)
save "${GHAbuild}/intermediate/wave2_chars.dta", replace

* clean up
erase "${GHAbuild}/intermediate/wave2_demog.dta"
erase "${GHAbuild}/intermediate/wave2_edu.dta"


/*
merge 1:1 FPrimary hhmid using "${GHAbuild}/intermediate/output/int/preroster", gen(b)
merge m:1 FPrimary using "${GHAraw}/Wave 2/Data/comm_matching_nonPII", gen(_merge2)
merge m:1 FPrimary using "${cons}/gha_cons", gen(wmc)

* drop communities that were only in wave 1
keep if _merge2 == 3
drop _merge2 a b commcode_W1 urbrur_W1 wmc urban
ren urbrur_W2 urban

tostring hhmid, gen(mem)

egen pid_wave2 = concat(FPrimary mem)
tostring pid_wave2, replace

ren wave wave_orig
gen wave = 2

*Loghours, Logearnings, and Logwages
egen annhours = rowtotal(annhours_1 annhours_2), m
generate loghours = ln(annhours)
generate loghourssq = (loghours)^2

gen earn = earn_1 + earn_2
gen logearn = ln(earn)

gen wage = earn/annhours
gen logwage = ln(wage)

drop if hhmid == .

merge 1:1 pid_wave2 using "${GHAbuild}/intermediate/output/splitoff_matches_new", generate(z)

replace pid_wave1 = pid_wave2 if pid_wave1 == ""

save "${GHAbuild}/intermediate/output/int/wave2", replace

/****************************************************************
	SECTION 3: Appending Wave 1 and Wave 2 using matched PID
****************************************************************/

append using "${GHAbuild}/intermediate/output/int/wave1"
sort pid_wave1 wave
drop mem _merge InstanceNumber count z

bysort pid_wave1: egen urban_min = min(urban)
bysort pid_wave1: egen urban_max = max(urban)
gen switcher = urban_min != urban_max

ren pid_wave1 pid

* keep only indiv who were win both waves
duplicates tag pid, gen(dup)
drop if dup != 1
drop dup

recode urban 2 = 0
recode urban 1 = 1
label define urb 0 "rural" 1 "urban"
label values urban urb

********* Rural-leaver variables (from Tanzania build file)
bysort pid (wave): gen rural_rural = urban[_n] == 0 & urban[_n+1] == 0
bysort pid (wave): gen rural_urban = urban[_n] == 0 & urban[_n+1] == 1
bysort pid (wave): gen urban_urban = urban[_n] == 1 & urban[_n+1] == 1
bysort pid (wave): gen urban_rural = urban[_n] == 1 & urban[_n+1] == 0

gen move = 1 if rural_rural == 1
	replace move = 2 if rural_urban == 1
	replace move = 3 if urban_urban == 1
	replace move = 4 if urban_rural == 1

label define type 1 "rural-rural" 2 "rural-urban" 3 "urban-urban" 4 "urban-rural"
label values move type

gen rural_leaver = 1 if move == 2
	replace rural_leaver = 0 if move == 1
	
*encode district_name, gen(dist) *** no district names available in wave 2
/*foreach var of varlist logearnings logconsumption dist dar zanzibar {
	bys pid (wave): gen `var'Next = `var'[_n+1]
	bys pid (wave): gen `var'Prev = `var'[_n-1]
	gen d`var' = `var'Next - `var' if rural_leaver == 1
	bys pid (wave): gen d`var'Prev = d`var'[_n-1]
}
*/
save "${GHAbuild}/intermediate/output/gha_clean", replace
*/
