/*****************************************************************
PROJECT: 		LMMVW Replication Files
				
TITLE:			Table 7: Observational vs. Experimental Returns to Seasonal Migration.
			
DESCRIPTION: 	Estimate observational and experimental returns to migration using
				Bangladesh seasonal migration data and report the difference. 

ORGANIZATION:	Section 1: Function to get bootstrap standard errors
				Section 2: Estimate FE and IV models

NOTE:			Requires outreg2. To install type:
				ssc install outreg2
******************************************************************/

/****************************************************************
	SECTION 1: Function to get bootstrap standard errors
*****************************************************************/

capture program drop ivfe
program ivfe, rclass
	areg log_average_exp3 migrated i.year if incentivized2008 == 0, absorb(hhid) vce(cluster hhid)
	loc fe = _b[migrated]
	ivregress 2sls log_average_exp3 (migrated  = incentivized2008) if year == 2008, cl(village) //savefirst
	loc iv = _b[migrated]
	return scalar diff = `iv' - `fe'
end

/****************************************************************
	SECTION 2: Estimate FE and IV models
*****************************************************************/

use "${BGDbuild}/bgd_panel.dta", clear

label var migrated "Seasonally Migrated"
capture drop _bs_1
gen _bs_1 = .
label var _bs_1 "Difference in Returns"


local fe "Yes"
*Observational returns to migration
areg log_average_exp3 migrated i.year if incentivized2008 == 0, absorb(hhid) vce(cluster hhid)
outreg2 using "${tabledir}/Table7_Obs_v_Exp.tex", ///
	replace ctitle("Observational") tex(frag) keep(migrated) dec(3) label  ///
	addtext("Individual FE", `fe', "Year FE", `fe') nonotes 

	* Notes in text. 
*	///
*	addnote("Note: The dependent variable in the regressions is the log of consumption per adult. The data come from Bryan, Chowdhury, and Mobarak (2014). Column (1) is estimated using households in the control group with household and year fixed effects. Column (2) presents the Local Average Treatment Effect (LATE) of migration on consumption using treatment assignment as an instrument for migration. Column (3) presents the difference between Columns (1) and (2). Standard errors in Columns (1) and (2) are clustered at the village level. The standard error in column (3) is computed from 10 0 0 bootstrap replications. $\sym{*} p<.1, \sym{**}p<.05, \sym{***}p<.01$") 
		
*Experimental returns to migration
ivregress 2sls log_average_exp3 (migrated  = incentivized2008) if year == 2008, cl(village)
outreg2 using "${tabledir}/Table7_Obs_v_Exp.tex", ///
	append ctitle("Experimental") tex(frag) keep(migrated) dec(3) label  ///
	addtext("Individual FE", `fe', "Year FE", `fe')
	
* Bootstrap difference
set seed 1439
bootstrap r(diff), reps(1000) cluster(hhid) strata(incentivized2008): ivfe
outreg2 using "${tabledir}/Table7_Obs_v_Exp.tex", ///
	append ctitle("Difference") tex(frag)  dec(3) label 
					
