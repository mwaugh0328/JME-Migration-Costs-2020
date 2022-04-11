/*****************************************************************
PROJECT: 		Rural-Urban Migration 
				
TITLE:			A_w2_income.do
			
AUTHOR: 		Sam Marshall

VERSION:		1.0.1

DATE CREATED:	5/2/2019

LAST EDITED:	5/2/2019

DESCRIPTION: 	Clean Ghana income data and build dataset

ORGANIZATION:	SECTION 1: Employed
				SECTION 2: Primary Job Income
				SECTION 3: Secondary Job Income
				
INPUTS: 		S1EI.dta S1EII.dta
				
OUTPUTS: 		int/w2_income.dta
				
NOTE:			Secondary job income is commented out until the payment variable
				paidamount is fixed. Currently it is a binary variable. 
				Still need to add farm income etc.
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Employed
****************************************************************/
use "${GHAraw}/Wave 2/01ea_employmentscreener.dta", clear

gen employed = paidemployed == 1 | businessowner == 1 | ///
	businesscontributor == 1 | farmowner == 1 | farmcontributor == 1

keep FPrimary hhmid employed

save "${GHAbuild}/intermediate/wave2_employed.dta", replace

/****************************************************************
	SECTION 2: Primary Job Income
****************************************************************/
use "${GHAraw}/Wave 2/01ei_employmentmain.dta", clear

*Nonag employment (see ISCO codes in CODE BOOK)
destring taskcode, gen(isco) ignore(".")
replace isco = round(isco / 10) if isco >= 1000  // make 3 digit code
gen nonag = !inlist(isco, 61, 62, 63, 92, 611, 612, 613, 614, 615, 621, 622, ///
	631, 632, 633, 634, 921)
	
* hours for Main Employment
rename (jobweeksperyear jobdaysperweek jobhoursperday) (weeks days hours)

* create a flag for impossible answers and top code at max possible
gen hours_flag = weeks > 52 | days > 7 | hours > 24
replace weeks = 52 if weeks > 52 & ~mi(weeks)
replace days = 7 if days > 7 & ~mi(days)
replace hours = 24 if hours > 24 & ~mi(hours)

gen annhours_1 = hours * days * weeks

*Earnings from Main Employement
rename paidamount earnings_1 
	replace earnings_1 = 0 if paid == 5  //no payment for job

* annualize earnings
rename paidperiod period
replace earnings_1 = earnings_1 * weeks * days if period == 1  // Daily
replace earnings_1 = earnings_1 * weeks if period == 2  // Weekly
replace earnings_1 = earnings_1 * weeks / 52 * 12 if period == 3  // Monthly
replace earnings_1 = earnings_1 * weeks / 52 * 4 if period == 4  // Quarterly

* other payment for labor
rename paidothervalue earnings_oth 
	replace earnings_oth = 0 if paidother == 5
	
* annualize earnings
rename paidotherperiod period_oth
replace earnings_oth = earnings_oth * weeks * days if period_oth == 1  // Daily
replace earnings_oth = earnings_oth * weeks if period_oth == 2  // Weekly
replace earnings_oth = earnings_oth * weeks / 52 * 12 if period_oth == 3  // Monthly
replace earnings_oth = earnings_oth * weeks / 52 * 4 if period_oth == 4  // Quarterly

replace earnings_1 = earnings_1 + earnings_oth if ~mi(earnings_oth)

* label variables
label var earnings_1 "annual income from primary job"
label var hours_flag "flag for topcoded hours/days/weeks values"
label var annhours_1 "Total annual hours worked in primary occupation"

keep FPrimary hhmid nonag hours_flag annhours_1 earnings_1 

save "${GHAbuild}/intermediate/wave2_wage.dta", replace

/****************************************************************
	SECTION 3: Secondary Job Income
****************************************************************/
/*
use "${rawdata}/Wave 2/01eii_employmentsecondary.dta", clear

rename (jobweeksperyear jobdaysperweek jobhoursperday) (weeks days hours)

* create a flag for impossible answers and top code at max possible
gen hours_flag_2 = weeks > 52 | days > 7 | hours > 24
replace weeks = 52 if weeks > 52 & ~mi(weeks)
replace days = 7 if days > 7 & ~mi(days)
replace hours = 24 if hours > 24 & ~mi(hours)

gen annhours_2 = hours * days * weeks

*Earnings from Secondary Employement
rename paidamount earnings 
	replace earnings = 0 if paid == 5  //no payment for job

* annualize earnings
rename s1eii_42 period
replace earnings = earnings * weeks * days if period == 1  // Daily
replace earnings = earnings * weeks if period == 2  // Weekly
replace earnings = earnings * weeks / 52 * 12 if period == 3  // Monthly
replace earnings = earnings * weeks / 52 * 4 if period == 4  // Quarterly

* other payment for labor
rename paidothervalue earnings_oth 
	replace earnings_oth = 0 if paidother == 5
	
* annualize earnings
rename paidotherperiod period_oth
replace earnings_oth = earnings_oth * weeks * days if period_oth == 1  // Daily
replace earnings_oth = earnings_oth * weeks if period_oth == 2  // Weekly
replace earnings_oth = earnings_oth * weeks / 52 * 12 if period_oth == 3  // Monthly
replace earnings_oth = earnings_oth * weeks / 52 * 4 if period_oth == 4  // Quarterly

egen earnings_2 = rowtotal(earnings earnings_oth)

keep FPrimary hhmid hours_flag_2 annhours_2 earnings_2 

merge 1:1 FPrimary hhmid using "${build}/wave1_wage.dta"

egen earnings = rowtotal(earnings_1 earnings_2), m
egen hours = rowtotal(annhours_1 annhours_2), m

replace hours_flag = 1 if hours_flag_2 == 1
drop hours_flag_2 annhours_2 earnings_2 _merge

*/

rename earnings_1 earnings
rename annhours_1 hours

label var earnings "annual employment income"
label var hours "annual hours worked in wage labor"

merge 1:1 FPrimary hhmid using "${GHAbuild}/intermediate/wave2_employed.dta", nogen

save "${GHAbuild}/intermediate/wave2_income.dta", replace


erase "${GHAbuild}/intermediate/wave2_wage.dta"
erase "${GHAbuild}/intermediate/wave2_employed.dta"





