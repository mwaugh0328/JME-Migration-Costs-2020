/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Malawi Build Short Term Panel chars.do		
AUTHORS: 		Sam Marshall, John Mori, Sebastian Quaade
CREATED:		05/14/2019
MODIFIED:		5/24/2019
DESC: 			Clean Malawi demographic data
ORG:			SECTION 1: Household Level variables
					SECTION 2: Demographics
					SECTION 3: Education
					SECTION 4: Variables for use in moving cost
					SECTION 5: Combine			
INPUTS: 	HH_MOD_B_10.dta HH_MOD_C_10.dta HH_MOD_A_FILT_10.dta			
OUTPUTS: w1_chars.dta w2_chars.dta			
NOTE:			
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Household level vars
****************************************************************/
use "${MWIraw}/IHPS short-term panel/HouseholdGeovariables_IHS3_Rerelease_10.dta", clear

merge 1:1 HHID using "${MWIraw}/IHPS short-term panel/HH_MOD_X_10.dta", nogen
merge 1:1 HHID using "${MWIraw}/IHPS short-term panel/HH_MOD_F_10.dta", ///
	nogen keepusing(hh_f01 hh_f02)


merge 1:1 HHID using "${MWIraw}/IHPS short-term panel/HH_MOD_A_FILT_10.dta", nogen

rename (hh_a01 hh_a02b) (district ward)
rename (hh_a23_1 hh_a23_2) (intrv_dt1 intrv_dt2)

recode reside (2 = 0), gen(urban)

keep HHID  urban ea_id stratum hh_wgt qx_type district ward intrv* //
	 

save "${MWIbuild}/intermediate/w1_hh.dta", replace

***** 2013 *****	
use "${MWIraw}/IHPS short-term panel/HouseholdGeovariables_IHPS_13.dta", clear
merge 1:1 y2_hhid using "${MWIraw}/IHPS short-term panel/HH_MOD_X_13.dta"
merge 1:1 y2_hhid using "${MWIraw}/IHPS short-term panel/HH_MOD_F_13.dta", ///
	nogen keepusing(hh_f01 hh_f02)


merge 1:1 y2_hhid using "${MWIraw}/IHPS short-term panel/HH_MOD_A_FILT_13.dta", nogen

rename hh_a10b ward

gen intrv_dt1 = mdy(hh_a23a_2, hh_a23a_1, hh_a23a_3)
format intrv_dt1 %td

gen intrv_dt2 = mdy(hh_a37a_2, hh_a37a_1, hh_a37a_3)
format intrv_dt2 %td

recode reside (2 = 0), gen(urban)

keep y2_hhid   urban baseline_rural ea_id stratum hh_wgt panelweight ///
	qx_type district ward intrv* //

	
save "${MWIbuild}/intermediate/w2_hh.dta", replace

***** 2016 *****
use "${MWIraw}/IHPS long-term panel/HouseholdGeovariablesIHPSY3.dta", clear

merge 1:1 y3_hhid using "${MWIraw}/IHPS long-term panel/HH_MOD_X_16.dta", nogen
merge 1:1 y3_hhid using "${MWIraw}/IHPS long-term panel/HH_MOD_F_16.dta", ///
	nogen keepusing(hh_f01 hh_f01_2 hh_f02)



merge 1:1 y3_hhid using "${MWIraw}/IHPS long-term panel/HH_MOD_A_FILT_16.dta", nogen

gen intrv_dt1 = date(interviewdate_v1,"YMD",2000)
format intrv_dt1 %td
gen intrv_dt2 = date(interviewdate_v2,"YMD",2000)
format intrv_dt2 %td

recode reside (2 = 0), gen(urban)

keep y3_hhid case_id urban ta_code region hh_wgt qx_type district mover intrv* panel* //
save "${MWIbuild}/intermediate/w3_hh.dta", replace

/****************************************************************
	SECTION 2: Demographics
****************************************************************/
local i = 1

foreach yr in 10 13 16 {
	* specify the path
	if (`yr' == 16) local path = "IHPS long-term panel"
	else local path = "IHPS short-term panel"

	use "${MWIraw}/`path'/HH_MOD_B_`yr'.dta", clear 
	
	if (`yr' == 10) 			local hhold = "HHID"
	else if (`yr' == 13)	local hhold = "y2_hhid"
	else 							local hhold = "y3_hhid"
	
	capture rename hh_b01 id_code  // in 2013 different name
	
	rename (hh_b05a hh_b04 hh_b24) (age relat marr_stat)
	rename hh_b13 movereason

	gen female = hh_b03 == 2

	keep `hhold' qx_type PID id_code female age relat marr_stat  movereason

	save "${MWIbuild}/intermediate/w`i'_demog.dta", replace

/****************************************************************
	SECTION 3: Education
****************************************************************/

	use "${MWIraw}/`path'/HH_MOD_C_`yr'.dta", clear

	recode hh_c08 (13/14 = 12) (15 20 = 13) (16 21 = 14) (17 22 = 15) ///
		(18 23 = 16) (19 = 18), gen(educ)
	replace educ = 0 if hh_c06 == 2

	keep PID educ

	save "${MWIbuild}/intermediate/w`i'_educ.dta", replace

/****************************************************************
	SECTION 4: Variables for use in moving cost
****************************************************************/


/****************************************************************
	SECTION 5: Combine
****************************************************************/

	use "${MWIbuild}/intermediate/w`i'_hh.dta", clear
	merge 1:m `hhold' using "${MWIbuild}/intermediate/w`i'_demog.dta", nogen
	merge 1:1 PID using "${MWIbuild}/intermediate/w`i'_educ.dta", nogen
	

	save "${MWIbuild}/intermediate/wave`i'_chars.dta", replace

	erase "${MWIbuild}/intermediate/w`i'_hh.dta"
	erase "${MWIbuild}/intermediate/w`i'_educ.dta"
	erase "${MWIbuild}/intermediate/w`i'_demog.dta"
	local ++i
}




