/*****************************************************************
PROJECT: 		Rural-Urban Migration 
				
TITLE:			A_w1_consump.do
			
AUTHORS: 		Sam Marshall
				Hannah Moreno 
				John Mori
				Sebastian Quaade

VERSION:		2.0.1

DATE CREATED:	05/14/2019

LAST EDITED:	5/14/2019

DESCRIPTION: 	Clean Tanzania consumption data

				
INPUTS: 		TZY1.HH.Consumption.dta TZY2.HH.Consumption.dta ConsumptionNPS3.dta
				
OUTPUTS: 		wave1_consumption.dta wave2_consumption.dta wave3_consumption.dta
				
NOTE:			
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Consumption loop
****************************************************************/

capture program drop consumpagg
program define consumpagg

	rename (expm expmR) (consumption consumption_real)
	rename (foodbev foodbevR) (food food_real)

	keep *hhid* mainland food health educa consumption *_real hhsize adulteq region urban

	gen food_share = food / consumption
	label variable food_share "Proportion of total consumption spent on food and non-alc beverages, annual"

	foreach var in food food_real consumption consumption_real {
		gen `var'_ae = `var' / adulteq
		gen log`var' = ln(`var')
		gen log`var'_ae = ln(`var'_ae)
	}

	label var food_ae "total hhold exp on food per adult eq, nominal"
	label var consumption_ae "total hhold exp per adult eq, nominal"
	label var logconsumption "log total hhold exp, nominal"
	label var logconsumption_ae "total hhold exp per adult eq, nominal"

	* make city dummies for all cities with > 200k pop as of 2002 census data.
	gen dodoma = (region == 1 & urban == 2)
	gen dar = (region == 7 & urban == 2)
	gen arusha = (region == 2 & urban == 2)
	gen mwanza = (region == 19 & urban == 2)
	gen tanga = (region == 4 & urban == 2)
	gen morogoro = (region == 5 & urban == 2)
	gen tabora = (region == 14 & urban == 2)
	gen kigoma = (region == 16 & urban == 2)
	//For zanzibar:
	gen zanzibar_city = (inlist(region, 51, 52, 53, 54, 55) & urban == 1)
	
	foreach var of varlist dodoma-zanzibar_city {
		label variable `var' "indicator for lives in `var' city"
	}

	drop urban
end

/****************************************************************
	SECTION 1: Wave 1
****************************************************************/

use "${TZAraw}/Wave 1 2008-2009/TZY1.HH.Consumption.dta", clear

consumpagg  // do consumption loop

save "${TZAbuild}/intermediate/wave1_consumption.dta", replace

/****************************************************************
	SECTION 2: Wave 2
****************************************************************/

use "${TZAraw}/Wave 2 2010-2011/TZY2.HH.Consumption.dta", clear

consumpagg

save "${TZAbuild}/intermediate/wave2_consumption.dta", replace

/****************************************************************
	SECTION 3: Wave 3
****************************************************************/

use "${TZAraw}/Wave 3 2012-2013/ConsumptionNPS3.dta", clear

consumpagg

save "${TZAbuild}/intermediate/wave3_consumption.dta", replace
