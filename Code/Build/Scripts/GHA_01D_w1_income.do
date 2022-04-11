/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Ghana Build Wave 1 Income.do		
AUTHOR: 		Sam Marshall
VERSION:		2.0.1
CREATED:		5/1/2019
MODIFIED:		7/15/2019
DESC: 			Clean Ghana Data and build dataset

ORG:			SECTION 1: Primary Job Income
				SECTION 2: Secondary Job Income				
INPUTS: 		S1EI.dta S1EII.dta				
OUTPUTS: 		int/w1_income.dta			
NOTE:			
******************************************************************/

/****************************************************************
	SECTION 0: Data Paths
****************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Primary Job Income
****************************************************************/
use "${GHAraw}/Wave 1/S1EI.dta", clear

*Nonag employment (see ISCO codes in CODE BOOK)
gen nonag = !inlist(s1ei_3, 61, 62, 92, 611, 612, 613, 614, 615, 621, 921)

* hours for Main Employment
rename (s1ei_7i s1ei_7ii s1ei_7iii) (weeks days hours)

* create a flag for impossible answers and top code at max possible
gen hours_flag = weeks > 52 | days > 7 | hours > 24
replace weeks = 52 if weeks > 52 & ~mi(weeks)
replace days = 7 if days > 7 & ~mi(days)
replace hours = 24 if hours > 24 & ~mi(hours)

gen annhours_1 = hours * days * weeks

*Earnings from Main Employement
rename s1ei_10i earnings_1 
	replace earnings_1 = earnings_1 + (s1ei_10ii / 100) if ~mi(s1ei_10ii)
	replace earnings_1 = 0 if s1ei_9 == 2  //no payment for job

* annualize earnings
rename s1ei_11 period
replace earnings_1 = earnings_1 * weeks * days if period == 1  // Daily
replace earnings_1 = earnings_1 * weeks if period == 2  // Weekly
replace earnings_1 = earnings_1 * weeks / 52 * 12 if period == 3  // Monthly
replace earnings_1 = earnings_1 * weeks / 52 * 4 if period == 4  // Quarterly

* other payment for labor
rename s1ei_13i earnings_oth 
	replace earnings_oth = earnings_oth + (s1ei_13ii / 100) if ~mi(s1ei_13ii)
	replace earnings_oth = 0 if s1ei_12 == 2
	
* annualize earnings
rename s1ei_14 period_oth
replace earnings_oth = earnings_oth * weeks * days if period_oth == 1  // Daily
replace earnings_oth = earnings_oth * weeks if period_oth == 2  // Weekly
replace earnings_oth = earnings_oth * weeks / 52 * 12 if period_oth == 3  // Monthly
replace earnings_oth = earnings_oth * weeks / 52 * 4 if period_oth == 4  // Quarterly

replace earnings_1 = earnings_1 + earnings_oth if ~mi(earnings_oth)

* label variables
label var earnings_1 "annual income from primary job"
label var hours_flag "flag for topcoded hours/days/weeks values"
label var annhours_1 "Total annual hours worked in primary occupation"

keep id1 id2 id3 id4 hhmid hhno nonag hours_flag annhours_1 earnings_1 

save "${GHAbuild}/intermediate/wave1_wage.dta", replace

/****************************************************************
	SECTION 2: Secondary Job Income
****************************************************************/
use "${GHAraw}/Wave 1/S1EII.dta", clear

* hours for secondary Employment
rename (s1eii_36i s1eii_36ii s1eii_36iii) (weeks days hours)

* create a flag for impossible answers and top code at max possible
gen hours_flag_2 = weeks > 52 | days > 7 | hours > 24
replace weeks = 52 if weeks > 52 & ~mi(weeks)
replace days = 7 if days > 7 & ~mi(days)
replace hours = 24 if hours > 24 & ~mi(hours)

gen annhours_2 = hours * days * weeks

*Earnings from Secondary Employement
rename s1eii_41i earnings 
	replace earnings = earnings + (s1eii_41ii / 100) if ~mi(s1eii_41ii)
	replace earnings = 0 if s1eii_40 == 2  //no payment for job

* annualize earnings
rename s1eii_42 period
replace earnings = earnings * weeks * days if period == 1  // Daily
replace earnings = earnings * weeks if period == 2  // Weekly
replace earnings = earnings * weeks / 52 * 12 if period == 3  // Monthly
replace earnings = earnings * weeks / 52 * 4 if period == 4  // Quarterly

* other payment for labor
rename s1eii_44i earnings_oth 
	replace earnings_oth = earnings_oth + (s1eii_44ii / 100) if ~mi(s1eii_44ii)
	replace earnings_oth = 0 if s1eii_43 == 2
	
* annualize earnings
rename s1eii_45 period_oth
replace earnings_oth = earnings_oth * weeks * days if period_oth == 1  // Daily
replace earnings_oth = earnings_oth * weeks if period_oth == 2  // Weekly
replace earnings_oth = earnings_oth * weeks / 52 * 12 if period_oth == 3  // Monthly
replace earnings_oth = earnings_oth * weeks / 52 * 4 if period_oth == 4  // Quarterly

egen earnings_2 = rowtotal(earnings earnings_oth)

keep id1 id2 id3 id4 hhmid hhno hours_flag_2 annhours_2 earnings_2 

merge 1:1 id1 id2 id3 id4 hhno hhmid using "${GHAbuild}/intermediate/wave1_wage.dta"

egen earnings = rowtotal(earnings_1 earnings_2), m
egen hours = rowtotal(annhours_1 annhours_2), m

replace hours_flag = 1 if hours_flag_2 == 1
drop hours_flag_2 annhours_2 earnings_2 _merge

label var earnings "annual employment income"
label var hours "annual hours worked in wage labor"

save "${GHAbuild}/intermediate/wave1_income.dta", replace


erase "${GHAbuild}/intermediate/wave1_wage.dta"

/****************************************************************
	SECTION 3: Farm Income
****************************************************************/
* farm profit = farm revenue - transportation cost
use "${GHAraw}/Wave 1/S4BI.dta", clear

rename s4bi_b67i transpo_cost 
	replace transpo_cost = transpo_cost + (s4bi_b67ii / 100) if ~mi(s4bi_b67ii)
	replace transpo_cost = - transpo_cost
	
rename s4bi_b71i farm_rev
	replace farm_rev = farm_rev + (s4bi_b71ii / 100) if ~mi(s4bi_b71ii)

egen farm_profit = rowtotal(farm_rev transpo_cost)
collapse (sum) farm_profit, by(hhno)

save "${GHAbuild}/intermediate/wave1_farm.dta", replace
