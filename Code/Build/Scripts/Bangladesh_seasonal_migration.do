/*****************************************************************
PROJECT: 		Cross Country Migration 
				
TITLE:			Build Bangladesh Seasonal Migration Panel.do
			
AUTHOR: 		Corey Vernot

VERSION:		1.0.0

DATE CREATED:	28nd September 2018

LAST EDITED:	10/3/18

DESCRIPTION: 	Creates cleanedPanel.dta, which is a household-year panel
				with data from 2008, 2009, and 2011 on consumption and
				migration status for control villages in the Bangladesh study.


ORGANIZATION: 
				
INPUTS: 		
				
OUTPUTS: 		
				
NOTE:			
******************************************************************/
set more off

*2008 Baseline
use "${BGDraw}/No Lean Season_Round1_Controls_Table1.dta", clear
rename exp_total_pc_r1 average_exp2
gen year = 2007
gen migrated = 0
keep hhid village migrated average_exp* incentive year
tempfile data_base
save `data_base'

*2008 Lean Season
use "${BGDraw}/No Lean Season_Round2.dta", clear
keep hhid village upazila migrant average_exp* incentive
gen year = 2008
encode incentive, generate(incentive2008)
drop incentive
rename migrant migrated
tempfile data08
save `data08'
isid hhid

*2009
use "${BGDraw}/No Lean Season_Round3.dta", clear
keep hhid village upazila migrant_r3 average_exp*
gen year = 2009
rename migrant_r3 migrated

isid hhid

*append years
append using `data_base'
append using `data08' 
isid hhid year

*egen add treatment groups to all years
egen mininc2008 = min(incentive2008), by(hhid)
replace incentive2008 = mininc2008 if incentive2008 == .
gen incentivized2008 = incentive2008 == 1 | incentive2008 == 3
drop mininc*

drop if hhid==92 // very high values for food expenditure (and total), also calories due to very high fish expenditure
gen log_average_exp1 = log(average_exp1)
gen log_average_exp2 = log(average_exp2)
gen log_average_exp3 = log(average_exp3)

save "${BGDbuild}/bgd_panel.dta", replace
