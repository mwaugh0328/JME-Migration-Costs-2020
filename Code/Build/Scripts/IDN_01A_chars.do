/*****************************************************************
PROJECT: 		Rural-Urban Migration				
TITLE:			Build Indonesia Demographics and Weights		
AUTHOR: 		Sam Marshall, John Mori, Min Byung Chae
CREATED:		2/22/2019
MODIFIED:		10/6/2019
DESC: 			Create education and other main demographic variables
ORG:			SECTION 1: Traker file
				SECTION 2: IFLS 1
				SECTION 3: IFLS 2
				SECTION 4: IFLS 3
				SECTION 5: IFLS 4
				SECTION 6: IFLS 5	
				SECTION 7: Weights
INPUTS: 		ptrack.dta	
				IFLS1: bukkar2.dta
				IFLS2 - IFLS5: bk_ar1.dta			
OUTPUTS: 		IFLS*_demog.dta	IFLS*_weights.dta				
NOTE:			https://www.scholaro.com/pro/countries/indonesia/education-system	
				Primary school is 6 years; middle school is 3, hs is 3, need to find definitive source for all types of education
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Traker file
****************************************************************/

use "${IDNraw}/IFLS5/Household/ptrack.dta", clear

gen female = sex == 3

keep pidlink female age* pwt93 pwt97l pwt97x pwt00*a pwt07*a pwt14la pwt14xa

duplicates drop

save "${IDNbuild}/intermediate/traker.dta", replace

/****************************************************************
	SECTION 2: IFLS 1
****************************************************************/

use "${IDNraw}/IFLS1/Household/bukkar2.dta", clear

* highest level of school plus number of years completed there
recode ar16 (1 2 = 0) (3 4 = 5) (5 6 = 8) (7 8 9 = 12) (11 96/99 = .), gen(base)

recode ar17 (96 = 0) (98 99 = .), gen(add)
	replace add = 5 if add > 5 & ~mi(add) & base == 0
	replace add = 3 if add > 5 & ~mi(add) & base == 5
	replace add = 4 if add > 5 & ~mi(add) & base == 8
	replace add = 6 if add > 5 & ~mi(add) & base == 12
	
egen educ = rowtotal(base add), m


merge 1:1 pidlink using "${IDNbuild}/intermediate/traker.dta", keep(match master) nogen

merge 1:1 pidlink using "${IDNraw}/IFLS1/Household/buk3dl1.dta", keep(match master) nogen


rename age_93 age
gen xweight = pwt93
rename pwt93 weight

merge m:1 hhid93 using "${IDNraw}/IFLS1/Household/bukksc1.dta", keep(match master) nogen
recode sc05 (2 = 0), gen(urban)
ren sc07 ea

keep pidlink educ  hhid93 age urban female *weight  ea

gen wave = 1993

save "${IDNbuild}/intermediate/IFLS1_demog.dta", replace

/****************************************************************
	SECTION 3: IFLS 2
****************************************************************/

use "${IDNraw}/IFLS2/Household/bk_ar1.dta", clear

keep if inlist(ar01a, 1, 5)  // in hhold

recode ar16 (1 2 11 17 70 = 0) (90 = 1) (3 4 12 = 5) (5 6 = 8) ///
	(7 8 9 13 14 = 12) (10 96/99 = .), gen(base)

recode ar17 (96 = 0) (98 99 = .), gen(add)
	replace add = 5 if add > 5 & ~mi(add) & base == 0
	replace add = 3 if add > 5 & ~mi(add) & base == 5
	replace add = 4 if add > 5 & ~mi(add) & base == 8
	replace add = 6 if add > 5 & ~mi(add) & base == 12
	
egen educ = rowtotal(base add), m

merge 1:1 pidlink using "${IDNbuild}/intermediate/traker.dta", keep(match master)  nogen

merge 1:1 pidlink using "${IDNraw}/IFLS2/Household/b3a_dl1.dta", keep(match master) nogen

rename age_97 age
rename (pwt97l pwt97x) (weight xweight)

merge m:1 hhid97 using "${IDNraw}/IFLS2/Household/bk_sc.dta", keep(match master) nogen

recode sc05 (2 = 0), gen(urban)

keep pidlink educ hhid97 age urban female *weight

gen wave = 1997

save "${IDNbuild}/intermediate/IFLS2_demog.dta", replace

/****************************************************************
	SECTION 4: IFLS3
****************************************************************/

use "${IDNraw}/IFLS3/Household/bk_ar1.dta", clear

keep if inlist(ar01a, 1, 5)  // in hhold

recode ar16 (1 2 11 17 70 72 = 0) (90 = 1) (3 4 12 73 = 5) (5 6 74 = 8) ///
	(9 13 14 60 61 62 63 = 12) (10 96/99 = .), gen(base)

recode ar17 (96 = 0) (98 99 = .), gen(add)
	replace add = 5 if add > 5 & ~mi(add) & base == 0
	replace add = 3 if add > 5 & ~mi(add) & base == 5
	replace add = 4 if add > 5 & ~mi(add) & base == 8
	replace add = 6 if add > 5 & ~mi(add) & base == 12
	
egen educ = rowtotal(base add), m

rename (ar15 ar18d) (religion status)

gen married = ar13 == 2
	replace married = . if ar13 > 5

duplicates drop pidlink educ religion married, force

merge 1:1 pidlink using "${IDNbuild}/intermediate/traker.dta", keep(match master)  nogen

