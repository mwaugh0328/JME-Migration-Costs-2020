/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			A_w1_chars.do			
AUTHORS: 		Min Byung Chae, Sam Marshall
						
VERSION:		2.0.1
CREATED:		02/25/2019
MODIFIED:		5/1/2019
DESC: 			Clean Ghana Data and build dataset
ORG:			SECTION 1: Demographics
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

use "${GHAraw}/Wave 1/s1d.dta", clear

gen female = s1d_1 == 2

rename s1d_4i age
gen agesq = (age)^2

*Region/Country of origin
ren s1d_14 birth_region




keep id1 id2 id3 id4 hhmid hhno female age agesq  birth_region  
 
save "${GHAbuild}/intermediate/wave1_demog.dta", replace

/****************************************************************
	SECTION 2: Education
****************************************************************/
use "${GHAraw}/Wave 1/s1fi.dta", clear

rename s1fi_hhmid hhmid

*Education
rename s1fi_3 schoolyears
rename s1fi_4 schtype

* there are issues with this and it needs to be adjusted
recode schoolyears 11=1 12=2 13=3 14=4 15=5 16=6 17=7 18=8 19=9 ///
	20=7 21=7 22=8 23=8 24=10 25=11 26=12 27=9 28=10 29=11 30=11 31=12 ///
	33=14 34=13 35=13 36=13 37=14 38=15 39=16 40=17 42=12 43=9 44=12 44=13 45=14 46=15 48=14
	
replace schoolyears = 14 if inlist(schoolyears, 47, 41, 32) & (schtype == 10)
replace schoolyears = 15 if inlist(schoolyears, 47, 41, 32) & (schtype == 11)
replace schoolyears = 12 if inlist(schoolyears, 47, 41, 32) & (schtype == 4)
replace schoolyears = 7 if (schoolyears == 47) & (schtype == 1)
replace schoolyears = 14 if (schoolyears == 47) & (schtype == 10)
replace schoolyears = 15 if (schoolyears == 47) & (schtype == 12)
replace schoolyears = 10 if (schoolyears == 32) & (schtype == 2)
replace schoolyears = 9 if (schoolyears == 32) & (schtype == 3)
replace schoolyears = 13 if (schoolyears == 32) & (schtype ==5)
replace schoolyears = 14 if (schoolyears == 32) & (schtype ==6)
replace schoolyears = 9 if (schoolyears == 32) & (schtype == 7)
replace schoolyears = 12 if (schoolyears == 32) & (schtype == 8)
replace schoolyears = 14 if (schoolyears == 32) & (schtype == 9)
replace schoolyears = 15 if (schoolyears == 32) & (schtype == 12)
replace schoolyears = 16 if (schoolyears == 32) & (schtype == 13)
replace schoolyears = 17 if (schoolyears == 32) & (schtype == 14)
replace schoolyears = 13 if (schoolyears == 41) & (schtype == 10)
replace schoolyears = 13 if (schoolyears == 41) & (schtype == 11)
replace schoolyears = 15 if (schoolyears == 41) & (schtype == 12)
replace schoolyears = 9 if schoolyears == 32

gen educ =  schoolyears
	replace educ = 0 if s1fi_2 == 2  // never attended school
	replace educ = . if educ > 18  // due to problems with coding above
gen educsq = (educ)^2

gen inschool = s1fi_6 == 1
label var inschool "currently in school"

drop if hhmid == .

keep id1 id2 id3 id4 hhmid hhno educ educsq inschool

save "${GHAbuild}/intermediate/wave1_edu.dta", replace

/****************************************************************
	SECTION 3: Medical Care
****************************************************************/
use "${GHAraw}/Wave 1/s6a.dta", clear

*Has [Name] ever registered or been covered with a health insurance scheme?
recode s6a_a1 (2 = 0), gen(insurance)

*Why is [Name] not registered with NHIS (National Health Insurance Scheme)? (primary reason)
* 3 = "cannot afford premium"
gen uninsured_cost = s6a_a3_1 == 3
label var uninsured_cost "Does not have insurance due to cost"

keep insurance uninsured_cost hhno hhmid

save "${GHAbuild}/intermediate/wave1_ins.dta", replace

/****************************************************************
	SECTION 4: Household Level variables
****************************************************************/

* household size
use "${GHAraw}/Wave 1/s10ai.dta", clear
gen adult = s1d_4i > 15
egen nadult = sum(adult), by(hhno)
keep hhno hhsize nadult
duplicates drop
drop if hhsize == .
save "${GHAbuild}/intermediate/wave1_hhsize.dta", replace

* prior migration experience
use "${GHAraw}/Wave 1/s1gii0.dta", clear
gen mig_exper = s1gii_13 == 1
label var mig_exper "1=household member ever lived away from this town for a year or more"
keep hhno mig_exper 
save "${GHAbuild}/intermediate/wave1_mig_exp.dta", replace



tempfile hh
save `hh', replace



/****************************************************************
	SECTION 5: Merging the cleaned datasets
****************************************************************/

use "${GHAraw}/Wave 1/key_hhld_info.dta", clear
	merge 1:1 hhno using "${GHAbuild}/intermediate/wave1_hhsize.dta", nogen
	merge 1:1 hhno using "${GHAbuild}/intermediate/wave1_mig_exp.dta", nogen

	
	merge 1:m hhno using "${GHAbuild}/intermediate/wave1_demog.dta", nogen
	merge 1:1 hhno hhmid using "${GHAbuild}/intermediate/wave1_edu.dta", nogen
	merge 1:1 hhno hhmid using "${GHAbuild}/intermediate/wave1_ins.dta", nogen

gen urban = urbrur == 1
drop urbrur


save "${GHAbuild}/intermediate/wave1_chars.dta", replace

* clean up
erase "${GHAbuild}/intermediate/wave1_hhsize.dta"
erase "${GHAbuild}/intermediate/wave1_mig_exp.dta"
erase "${GHAbuild}/intermediate/wave1_demog.dta"
erase "${GHAbuild}/intermediate/wave1_edu.dta"
erase "${GHAbuild}/intermediate/wave1_ins.dta"
