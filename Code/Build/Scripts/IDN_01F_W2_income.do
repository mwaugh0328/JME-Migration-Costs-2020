/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Build Indonesia Wave 2 Income		
AUTHORS: 		Sam Marshall, Min Byung Chae
MODIFIED:		6/12/2019 MBC
DESC: 			Clean Indonesia wave 2 income data
ORG:	
INPUTS: 		b3a_tk1.dta b3a_tk2.dta
OUTPUTS: 		IFLS2_income.dta			
NOTE:			
******************************************************************/

* initiate globals if not done already
do "${bldcode}/Support/IDN_income_funs.do"

/****************************************************************
	SECTION 1: Own Responses
	SECTION 1.1: 1997 Employment
****************************************************************/

use "${IDNraw}/IFLS2/Household/b3a_tk1.dta", clear

gen employed = (tk01 == 1 | tk02 == 1 | tk03 == 1 | tk04 == 1)
	
keep pidlink employed hhid

merge 1:1 pidlink using "${IDNraw}/IFLS2/Household/b3a_tk2.dta"

/****************************************************************
	SECTION 1.2: Hours
****************************************************************/

* lpw variables correspond to values for hours worked past week

* hours in primary job / business
rename (tk22a tk21a tk23a) (hours_p hours_lwp weeks_p)
annhours , out(p) hrs(hours_p) wks(weeks_p)

* hours secondary job
rename (tk22b tk21b tk23b) (hours_sec hours_lwsec weeks_sec)
annhours , out(sec) hrs(hours_sec) wks(weeks_sec)
	
* annual hours sum
egen hours = rowtotal(ahrs_p ahrs_sec), missing
gen hours_flag = hours > 365 * 24 & ~mi(hours)
label var hours_flag "flag for hours too high"
replace hours = 365 * 24 if hours > 365 * 24 & ~mi(hours)

/****************************************************************
	SECTION 1.3: Earnings
****************************************************************/

*Primary job (j1) wage income
rename (tk25am tk25ay) (mearn_j1 aearn_j1)
annearn , out(primary) mon(mearn_j1) ann(aearn_j1) wks(weeks_p)

*Net profit if primary job is self employment (se1)
*MBC 5/29: We need to distinguish net profit from gross income 
rename (tk26amn tk26ayn) (mearn_se1 aearn_se1)
annearn , out(self1) mon(mearn_se1) ann(aearn_se1) wks(weeks_p)

*Gross income if primary job is self employment (se3)
rename (tk26amg tk26ayg) (mearn_se3 aearn_se3)
annearn , out(self3) mon(mearn_se3) ann(aearn_se3) wks(weeks_p)

*Secondary job (j2) wage income
rename (tk25bm tk25by) (mearn_j2 aearn_j2)
annearn , out(secondary) mon(mearn_j2) ann(aearn_j2) wks(weeks_sec)

*Net profit if secondary job is self employment (se2)
rename (tk26bmn tk26byn) (mearn_se2 aearn_se2)
annearn , out(self2) mon(mearn_se2) ann(aearn_se2) wks(weeks_p)	

*Gross income if secondary job is self employment (se4)
rename (tk26bmg tk26byg) (mearn_se4 aearn_se4)
annearn , out(self4) mon(mearn_se4) ann(aearn_se4) wks(weeks_p)	


/****************************************************************
	SECTION 1.5: Clean up
****************************************************************/

egen earn_self = rowtotal(earn_self1 earn_self2 earn_self3 earn_self4), m
egen earnings = rowtotal(earn_primary earn_secondary earn_self), m
egen earnings2 = rowtotal(earn_primary earn_secondary earn_self)

gen earn_flag = tk26amgx == 1 | tk26bmgx == 1 | tk26aygx == 1 | tk26bygx == 1
label var earn_flag "flag for gross income"

gen wage = earnings / hours

gen year = 1997
gen proxy = 0

keep pidlink employed earn* hours hours_flag weeks_p proxy year hhid97
drop earn_self1 earn_self2 earn_self3 earn_self4

save "${IDNbuild}/intermediate/IFLS2_income_A.dta", replace

/****************************************************************
	SECTION 2: Proxy Responses
	SECTION 2.1: 1997 Employment
****************************************************************/