merge 1:1 pidlink using "${IDNraw}/IFLS3/Household/b3a_dl1.dta", keep(match master) nogen




rename age_00 age
rename (pwt00la pwt00xa) (weight xweight)

merge m:1 hhid00 using "${IDNraw}/IFLS3/Household/bk_sc.dta", keep(match master) nogen

recode sc05 (2 = 0), gen(urban)

keep pidlink educ  hhid00 age urban female *weight  //N=43,649

gen wave = 2000

save "${IDNbuild}/intermediate/IFLS3_demog.dta", replace

/****************************************************************
	SECTION 5: IFLS4
****************************************************************/

use "${IDNraw}/IFLS4/Household/bk_ar1.dta", clear

keep if inlist(ar01a, 1, 2, 5, 11)  // in hhold

* according to the codebook kindergarten is actually 98 in this wave
recode ar16 (1 2 11 17 70 72 = 0) (98 = 1) (3 4 12 73 = 5) (5 6 74 15 90 = 8) ///
	(9 13 14 60 61 62 63 = 12) (95 99 = .), gen(base)

recode ar17 (96 = 0) (98 99 = .), gen(add)
	replace add = 5 if add > 5 & ~mi(add) & base == 0
	replace add = 3 if add > 5 & ~mi(add) & base == 5
	replace add = 4 if add > 5 & ~mi(add) & base == 8
	replace add = 6 if add > 5 & ~mi(add) & base == 12
	
egen educ = rowtotal(base add), m

rename (ar15 ar18d) (religion status)

gen married = ar13 == 2
	replace married = . if ar13 > 5

duplicates drop pidlink educ religion married, force

duplicates tag pidlink, gen(dup)

drop if dup == 1 & mi(status)

merge 1:1 pidlink using "${IDNbuild}/intermediate/traker.dta", keep(match master)  nogen

merge 1:1 pidlink using "${IDNraw}/IFLS4/Household/b3a_dl1.dta", keep(match master) nogen



rename age_07 age
rename (pwt07la pwt07xa) (weight xweight)

merge m:1 hhid07 using "${IDNraw}/IFLS4/Household/bk_sc.dta", keep(match master) nogen

recode sc05 (2 = 0), gen(urban)

keep pidlink educ religion  married  status hhid07 age urban female *weight   //N= 50,577 

gen wave = 2007

save "${IDNbuild}/intermediate/IFLS4_demog.dta", replace

/****************************************************************
	SECTION 6: IFLS5
****************************************************************/

use "${IDNraw}/IFLS5/Household/bk_ar1.dta", clear

keep if inlist(ar01a, 1, 2, 5, 11)  // in hhold

recode ar16 (1 2 11 17 70 72 = 0) (90 = 1) (3 4 12 73 = 5) (5 6 74 15 90 = 8) ///
	(9 13 14 60 61 62 63 = 12) (95/99 = .), gen(base)

recode ar17 (96 = 0) (98 99 = .), gen(add)
	replace add = 5 if add > 5 & ~mi(add) & base == 0
	replace add = 3 if add > 5 & ~mi(add) & base == 5
	replace add = 4 if add > 5 & ~mi(add) & base == 8
	replace add = 6 if add > 5 & ~mi(add) & base == 12
	
egen educ = rowtotal(base add), m

rename (ar15 ar18d) (religion status)

gen married = ar13 == 2
	replace married = . if ar13 > 5

duplicates drop pidlink educ religion married, force

duplicates tag pidlink, gen(dup)

drop if dup == 1 & mi(status)

duplicates tag pidlink, gen(dup2)
drop if dup2 > 0

merge 1:1 pidlink using "${IDNbuild}/intermediate/traker.dta", keep(match master)  nogen

merge 1:1 pidlink using "${IDNraw}/IFLS5/Household/b3a_dl1.dta", keep(match master) nogen



rename age_14 age
rename (pwt14la pwt14xa) (weight xweight)

merge m:1 hhid14 using "${IDNraw}/IFLS5/Household/bk_sc1.dta", keep(match master) nogen

recode sc05 (2 = 0), gen(urban)

keep pidlink educ religion  married status hhid14 age urban female *weight  

gen wave = 2014

save "${IDNbuild}/intermediate/IFLS5_demog.dta", replace


/****************************************************************
	SECTION 7: Weights
****************************************************************/
use "${IDNraw}/IFLS1/Household/indivwt.dta", clear
keep pidlink respwt
ren respwt weight
save "${IDNbuild}/intermediate/IFLS1_weights", replace

use "${IDNraw}/IFLS2/Household/ptrack.dta", clear
keep pidlink pwt97l
ren pwt97l weight
save "${IDNbuild}/intermediate/IFLS2_weights", replace

use "${IDNraw}/IFLS3/Household/ptrack.dta", clear
keep pidlink pwt00la
ren pwt00la weight
save "${IDNbuild}/intermediate/IFLS3_weights", replace

use "${IDNraw}/IFLS4/Household/ptrack.dta", clear
keep pidlink pwt07la
ren pwt07la weight
save "${IDNbuild}/intermediate/IFLS4_weights", replace

use "${IDNraw}/IFLS5/Household/ptrack.dta", clear
keep pidlink pwt14la
ren pwt14la weight
duplicates drop pidlink, force
save "${IDNbuild}/intermediate/IFLS5_weights", replace

