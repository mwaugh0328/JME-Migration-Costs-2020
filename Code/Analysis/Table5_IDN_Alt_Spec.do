/*****************************************************************
PROJECT: 		LMMVW Replication Files
				
TITLE:			Table 5: Results for Indonesia Under Alternative Specifications.
			
DESCRIPTION: 	Estimate returns under a number of different specifications for Indonesia

ORGANIZATION:	Section 1: 
				Section 2: 

NOTE:			
******************************************************************/


use "${xcbuild}/Indonesia.dta", clear
if 1 == 2 {
cap drop hhearnings*
loc i = 0
*set trace on
gen miss = .
foreach wage in  hhwage2 hhwageInc earn2 earnings {	
	loc ++ i
	loc j = 0
	
	*gen hhearnings`i'_hhlevel2 = `wage' + hhlevel2
	*gen hhearnings`i'_hhlevel = `wage' + hhlevelInc
	egen hhearnings`i'_hhlevel2 = rowtotal(`wage' hhlevel2)
	egen hhearnings`i'_hhlevel = rowtotal(`wage' hhlevelInc)
	*if "`wage'" == miss loc wage
	foreach self in  hhself2 hhselfInc miss {
		loc ++ j
		loc k = 0
			*if "`self'" == miss loc self

		foreach bus in  hhbus2 busInc miss{
			loc ++ k
			loc l = 0
				*if "`bus'" == miss loc bus

			foreach farm in  hhfarm2 farmInc  {
				loc ++ l
					*if "`farm'" == miss loc farm
				loc exp 
				if "`wage'" != "miss" loc exp `wage'
				if "`self'" != "miss" & "`exp'" != "" loc exp `exp' + `self' 
				if "`self'" != "miss" & "`exp'" == "" loc exp `self' 
				if "`bus'" != "miss" & "`exp'" != "" loc exp `exp' + `bus' 
				if "`bus'" != "miss" & "`exp'" == "" loc exp `bus' 
				if "`farm'" != "miss" & "`exp'" != "" loc exp `exp' + `farm' 
				if "`farm'" != "miss" & "`exp'" == "" loc exp `farm' 
				di "`exp'"
				if "`exp'" == "" continue
				gen hhearnings`i'_`j'_`k'_`l'_ = `exp'
				
				egen hhearnings`i'_`j'_`k'_`l' = rowtotal(`wage' `self' `bus' `farm'), mi
				label var hhearnings`i'_`j'_`k'_`l'  "`wage' `self' `bus' `farm'"
				label var hhearnings`i'_`j'_`k'_`l'_  "`wage' `self' `bus' `farm'"
			}
		}
	}
}

cap drop hhearnings3_3_3_3
sum CPI_indonesia if year == 2014
local base = `r(mean)'

winsor2 hhearnings*, cuts(0.5 99.5)
foreach var of varlist hhearnings* {
	gen log`var' = log(`var'/nadult * `base' / CPI_indonesia)
	gen log`var'_na2 = log(`var'/nadult * `base' / CPI_indonesia/nadult)
	gen log`var'_n = log(`var'/nadult ) //* `base' / CPI_indonesia
}
gen csec = .
gen all = .
gen srur = .
gen surb = .
gen vardef = ""
ds loghhearnings*
loc i = 0
foreach v in `r(varlist)' {
	loc ++ i
	di `i'
}