use "${IDNraw}/IFLS2/Household/b3p_tk1.dta", clear

gen employed = 1 if tk01 == 1 | tk02 == 1 | tk03 == 1 | tk04 == 1
	replace employed = 0 if employed == .
	
keep pidlink employed hhid

merge 1:1 pidlink using "${IDNraw}/IFLS2/Household/b3p_tk2.dta"

/****************************************************************
	SECTION 2.2: Hours
****************************************************************/

* lpw variables correspond to values for hours worked past week

* hours in primary job / business
rename (tk22a tk21a tk23a) (hours_p hours_lwp weeks_p)
annhours , out(p) hrs(hours_p) wks(weeks_p)

* hours secondary job
rename (tk22b tk21b tk23b) (hours_sec hours_lwsec weeks_sec)
annhours , out(sec) hrs(hours_sec) wks(weeks_sec)
	
* annual hours sum
egen hours = rowtotal(ahrs_p ahrs_sec), missing
gen hours_flag = hours > 365 * 24 & ~mi(hours)
label var hours_flag "flag for hours too high"
replace hours = 365 * 24 if hours > 365 * 24 & ~mi(hours)

/****************************************************************
	SECTION 2.3: Earnings
****************************************************************/

*Primary job (j1) wage income
rename (tk25am tk25ay) (mearn_j1 aearn_j1)
annearn , out(primary) mon(mearn_j1) ann(aearn_j1) wks(weeks_p)

*Net profit if primary job is self employment (se1)
*MBC 5/29: We need to distinguish net profit from gross income 
rename (tk26amn tk26ayn) (mearn_se1 aearn_se1)
annearn , out(self1) mon(mearn_se1) ann(aearn_se1) wks(weeks_p)

*Gross income if primary job is self employment (se3)
rename (tk26amg tk26ayg) (mearn_se3 aearn_se3)
annearn , out(self3) mon(mearn_se3) ann(aearn_se3) wks(weeks_p)

*Secondary job (j2) wage income
rename (tk25bm tk25by) (mearn_j2 aearn_j2)
annearn , out(secondary) mon(mearn_j2) ann(aearn_j2) wks(weeks_sec)

*Net profit if secondary job is self employment (se2)
rename (tk26bmn tk26byn) (mearn_se2 aearn_se2)
annearn , out(self2) mon(mearn_se2) ann(aearn_se2) wks(weeks_p)	

*Gross income if secondary job is self employment (se4)
rename (tk26bmg tk26byg) (mearn_se4 aearn_se4)
annearn , out(self4) mon(mearn_se4) ann(aearn_se4) wks(weeks_p)	

/****************************************************************
	SECTION 2.5: Clean up
****************************************************************/

egen earn_self = rowtotal(earn_self1 earn_self2 earn_self3 earn_self4), m
egen earnings = rowtotal(earn_primary earn_secondary earn_self), m
egen earnings2 = rowtotal(earn_primary earn_secondary earn_self)

gen earn_flag = tk26amgx == 1 | tk26bmgx == 1 | tk26aygx == 1 | tk26bygx == 1
label var earn_flag "flag for gross income"

gen wage = earnings / hours

gen year = 1997
gen proxy = 1

keep pidlink employed earn* hours hours_flag weeks_p proxy year  hhid97
drop earn_self1 earn_self2 earn_self3 earn_self4

save "${IDNbuild}/intermediate/IFLS2_income_B.dta", replace

/****************************************************************
	SECTION 3: Append and clean up
****************************************************************/
append using "${IDNbuild}/intermediate/IFLS2_income_A.dta"
rename hhid97 hhid

duplicates tag pidlink, gen(dup)
drop if dup > 0 & proxy == 1
drop dup

* label variables
label var earn_primary "earnings from wage labor, 1st job"
label var earn_secondary "earnings from wage labor, 2nd job"	
label var earn_self "earnings from self-employment, equal weight"
label var earnings "total annual income"
label var hours "Total annual hours worked"


gen recall = 0
	
save "${IDNbuild}/intermediate/IFLS2_income.dta", replace

erase "${IDNbuild}/intermediate/IFLS2_income_A.dta"
erase "${IDNbuild}/intermediate/IFLS2_income_B.dta"
