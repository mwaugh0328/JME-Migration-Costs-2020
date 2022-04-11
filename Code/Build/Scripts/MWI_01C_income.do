/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Build Malawi income.do	
AUTHORS: 		Sam Marshall, John Mori, Sebastian Quaade
CREATED:		05/24/2019
DESC: 			Clean Malawi income data
ORG:			SECTION 1: Self Employment
				SECTION 2: Primary Job Income
				SECTION 3: Secondary Job Income
				SECTION 4: Ganyu Labor Income
				SECTION 5: Hours Worked
				SECTION 6: Clean Up			
INPUTS: 	HH_MOD_N2_13.dta HH_MOD_E_13.dta		
OUTPUTS: 	wave1_income.dta wave2_income.dta wave3_income.dta		
NOTE:			
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 0: Income Loops
****************************************************************/

capture program drop scalewage
program define scalewage
	args wage units scale months weeks hours
	
	* weeks take values 0 / 4, so make to percent of month
	qui gen weeks_pm = ( min( `weeks' , 4) / 4)
	
	* make wage per one unit
	qui replace `wage' = `wage' / `units'
	
	qui replace `wage' = `wage' * weeks_pm * `months' * (6 / 7) if `scale' == 3  // days, assume 6 days work per week
	qui replace `wage' = `wage' * weeks_pm * `months' if `scale' == 4 // weeks
	qui replace `wage' = `wage' * `months' if `scale' == 5 // month
	
	drop weeks_pm
end

/****************************************************************
	SECTION 1: Self Employment
****************************************************************/
local i = 1

foreach yr in 10 13 16 {
		* specify path for long-term and short-term panels
	if (`yr' == 16) local path "IHPS long-term panel"
	else local path "IHPS short-term panel"
	
	* get hhid var in each wave
	if (`yr' == 10) local hhold = "HHID"
	else if (`yr' == 13) local hhold = "y2_hhid"
	else local hhold = "y3_hhid"
	
	use "${MWIraw}/`path'/HH_MOD_N2_`yr'.dta", clear

	rename (hh_n14 hh_n40) (pft_share profit)

	foreach var in hh_n25a-hh_n25y {
		qui recode hh_n25* (1/3 = 1)
	}

	egen months_op = rowtotal(hh_n25*)
		qui replace months_op = 12 if months_op > 12
	
* create annual hours worked per hhold member
*coding changes in 2016 from 1-d to 1-4...
	if `yr' == 10 | `yr' == 13 {
		local n = 1
		foreach j in a b c d {
			rename (hh_n30`j'1 hh_n30`j'2 hh_n30`j'3 hh_n30`j'4) ///
				(id_code`n' days_`n' hours_`n' months_`n')
			qui gen hours_flag`n' = (days_`n' > 31 & ~mi(days_`n')) | ///
				(months_`n' > 12 & ~mi(months_`n'))
			qui replace months_`n' = 12 if months_`n' > 12 & ~mi(months_`n')
			qui gen ahrs_self`n' = hours_`n'   // it seems that hours are per year for 2013
			if (`yr' == 10) qui replace ahrs_self`n' = hours_`n' * months_`n'
			local ++n
			}
		}
	else {
		forvalues n = 1/7 {
			rename (hh_n30a`n' hh_n30b`n' hh_n30c`n' hh_n30d`n') ///
				(id_code`n' days_`n' hours_`n' months_`n')
			qui gen hours_flag`n' = (days_`n' > 31 & ~mi(days_`n')) | ///
				(months_`n' > 12 & ~mi(months_`n')) | (hours_`n' > 24 & ~mi(hours_`n'))
			qui replace months_`n' = 12 if months_`n' > 12 & ~mi(months_`n')
			qui replace hours_`n' = 24 if hours_`n' > 24 & ~mi(hours_`n')
			qui gen ahrs_self`n' = hours_`n'  * days_`n' * months_`n'
			local ++n
		}
	}

	keep `hhold' hh_n09a pft_share profit id_code* ahrs* months_op

	drop if hh_n09a == . // hhold with no business

* adjust profit to hhold if shared with others outside of the hhold
	qui replace profit = 0.05 * profit if pft_share == 1  // almost none, give 5%
	qui replace profit = 0.25 * profit if pft_share == 2
	qui replace profit = 0.50 * profit if pft_share == 3
	qui replace profit = 0.75 * profit if pft_share == 4
	qui replace profit = 0.95 * profit if pft_share == 5  // almost all, give 95%

* make one obs per person-hhold-business
	reshape long id_code ahrs_self, i(`hhold' hh_n09a) j(memno)

	drop if id_code == .

	gen temp = 1
	bysort `hhold' hh_n09a: egen hh_share = sum(temp)
	bysort `hhold' hh_n09a: egen ahrs_hhold = sum(ahrs_self)

* exclude obs in which people didn't work any hours and had no profit
	drop if ahrs_self == 0 & profit == 0

	gen earn_self = profit / hh_share
	gen earn_self_wgt = profit * ahrs_self / ahrs_hhold

	collapse (sum) earn_self earn_self_wgt ahrs_self, by(`hhold' id_code)

	save "${MWIbuild}/intermediate/wave`i'_self.dta", replace

/****************************************************************
	SECTION 2: Primary Job Income
****************************************************************/

	use "${MWIraw}/`path'/HH_MOD_E_`yr'.dta", clear

	capture drop if hh_e02 == "X"  // for now for ease of use, drop ppl who are under 5 years old

* employed in wage work (which var is reported changes b/w years
	capture gen employed = hh_e18 == 1
	capture gen employed = hh_e06_4 == 1

	rename hh_e20b isic_wage

	rename (hh_e25 hh_e26a hh_e26b) (earn_p units_p scale_p) 
	rename (hh_e22 hh_e23  hh_e24)  (months_p weeks_p hours_p)

* non-monetary payments for primary job
	rename (hh_e27 hh_e28a hh_e28b) (earn_p2 units_p2 scale_p2)

* adjust primary earnings
	scalewage earn_p units_p scale_p months_p weeks_p hours_p

	scalewage earn_p2 units_p2 scale_p2 months_p weeks_p hours_p

* sum and add those with no earnings of this type
	egen earn_primary = rowtotal(earn_p earn_p2)
	replace earn_primary = 0 if employed != 1

/****************************************************************
	SECTION 3: Secondary Job Income
****************************************************************/

* has secondary job
	gen employed2 = hh_e32 == 1

	rename (hh_e39 hh_e40a hh_e40b) (earn_sec units_sec scale_sec)
	rename (hh_e36 hh_e37 hh_e38) (months_sec weeks_sec hours_sec)

* non-monetary payments for primary job
	rename (hh_e41 hh_e42a hh_e42b) (earn_sec2 units_sec2 scale_sec2)

* adjust primary earnings
	scalewage earn_sec units_sec scale_sec months_sec weeks_sec hours_sec

	scalewage earn_sec2 units_sec2 scale_sec2 months_sec weeks_sec hours_sec

* sum and add those with no earnings of this type
	egen earn_secondary = rowtotal(earn_sec earn_sec2)
	replace earn_secondary = 0 if employed2 != 1

/****************************************************************
	SECTION 4: Ganyu Labor Income
****************************************************************/

* did any ganyu labor
	capture gen ganyu = hh_e55 == 1
	capture gen ganyu = hh_e06_6 == 1

	rename (hh_e59 hh_e56 hh_e57 hh_e58 ) (earn_g months_g weeks_g days_g)

	gen earn_ganyu = earn_g * days_g * (weeks_g / 4) * 52 * (months_g / 12)
	replace earn_ganyu = 0 if ganyu != 1

/****************************************************************
	SECTION 5: Hours Worked
****************************************************************/

* hours in apprentice work
	rename (hh_e50 hh_e51 hh_e52) (months_appr weeks_appr hours_appr)

	qui gen ahrs_appr = hours_appr * (weeks_appr / 4) * 52 * (months_appr / 12)

	qui gen ahrs_p = hours_p * (weeks_p / 4) * 52 * (months_p / 12)
	qui gen ahrs_sec = hours_sec * (weeks_sec / 4) * 52 * (months_sec / 12)

* for ganyu assume 10 hours worked per day
	qui gen ahrs_g = 10 * days_g * (weeks_g / 4) * 52 * (months_g / 12)

/****************************************************************
	SECTION 6: Clean Up
****************************************************************/
	if `yr' == 13 {
		rename hh_e01 id_code
	}

	merge 1:1 `hhold' id_code using "${MWIbuild}/intermediate/wave`i'_self.dta"
	drop if _merge == 2

	egen hours = rowtotal(ahrs_appr ahrs_p ahrs_sec ahrs_g ahrs_self)
	
	egen earnings = rowtotal(earn_primary earn_secondary earn_ganyu earn_self), m

	gen wage = earnings / hours

	keep PID earn_primary earn_secondary earn_ganyu earn_self* hours earnings wage ahrs* 

	* label variables
	label var earn_primary "earnings from wage labor, 1st job"
	label var earn_secondary "earnings from wage labor, 2nd job"	
	label var earn_ganyu "earnings from ganyu labor"
	label var earn_self "earnings from self-employment, equal weight"
	label var earn_self_wgt "earnings from self-employment, hours weight"
	label var earnings "total annual income"
	label var hours "Total annual hours worked"

	save "${MWIbuild}/intermediate/wave`i'_income.dta", replace

	erase "${MWIbuild}/intermediate/wave`i'_self.dta"
	local ++i
}