loc i = 0
qui foreach var of varlist loghhearnings* {
	loc ++ i
	noi di "-----------     `i'         ------ "
	noi di "`var'"
	reg `var' urban
	replace csec = _b[urban] if _n == `i'
	replace vardef = "`var'" if _n == `i'
}
gen distcsec = abs(csec - 0.54)
sort distcsec
cap drop num
gen num = _n
cap drop mindist

qui foreach i of numlist 1/916 {
	loc var = vardef[`i']
	noi di "`var', ------ `i'  -----"
	areg `var' urban age age2 hhsize hhsize2 i.wave if startUrban == 0, absorb(pid) vce(cluster fhhid) //  
	replace srur = _b[urban] if _n == `i'
	areg `var' urban age age2 hhsize hhsize2  i.wave if startUrban == 1, absorb(pid) vce(cluster fhhid)  //
	replace surb = _b[urban] if _n == `i'
	
	if mod(`i', 5) == 0 {
		loc csec = .54
		loc surb = -.004
		loc srur = .148
		foreach var of varlist csec surb srur {
			cap drop `var'_
				sum `var'
			gen `var'_ = (`var' - ``var'' )/`r(sd)'
		}
		cap drop distance
		gen distance = sqrt(csec_^2 + srur_^2 + surb_^2)
		noi tw (scatter srur surb) (scatteri 0.148 -0.004, mcolor("red"))
		
		cap drop mindist
		rangestat (min) mindist = distance if num <= `i', interval(num, ., 0)
		noi tw line mindist num if num <= `i'
	}
}

gen na2 = regexm(vardef, "na2")
sort  na2 distance
browse distance vardef csec srur surb
tw (scatter srur surb if na2 == 0) (scatteri 0.148 -0.004, mcolor("red")) (function y = x, ra(surb))


	*areg `var' urban age age2  hhsize hhsize2  i.wave , absorb(pid) vce(cluster fhhid) //if startUrban == 0 
	*replace all = _b[urban] if _n == `i'



tw (scatter srur surb) (scatteri 0.148 -0.004, mcolor("red"))
sort distance
browse csec all srur surb distance vardef

stop

gen distance = sqrt((srur - .148)^2 + (surb - .004)^2)
sort distance
levelsof vardef if _n < 16
gl vars `r(levels)'
foreach v in `r(levels)' {
		reg log`v' urban
		replace csec = _b[urban] if vardef == "`v'"
		areg log`v' urban age age2  hhsize hhsize2  i.wave , absorb(pid) vce(cluster fhhid) //if startUrban == 0 
		replace all = _b[urban] if vardef == "`v'"
}
browse csec all srur surb distance vardef

stop
gl vars 
qui foreach var of varlist hhearnings* {
	reg log`var' urban
	loc c = round(_b[urban], .001)
	if `c' > 0.45 & `c' < 0.63  noi di "`var':     `c'"
	if `c' > 0.45 & `c' < 0.63 gl vars $vars `var'
}

