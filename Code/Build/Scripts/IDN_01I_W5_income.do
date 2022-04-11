/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Build Indonesia Wave 5 Income		
AUTHORS: 		Sam Marshall, Min Byung Chae
MODIFIED:		6/13/2019 MBC
DESC: 			Clean Indonesia wave 5 income data
ORG:				
INPUTS: 		b3a_tk1.dta b3a_tk2.dta			
OUTPUTS: 		IFLS5_income.dta			
NOTE:			
******************************************************************/

* initiate globals if not done already
do "${bldcode}/Support/IDN_income_funs.do"

/****************************************************************
	SECTION 1: 2014 Employment
****************************************************************/

use "${IDNraw}/IFLS5/Household/b3a_tk1.dta", clear

gen employed = (tk01 == 1 | tk02 == 1 | tk03 == 1 | tk04 == 1)
	
keep pidlink employed hhid14

merge 1:1 pidlink using "${IDNraw}/IFLS5/Household/b3a_tk2.dta"

/****************************************************************
	SECTION 2: Hours
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
	SECTION 3: Earnings
****************************************************************/

*Primary job (j1) wage income
rename (tk25a1 tk25a2) (mearn_j1 aearn_j1)
annearn , out(primary) mon(mearn_j1) ann(aearn_j1) wks(weeks_p)

*Net profit if primary job is self employment (se1)
*MBC 5/29: We need to distinguish net profit from gross income 
rename (tk26a1 tk26a3) (mearn_se1 aearn_se1)
annearn , out(self1) mon(mearn_se1) ann(aearn_se1) wks(weeks_p)

*Secondary job (j2) wage income
rename (tk25b1 tk25b2) (mearn_j2 aearn_j2)
annearn , out(secondary) mon(mearn_j2) ann(aearn_j2) wks(weeks_sec)

*Net profit if secondary job is self employment (se2)
rename (tk26b1 tk26b3) (mearn_se2 aearn_se2)
annearn , out(self2) mon(mearn_se2) ann(aearn_se2) wks(weeks_p)	


/****************************************************************
	SECTION 5: Clean up
****************************************************************/

egen earn_self = rowtotal(earn_self1 earn_self2), m
egen earnings = rowtotal(earn_primary earn_secondary earn_self), m
egen earnings2 = rowtotal(earn_primary earn_secondary earn_self)

gen wage = earnings / hours

	* label variables
	label var earn_primary "earnings from wage labor, 1st job"
	label var earn_secondary "earnings from wage labor, 2nd job"	
	label var earn_self "earnings from self-employment, equal weight"
	label var earnings "total annual income"
	label var hours "Total annual hours worked"

	
gen year = 2014
gen proxy = 0 
replace proxy = 1 if tkp18ax != .

keep pidlink employed earn*  hours hours_flag weeks_p proxy year hhid14
drop earn_self1 earn_self2 
rename hhid14 hhid

gen recall = 0

save "${IDNbuild}/intermediate/IFLS5_income.dta", replace
