/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Build Indonesia Wave 1 Income		
AUTHORS: 		Sam Marshall, John Mori, Min Byung Chae, Corey Vernot
DESC: 			Clean Indonesia wave 1 income data
ORG:	
INPUTS: 		buk3tk1.dta buk3tk2.dta		
OUTPUTS: 		IFLS1_income.dta			
NOTE:			
******************************************************************/

* initiate globals if not done already
do "${bldcode}/Support/IDN_income_funs.do"

/****************************************************************
	SECTION 1: 1993 Employment
****************************************************************/

use "${IDNraw}/IFLS1/Household/buk3tk1.dta", clear

gen employed = (tk01 == 1 | tk02 == 1 | tk03 == 1 | tk04 == 1)
	
keep pidlink employed hhid93

merge 1:1 pidlink using "${IDNraw}/IFLS1/Household/buk3tk2.dta"

/****************************************************************
	SECTION 2: Hours
****************************************************************/

* lpw variables correspond to values for hours worked past week

* hours in primary job / business
rename (tk22a tk21a tk23a) (hours_p hours_lwp weeks_p)
annhours , out(p) hrs(hours_p) wks(weeks_p) lowcap(1)

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
rename (tk25r1_m tk25r1_y) (mearn_j1 aearn_j1)
annearn , out(primary) mon(mearn_j1) ann(aearn_j1) wks(weeks_p)

*Net profit/gross income if primary job is self employment (se1)
rename (tk26r1_m tk26r1_y) (mearn_se1 aearn_se1) 
annearn , out(self1) mon(mearn_se1) ann(aearn_se1) wks(weeks_p)

*Secondary job (j2) wage income
rename (t25br1_m t25br1_y) (mearn_j2 aearn_j2)
annearn , out(secondary) mon(mearn_j2) ann(aearn_j2) wks(weeks_sec)

*Net profit/gross income if secondary job is self employment (se2)
rename (t26br1_m t26br1_y) (mearn_se2 aearn_se2)
annearn , out(self2) mon(mearn_se2) ann(aearn_se2) wks(weeks_p)	



/****************************************************************
	SECTION 5: Clean up
****************************************************************/

egen earn_self = rowtotal(earn_self1 earn_self2), m
egen earnings = rowtotal(earn_primary earn_secondary earn_self), m
egen earnings2 = rowtotal(earn_primary earn_secondary earn_self)

gen earn_flag = tk26a1_m == 3 | t26b1_m == 3 | tk26a1_y == 3 | t26b1_y == 3
label var earn_flag "flag for gross income"

gen wage = earnings / hours

	* label variables
	label var earn_primary "earnings from wage labor, 1st job"
	label var earn_secondary "earnings from wage labor, 2nd job"	
	label var earn_self "earnings from self-employment, equal weight"
	label var earnings "total annual income"
	label var hours "Total annual hours worked"
	label var wage "Avg hourly wage"


gen year = 1993
gen proxy = 0

keep pidlink employed earn* wage hours hours_flag weeks_p year  hhid93
drop earn_self1 earn_self2

foreach var of varlist earn_primary-wage {
	replace `var' = 1000 * `var'
}

recode earn_flag (1000 = 1)
rename hhid93 hhid
gen recall = 0
save "${IDNbuild}/intermediate/IFLS1_income.dta", replace

