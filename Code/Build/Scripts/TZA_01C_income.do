/*****************************************************************
PROJECT: 		Rural-Urban Migration 
				
TITLE:			Build Tanzania Income
			
AUTHOR: 		Sam Marshall

DATE CREATED:	5/1/2019

DESCRIPTION: 	Clean Tanzania Data and build dataset

ORGANIZATION:	SECTION 1: Wave 1
				SECTION 2: Wave 2
				SECTION 3: Wave 3
				
INPUTS: 		
				
OUTPUTS: 		int/wave_income.dta
				
******************************************************************/

* initiate globals if not done already


/****************************************************************
	SECTION 0: Income Loop
****************************************************************/

capture program drop scalewage
program define scalewage
	args wage scale months weeks hours
	
	* weeks take values 0 / 4 through w2 and 0 / 5 in w3
	qui gen weeks_py = ( min( `weeks' , 4) / 4) * 52
	
	qui replace `wage' = `wage' * `hours' * weeks_py if `scale' == 1  //hours
	qui replace `wage' = `wage' * weeks_py * (6 / 7) if `scale' == 2  // days, assume 6 days work per week
	qui replace `wage' = `wage' * weeks_py if `scale' == 3 // weeks
	qui replace `wage' = `wage' * weeks_py / 2 if `scale' == 4 // fortnight
	qui replace `wage' = `wage' * `months' if `scale' == 5 // month
	qui replace `wage' = `wage' * 4 if `scale' == 6 // quarter
	qui replace `wage' = `wage' * 2 if `scale' == 7 // half year
	
	drop weeks_py
end


***** creating annualized hours *****
capture program drop annhrs
program define annhrs
	syntax [, out(string) months(string) weeks(string) hrs(string)]
	
	***** make hours per day instead of per week *****
	qui gen daily_hours = `hrs' / 7
	
	***** make months share if not missing *****
	if "`months'" != "" {
		qui gen months_share = `months' / 12
	}
	else { 
		qui gen months_share = 1  // this is the assumption here...
	}
	
	***** make weeks share if not missing *****
	if "`weeks'" != "" {
		qui gen weeks_share = min( `weeks' , 4) / 4
	}
	else { 
		qui gen weeks_share = 1  // this is the assumption here...
	}
	
	***** annual hours worked *****
	gen annhrs_`out' = months_share * weeks_share * daily_hours * 365
	
	if annhrs_`out' > 365 * 24 & ~mi(annhrs_`out') {
		disp "Flag for `out' generated"
		qui gen h_flag_`out' = annhrs_`out' > 365 * 24 & ~mi(annhrs_`out')
	}
	
	drop months_share daily_hours weeks_share

end


/****************************************************************
*****************************************************************
	SECTION 1: Wave 1
*****************************************************************
****************************************************************/

/****************************************************************
	SECTION 1.1: Primary Job Income
****************************************************************/

use "${TZAraw}/Wave 1 2008-2009/SEC_B_C_D_E1_F_G1_U.dta", clear


keep hhid sbmemno se* 

keep if seq1 == 1  // drop ppl who are under 5 years old

gen employed = seq3 == 1 | seq4 == 1 // employed in wage work or own business/farm

recode seq16 (2 = 0), gen(any_wage)

rename (seq18_1 seq18_2 seq19) (earn_p scale_p hours_p)

* non-monetary payments for primary job
rename (seq21_1 seq21_2) (earn_p2 scale_p2)

* adjust primary earnings
gen weeks_p = 4
gen months_p = 12 // this is the best we can do for now...
scalewage earn_p scale_p months_p weeks_p hours_p

scalewage earn_p2 scale_p2 months_p weeks_p hours_p
replace earn_p2 = 0 if seq20 != 1  // no payments of this type

* sum and add those with no earnings of this type
egen earn_primary = rowtotal(earn_p earn_p2)
replace earn_primary = 0 if any_wage != 1
rename hours_p hours_primary
rename seq13 isic_primary

/****************************************************************
	SECTION 1.2: Self employment income
****************************************************************/
rename seq24 isic_self

rename (seq45 seq46_hr) (hours_self hours_ag)

gen self_employed = seq22 == 1 | seq23 == 1

* average profit per month times months operated in past year
gen earn_self = seq41 * seq42 if seq41 <= 12 & self_employed == 1

* profits from last week/month
* seq36_1 and 2 are swapped
gen earn_self2 = seq36_2 if self_employed == 1
replace earn_self2 = 52 * earn_self2 if seq36_1 == 1
replace earn_self2 = 12 * earn_self2 if seq36_1 == 2


/****************************************************************
	SECTION 1.3: Aggregate
****************************************************************/

keep hhid sbmemno employed *primary hours* earn_self* isic*

* topcode hours and create flag
foreach var in hours_primary hours_self hours_ag {
	replace `var' = . if `var' > 24 * 7
	sum `var', det
}

egen hours = rowtotal(hours_primary hours_self hours_ag), m
gen hours_flag = hours > 24 * 7 & ~mi(hours)
replace hours = 24 * 7 if hours > 24 * 7 & ~mi(hours)
replace hours = hours * 52

egen earnings = rowtotal(earn_primary earn_self), m


* label variables
label var earn_primary "earnings from wage labor"
label var earn_self2 "own business earnings extrapolated from past month"
label var earn_self "own business earnings past year"
label var earnings "annual income from primary job"
label var hours_flag "flag for topcoded hours/days/weeks values"
label var hours "Total annual hours worked"

save "${TZAbuild}/intermediate/wave1_income.dta", replace

/****************************************************************
*****************************************************************
	SECTION 2: Wave 2
*****************************************************************
****************************************************************/

/****************************************************************
	SECTION 2.1: Primary Job Income
****************************************************************/


use "${TZAraw}/Wave 2 2010-2011/HH_SEC_E1.dta", clear

keep if hh_e01 == 1  // drop ppl who are under 5 years old

* employed in wage work or own business/farm
gen employed = hh_e04 == 1 | hh_e05 == 1 

* indicator for employed in wage work
gen any_wage = hh_e12 == 1 | hh_e13 == 1 

rename (hh_e22_1 hh_e22_2 hh_e26 hh_e27 hh_e28) (earn_p scale_p months_p weeks_p hours_p)

* non-monetary payments for primary job
rename (hh_e24_1 hh_e24_2) (earn_p2 scale_p2)

* adjust primary earnings
scalewage earn_p scale_p months_p weeks_p hours_p

scalewage earn_p2 scale_p2 months_p weeks_p hours_p

* sum and add those with no earnings of this type
egen earn_primary = rowtotal(earn_p earn_p2)
replace earn_primary = 0 if any_wage != 1

/****************************************************************
	SECTION 2.2: Secondary Job Income
****************************************************************/

* indicator for second job
recode hh_e29 (2 = 0), gen(secwork)

rename (hh_e37_1 hh_e37_2 hh_e41 hh_e42 hh_e43) (earn_sec scale_sec months_sec weeks_sec hours_sec)

rename (hh_e39_1 hh_e39_2) (earn_sec2 scale_sec2)

* adjust secondary earnings
scalewage earn_sec scale_sec months_sec weeks_sec hours_sec

scalewage earn_sec2 scale_sec2 months_sec weeks_sec hours_sec

* sum and add those with no earnings of this type
egen earn_secondary = rowtotal(earn_sec earn_sec2)
replace earn_secondary = 0 if secwork != 1

/****************************************************************
	SECTION 2.3: Self employment
****************************************************************/

* hh_e61-e63 are value of goods in own business

gen self_employed = hh_e51 == 1 | hh_e52 == 1

* annualized self employment earnings
rename (hh_e70 hh_e71) (months_self e_self)
gen earn_self = months_self * e_self

* when multiple people report the same income for self employment divide between them
duplicates tag y2_hhid earn_self if earn_self != ., gen(dup_earn)
replace dup_earn = dup_earn + 1
replace earn_self = earn_self / dup_earn

/****************************************************************
	SECTION 2.4: Hours
****************************************************************/

* hours in unpaid apprentice work
annhrs, out(appr) months(hh_e48) weeks(hh_e49) hrs(hh_e50)

* hours in self employment
annhrs, out(self) months(months_self) hrs(hh_e75)
replace annhrs_self = 0 if hh_e74 != 1

* hours past week in own farm ag
rename (hh_e77 hh_e78) (any_ag hours_ag)
replace hours_ag = 0 if any_ag != 1
replace hours_ag = 24 * 7 if hours_ag > 24 * 7 & ~mi(hours_ag)

***** may want to come back to this if we can adjust for time worked during year in ag
gen annhrs_ag = 52 * hours_ag

* total hours in employed work
annhrs, out(primary) months(months_p) weeks(weeks_p) hrs(hours_p)
annhrs, out(secondary) months(months_sec) weeks(weeks_sec) hrs(hours_sec)

egen hours = rowtotal(annhrs_primary annhrs_secondary annhrs_self annhrs_appr annhrs_ag)

gen hours_flag = hours > 365 * 24 & ~mi(hours)
replace hours = 365 * 24 if hours > 365 * 24
 
/****************************************************************
	SECTION 2.5: Clean up
****************************************************************/

egen earnings = rowtotal(earn_primary earn_secondary earn_self)


keep y2_hhid indidy2 earnings hours hours_flag employed 

* label variables
label var earnings "annual income"
label var hours_flag "flag for topcoded hours/days/weeks values"
label var hours "Total annual hours worked"

save "${TZAbuild}/intermediate/wave2_income.dta", replace

/****************************************************************
*****************************************************************
	SECTION 3: Wave 3
*****************************************************************
****************************************************************/


/****************************************************************
	SECTION 3.1: Self employment
****************************************************************/

use "${TZAraw}/Wave 3 2012-2013/HH_SEC_N.dta", clear
* hh_n10 hh_n11 hh_n12 are value of goods in own business

* annualized self employment earnings
rename (hh_n19 hh_n20) (months_self e_self)
gen earn_self = months_self * e_self

keep y3_hhid entid hh_n03_1 hh_n03_2 hh_n03_3 hh_n03_4 hh_n03_5 hh_n03_6 earn_self 

keep if earn_self != .

* make one obs per person-hhold-business
reshape long hh_n03_, i(y3_hhid entid) j(memno)

rename hh_n03_ indidy3
keep if indidy3 != .

* gen count of num hhold members involved in business
bysort y3_hhid entid: egen N_involved = max(memno)

* adjusted earnings share, unweighted by num hours worked
replace earn_self = earn_self / N_involved

collapse (sum) earn_self, by(y3_hhid indidy3)

save "${TZAbuild}/intermediate/wave3_selfemp.dta", replace

/****************************************************************
	SECTION 3.2: Primary Job Income
****************************************************************/

use "${TZAraw}/Wave 3 2012-2013/HH_SEC_E.dta", clear

keep if hh_e01 == 1  // drop ppl who are under 5 years old

* employed in wage work or own business/farm
gen employed = hh_e04b == 1 | hh_e04c == 1 | hh_e04d == 1

* indicator for employed in wage work and receives wages
gen any_wage = hh_e24 

rename (hh_e26_1 hh_e26_2 hh_e29 hh_e30 hh_e31) (earn_p scale_p months_p weeks_p hours_p)

* non-monetary payments for primary job
rename (hh_e28_1 hh_e28_2) (earn_p2 scale_p2)

* adjust primary earnings
scalewage earn_p scale_p months_p weeks_p hours_p

scalewage earn_p2 scale_p2 months_p weeks_p hours_p

* sum and add those with no earnings of this type
egen earn_primary = rowtotal(earn_p earn_p2)
replace earn_primary = 0 if any_wage != 1

/****************************************************************
	SECTION 3.3: Secondary Job Income
****************************************************************/

* indicator for second job
recode hh_e36 (2 = 0), gen(secwork)

rename (hh_e44_1 hh_e44_2 hh_e47 hh_e48 hh_e49) (earn_sec scale_sec months_sec weeks_sec hours_sec)

rename (hh_e46_1 hh_e46_2) (earn_sec2 scale_sec2)

* adjust secondary earnings
scalewage earn_sec scale_sec months_sec weeks_sec hours_sec

scalewage earn_sec2 scale_sec2 months_sec weeks_sec hours_sec

* sum and add those with no earnings of this type
egen earn_secondary = rowtotal(earn_sec earn_sec2)
replace earn_secondary = 0 if secwork != 1

/****************************************************************
	SECTION 3.4: Hours
****************************************************************/

* hours in unpaid apprentice work
annhrs, out(appr) months(hh_e59) weeks(hh_e60) hrs(hh_e61)

* hours in self employment
annhrs, out(self) months(hh_e73) weeks(hh_e74) hrs(hh_e75)

* average hours past year in own farm ag
annhrs, out(ag) months(hh_e66) weeks(hh_e67) hrs(hh_e68)

* total hours in employed work
annhrs, out(primary) months(months_p) weeks(weeks_p) hrs(hours_p)
annhrs, out(secondary) months(months_sec) weeks(weeks_sec) hrs(hours_sec)

egen hours = rowtotal(annhrs_primary annhrs_secondary annhrs_self annhrs_appr annhrs_ag)
 
/****************************************************************
	SECTION 3.5: Clean up
****************************************************************/

merge 1:1 y3_hhid indidy3 using "${TZAbuild}/intermediate/wave3_selfemp.dta"

egen earnings = rowtotal(earn_primary earn_secondary earn_self)


keep y3_hhid indidy3 earnings hours employed 

* label variables
label var earnings "annual income"
label var hours "Total annual hours worked"

save "${TZAbuild}/intermediate/wave3_income.dta", replace

erase "${TZAbuild}/intermediate/wave3_selfemp.dta"

