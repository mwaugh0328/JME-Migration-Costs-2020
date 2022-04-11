/*****************************************************************
PROJECT: 		Rural-Urban Migration 
				
TITLE:			Malawi Build consumption.do
			
AUTHORS: 		Sam Marshall, Hannah Moreno, John Mori, Sebastian Quaade

DATE CREATED:	05/14/2019

LAST EDITED:	5/14/2019

DESCRIPTION: 	Clean Malawi consumption data

ORGANIZATION:	SECTION 1: Demographics
				SECTION 2: Education
				SECTION 3: Medical Care
				SECTION 4: Household Level variables
				
INPUTS: 		Round 1 (2010) Consumption Aggregate.dta
				Round 2 (2013) Consumption Aggregate.dta
				IHS4 Consumption Aggregate.dta
				
OUTPUTS: 		wave1_consumption.dta wave2_consumption.dta wave3_consumption.dta
				
NOTE:			Round 1 consumption aggregate is only in the IHS wave 3 data
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Consumption loop
****************************************************************/

capture program drop consumpagg
program define consumpagg

	gen food_share = food / consumption
	label variable food_share "Proportion of total consumption spent on food and non-alc beverages, annual"

	foreach var in food consumption {
		gen `var'_ae = `var' / adulteq
		gen log`var' = ln(`var')
		gen log`var'_ae = ln(`var'_ae)
		gen log`var'_pc = ln(`var'_pc)
	}

	label var food_ae "annual hhold food exp per adult eq, real"
	label var consumption_ae "annual hhold total exp per adult eq, real"
	label var logconsumption "log total hhold exp, real"
	label var logconsumption_ae "total hhold exp per adult eq, nominal"
end

/****************************************************************
	SECTION 1: Wave 1
****************************************************************/

use "${MWIraw}/IHS 2010/Panel/Round 1 (2010) Consumption Aggregate.dta", clear

rename (rexpagg pcrexpagg rexp_cat01 pcrexp_cat01) (consumption consumption_pc food food_pc)

consumpagg  // do consumption loop

keep HHID hhsize adulteq price_indexL poor epoor consumption* food* hhweight

save "${MWIbuild}/intermediate/wave1_consumption.dta", replace

/****************************************************************
	SECTION 2: Wave 2
****************************************************************/

use "${MWIraw}/IHPS short-term panel/Round 2 (2013) Consumption Aggregate.dta", clear
rename (rexpagg pcrexpagg) (consumption consumption_pc)
rename (rexp_cat01 pcrexp_cat01) (food food_pc)

consumpagg

keep y2_hhid HHID hhsize adulteq price_indexL poor epoor consumption* food* hhweight

save "${MWIbuild}/intermediate/wave2_consumption.dta", replace

/****************************************************************
	SECTION 3: Wave 3
****************************************************************/

use "${MWIraw}/IHS 2016/IHS4 Consumption Aggregate.dta", clear

rename (rexpagg rexp_cat01 upoor) (consumption food epoor)
gen consumption_pc = consumption / hhsize
gen food_pc = food / hhsize

consumpagg

keep case_id hhsize adulteq price_index poor epoor consumption* food* hh_wgt

merge 1:m case_id using "${MWIraw}/IHS 2016/HH_MOD_A_FILT", keepusing(*id* *ID*) gen(_mp)

save "${MWIbuild}/intermediate/wave3_consumption.dta", replace
