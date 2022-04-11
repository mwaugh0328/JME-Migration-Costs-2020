/*****************************************************************
PROJECT: 		Rural-Urban Migration 				
TITLE:			Build South Africa Income		
AUTHORS: 		Sam Marshall, Liana Wang, Sebastian Quaade			
CREATED:		7/8/2019
DESC: 			Create income info for each wave of South Africa
ORG:			SECTION 1: Earnings
				SECTION 2: Hours
				SECTION 3: Clean Up
INPUTS: 		indderived_W`i'.dta	Adult_W`i'.dta
OUTPUTS: 		wave`i'_income.dta			
NOTE:			
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Earnings
****************************************************************/

label define lfs -1 "Out of the labor force" 0 "Unemployed" 1 "Employed"

***** Wave 1 *****
use "${ZAFraw}/Wave 1/indderived_W1.dta", clear
	rename w1_* *
	drop if quest_typ == 2 // child interviews
	gen lfs = empl_stat_inclprox  -1
	label values lfs lfs
	
	egen earnings = rowtotal(fwag-help), m
	egen nonlabor_inc = rowtotal(spen-remt), m
	
	keep pid earnings nonlabor_inc lfs numzscore
	save "${ZAFbuild}/intermediate/wave1_income.dta", replace
	
***** Wave 2 *****
use "${ZAFraw}/Wave 2/indderived_W2.dta", clear
	rename w2_* *
	drop if quest_typ == 2 // child interviews
	gen lfs = empl_stat_inclprox  -1
	replace lfs = . if lfs == -9

	egen earnings = rowtotal(fwag-opro), m
	egen nonlabor_inc = rowtotal(spen-remt), m
	
	keep pid earnings nonlabor_inc lfs stayer pweight 
	save "${ZAFbuild}/intermediate/wave2_income.dta", replace

***** Wave 3 *****
use "${ZAFraw}/Wave 3/indderived_W3.dta", clear
	rename w3_* *
	drop if quest_typ == 2 // child interviews
	recode empl_stat (-8 = .) (0 = -1) (1 2 = 0) (3 = 1), gen(lfs)
	
	egen earnings = rowtotal(fwag-help), m
	egen nonlabor_inc = rowtotal(spen-remt), m

	keep pid earnings nonlabor_inc lfs stayer pweight 
	save "${ZAFbuild}/intermediate/wave3_income.dta", replace
	
***** Wave 4 *****
use "${ZAFraw}/Wave 4/indderived_W4.dta", clear
	rename w4_* *
	drop if quest_typ == 2 // child interviews
	recode empl_stat (-8 = .) (0 = -1) (1 2 = 0) (3 = 1), gen(lfs)
	
	egen earnings = rowtotal(fwag-help), m
	egen nonlabor_inc = rowtotal(spen-remt), m
	
	rename (tot_ass_i tot_deb_i net_worth_i) (assets debt networth)
	
	keep pid earnings nonlabor_inc lfs stayer pweight assets debt networth
	save "${ZAFbuild}/intermediate/wave4_income.dta", replace
	
***** Wave 5 *****
use "${ZAFraw}/Wave 5/indderived_W5.dta", clear
	rename w5_* *
	drop if quest_typ == 2 // child interviews
	drop *_extu
	recode empl_stat (-8 = .) (0 = -1) (1 2 = 0) (3 = 1), gen(lfs)
	
	egen earnings = rowtotal(fwag-help), m
	egen nonlabor_inc = rowtotal(spen-remt), m
	
	rename (tot_ass_i tot_deb_i net_worth_i) (assets debt networth)
	
	keep pid earnings nonlabor_inc lfs stayer pweight assets debt networth flscore
	save "${ZAFbuild}/intermediate/wave5_income.dta", replace
	
	

/****************************************************************
	SECTION 2: Hours
****************************************************************/

forvalues i = 1/5 {
	use "${ZAFraw}/Wave `i'/Adult_W`i'.dta", clear
	rename w`i'_a_* *
	keep if outcome == 1

	rename emsmn months_self
	* hours worked
	rename (em1hrs em2hrs emshrs emphrs emhhrs emchrs) ///
		(hours_p hours_sec hours_self hours_ag hours_oth hours_cas)
	
	foreach v of varlist hours_* months_self {
		replace `v' = . if `v' < 0
	}

	* scale self-employment hours because we know how many months worked
	replace hours_self = hours_self * (months_self / 12) if months_self != .

	egen hours = rowtotal(hours_*), m

	


	keep pid hours 
	save "${ZAFbuild}/intermediate/wave`i'_hours.dta", replace
}

/****************************************************************
	SECTION 3: Clean Up
****************************************************************/
forvalues i = 1/5 {
	use "${ZAFbuild}/intermediate/wave`i'_income.dta"
	merge 1:1 pid using "${ZAFbuild}/intermediate/wave`i'_hours.dta", nogen
	save "${ZAFbuild}/intermediate/wave`i'_income.dta", replace
	erase "${ZAFbuild}/intermediate/wave`i'_hours.dta"
}



