/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Build Indonesia Household Income		
AUTHORS: 		Corey Vernot
DESC: 			Clean Indonesiahousehold income data
ORG:	
INPUTS: 		buk3tk1.dta buk3tk2.dta		
OUTPUTS: 		IFLS1_income.dta			
NOTE:			
******************************************************************/

foreach w in 1 2 3 4 5{
	* adjustments for directory paths
	loc b 
	if `w' == 1 loc b uk
	loc u
	if `w' != 1 loc u _
	noi di "`w'"
	use "${IDNraw}/IFLS`w'/Household/b`b'2`u'ut1.dta", clear
	if `w' == 1 ren *b1 *
	
	* create farm income
	gen farmInc = ut09
	replace farmInc = ut07 - ut08 if mi(farmInc)
	if inlist(`w', 1,2)  replace farmInc = 0 if ut01 == 3 & mi(farmInc)
	if !inlist(`w', 1,2) replace farmInc = 0 if ut00a == 3 & mi(farmInc)
	tempfile farmInc
	save `farmInc', replace
	
	* create business income
	use "${IDNraw}/IFLS`w'/Household/b`b'2`u'nt1.dta", clear
	if `w' > 2 use  "${IDNraw}/IFLS`w'/Household/b`b'2`u'nt2.dta", clear
	if `w' == 1 ren *b1 *
	gen busInc1 = nt09
	
	replace busInc1 = nt07-nt08 if mi(busInc)
		if `w' == 4 drop hhid07_9
		if `w' == 5 drop hhid14_9
		if `w' == 1 drop hhid
	egen busInc = sum(busInc1), by(hhid)
	keep hhid busInc
	duplicates drop hhid, force
	tempfile busInc
	save `busInc', replace
	
	merge 1:1 hhid using `farmInc', keepusing(farmInc) gen(_minc)
	replace busInc = 0 if _minc == 2
	drop _minc
	
	gen hhlevelInc = busInc + farmInc
	noi codebook hhlevelInc, det
	
	if `w' == 1 gen hhid = hhid93
	if `w' == 2 gen hhid = hhid97
	if `w' == 3 gen hhid = hhid00
	if `w' == 4 gen hhid = hhid07
	if `w' == 5 gen hhid = hhid14
		
	save "${IDNbuild}/intermediate/IFLS`w'_hhlevelInc.dta", replace
}