qui foreach var of varlist $vars {
	reg log`var' urban
	loc c = round(_b[urban], 0.001)
	areg log`var' urban age age2  hhsize hhsize2  i.wave , absorb(pid) vce(cluster fhhid) //if startUrban == 0 
	loc b = round(_b[urban], .001)
	
			areg log`var' urban age age2 hhsize hhsize2 i.wave if startUrban == 0, absorb(pid) vce(cluster fhhid) //  
					loc d  = _b[urban]

			areg log`var' urban age age2 hhsize hhsize2  i.wave if startUrban == 1, absorb(pid) vce(cluster fhhid)  //
		loc e  = _b[urban]
		
		
	*reg log`var' urban_hklm
	*loc d = round(_b[urban_hklm], .001)
	noi di "`var':     `c'   ; All `b' ;   StartUrban  `e'   ; StartRural    `d'"
}

		areg loghhearnings_pa urban age age2 hhsize hhsize2 i.wave , absorb(pid) vce(cluster fhhid)
		areg loghhearnings_pa urban age age2 hhsize hhsize2 i.wave if startUrban == 1, absorb(pid) vce(cluster fhhid)
		areg loghhearnings_pa urban age age2 hhsize hhsize2 i.wave if startUrban == 0, absorb(pid) vce(cluster fhhid)

}

		
eststo clear
loc urb urban_hklm
gl mods crossSec panel startRur moveWork 
gl rownames  urbBigEarn urbBigEarnHH urbBigCons urbMigEarn urbMigEarnHH urbMigCons
foreach t in $mods{
		matrix b_`t'= J(1, 6, .)
		matrix v_`t' = J(6, 6, 0)
		matrix colnames b_`t' = $rownames
		matrix colnames v_`t' = $rownames
		matrix rownames v_`t' = $rownames
}
loc i = 0
foreach u in "" _hklm {
	loc urb urban`u'
	foreach hh in "" hh {
		if "`hh'" == "hh" loc pa _pa
		if "`hh'" != "hh" loc pa
		loc ++ i

		loc hhs hhsize hhsize2
		if "`hh'" == "" loc hhs 

		reg log`hh'earnings`pa' `urb'
		matrix b_crossSec[1, `i'] = _b[`urb']
		matrix v_crossSec[`i', `i'] = _se[`urb']^2

		areg log`hh'earnings`pa' `urb' age age2 `hhs' i.wave , absorb(pid) vce(cluster fhhid)
		matrix b_panel[1, `i'] = _b[`urb']
		matrix v_panel[`i', `i'] = _se[`urb']^2

		if "`hh'" != "hh" {
			areg log`hh'earnings`pa' c.`urb'#startUrban`u' age age2  `hhs'  i.wave , absorb(pid) vce(cluster fhhid)
			matrix b_startRur[1, `i'] = _b[0b.startUrban`u'#c.`urb']
			matrix v_startRur[`i', `i'] = _se[0b.startUrban`u'#c.`urb']^2
		}
		
		if "`hh'" == "hh" {
			areg log`hh'earnings`pa' `urb' age age2 `hhs'  i.wave if startUrban == 0, absorb(pid) vce(cluster fhhid)
			matrix b_startRur[1, `i'] = _b[urban]
			matrix v_startRur[`i', `i'] = _se[urban]^2
		}
		
		areg log`hh'earnings`pa'  c.`urb'#mreason i.mreason age age2  `hhs' i.wave if startUrban == 0, absorb(pid) vce(cluster fhhid)
		matrix b_moveWork[1, `i'] = _b[1b.mreason#c.`urb']
		matrix v_moveWork[`i', `i'] = _se[1b.mreason#c.`urb']^2

	}

	loc ++ i
	loc hhs hhsize hhsize2
	reg logcons`pa' `urb'
	matrix b_crossSec[1, `i'] = _b[`urb']
	matrix v_crossSec[`i', `i'] = _se[`urb']^2

	areg logcons`pa' `urb' age age2 `hhs'  i.wave , absorb(pid) vce(cluster fhhid)
	matrix b_panel[1, `i'] = _b[`urb']
	matrix v_panel[`i', `i'] = _se[`urb']^2
	 
	*areg logcons_pa c.`urb'#startUrban`u' age age2 `hhs'  i.wave , absorb(pid) vce(cluster fhhid)
	*matrix b_startRur[1, `i'] = _b[0b.startUrban`u'#c.`urb']
	*matrix v_startRur[`i', `i'] = _se[0b.startUrban`u'#c.`urb']^2
	
	areg logcons`pa' `urb' age age2 `hhs'  i.wave if startUrban == 0, absorb(pid) vce(cluster fhhid)
	matrix b_startRur[1, `i'] = _b[urban]
	matrix v_startRur[`i', `i'] = _se[urban]^2
	
	areg logcons_pa	c.`urb'#mreason i.mreason age age2 `hhs'  i.wave if startUrban == 0, absorb(pid) vce(cluster fhhid)
		matrix b_moveWork[1, `i'] = _b[1b.mreason#c.`urb']
		matrix v_moveWork[`i', `i'] = _se[1b.mreason#c.`urb']^2

}

foreach t in $mods{
		di "`t'"
		cap matrix drop b V
		matrix b = b_`t'
		matrix V = v_`t'
		ereturn post b V
		eststo `t'	
}
foreach r in $rownames{
	cap drop `r'
	gen `r' = .
}

label var urbBigEarn "City, Ind. Earnings"
label var urbBigEarnHH "City, HH. Earnings"
label var urbBigCons "City, HH. Consumption"
label var urbMigEarn "City + small towns, Ind. Earnings"
label var urbMigEarnHH "City + small towns, HH. Earnings"
label var urbMigCons "City + small towns, HH. Consumption"
estadd local Individual_FE "Yes": $mods
estadd local Individual_FE "No", replace : crossSec
estadd local Year_FE "Yes": $mods
estadd local Initial_Location "Rural": $mods
estadd local Initial_Location "All", replace: crossSec panel
estadd local Move_Reason "Any": $mods
estadd local Move_Reason "Work", replace: moveWork
estadd local Local_Mig_Rate "All": $mods
*estadd local Local_Mig_Rate "High", replace: highMig
*estadd local Local_Mig_Rate "Low", replace: lowMig

esttab crossSec panel startRur moveWork   ,  ///
		 label wrap b(3) se(3) se star(* .1 ** .05 *** .01) ///
		title(Results for Indonesia Under Alternative Specifications.) ///
		stats(Individual_FE Year_FE Initial_Location Move_Reason Local_Mig_Rate) /// 
		mtitles("Cross-Section" "Panel" "Rural-Only" "Work Moves" "HighRL" "LowRL")

esttab crossSec panel startRur moveWork  using ///
	"${tabledir}/Table5_Indonesia_robustness.tex", replace ///
		booktabs label wrap b(3) se(3) se star(* .1 ** .05 *** .01) ///
		title(Results for Indonesia Under Alternative Specifications.) ///
		stats(Individual_FE Year_FE Initial_Location Move_Reason Local_Mig_Rate) /// 
		mtitles("Cross-Section" "Panel" "Rural-Only" "Work Moves")

		