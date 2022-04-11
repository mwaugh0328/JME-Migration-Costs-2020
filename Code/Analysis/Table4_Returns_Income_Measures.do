/*****************************************************************
PROJECT: 		LMMVW Replication Files
				
TITLE:			Table 4: Observational Returns to Migration: Income Measures.
			
DESCRIPTION: 	Estimate cross section and obs return to migration using income

NOTE:			This table works and gives the right numbers. Just want to clean up the global calls a bit 
				so that we aren't overwriting and then comment. Perhaps have this only make the 
				table that actually appears in the paper. 
				This also makes Table 4. So split into two files
******************************************************************/


local mods csec all surb srur 

* set countries for this table
local inc_ctrys idn saf
local inc_ctrynames `" "Indonesia" "South Africa" "'

* intitialize matrix 
local nctry = wordcount(`" `inc_ctrys' "')

foreach t of local mods {

	matrix b_`t' = J(1, `nctry', .)
	
	matrix v_`t' = J(`nctry', `nctry', 0)
	
	matrix colnames b_`t' = `inc_ctrys'
	matrix colnames v_`t' = `inc_ctrys'
	matrix rownames v_`t' = `inc_ctrys'
}

loc i = 0

* estimate model for each country
qui foreach ctry in `inc_ctrynames' {
	loc ++ i
	use "${xcbuild}/`ctry'.dta", clear

	/*if "`ctry'" == "Indonesia" {
		sum CPI_indonesia if year == 2014
		local base = r(mean)
		gen loghhearnings3 = log(hhearnings3/nadult*`base'/CPI_indonesia)
		replace loghhearnings_pa = loghhearnings
	}*/
	
	
	noi di " `ctry'  "

	
	reg loghhearnings_pa urban
	matrix b_csec[1, `i'] = _b[urban]
	matrix v_csec[`i', `i'] = _se[urban]^2 
	areg loghhearnings_pa urban hhsize hhsize2 age agesq i.wave, absorb(pid) vce(cluster fhhid)
	matrix b_all[1, `i'] = _b[urban]
	matrix v_all[`i', `i'] = _se[urban]^2
	areg loghhearnings_pa urban hhsize hhsize2 age agesq i.wave if startUrban == 1, absorb(pid) vce(cluster fhhid)
	matrix b_surb[1, `i'] = _b[urban]
	matrix v_surb[`i', `i'] = _se[urban]^2
	areg loghhearnings_pa urban hhsize hhsize2 age agesq i.wave if startUrban == 0, absorb(pid) vce(cluster fhhid)
	matrix b_srur[1, `i'] = _b[urban]
	matrix v_srur[`i', `i'] = _se[urban]^2
	
	}


eststo clear
foreach t of local mods {
	cap drop b
	cap drop V
	matrix b = b_`t'
	matrix list b
	matrix V = v_`t'
	ereturn post b V
	eststo `t'
}



estadd local Individual_FE "Yes": `mods'
estadd local Individual_FE "No", replace : csec
estadd local Year_FE "Yes": `mods'
estadd local Year_FE "No", replace : csec
estadd local Sample "Full" : `mods'
estadd local Sample "Start Rural" , replace : srur*
estadd local Sample "Start Urban", replace : surb*

loc i = 0
tokenize `" `inc_ctrynames' '"'
foreach ctry in `inc_ctrys'{
	loc ++ i
	cap drop `ctry'
	gen `ctry' = .
	label var `ctry' `" ``i'' "'
}

esttab csec all surb srur ,  ///
	 label wrap b(3) se(3) se star(* .1 ** .05 *** .01) ///
	title(Observational Returns to Migration: Income Measures.) ///
	stats(hours_control Individual_FE Year_FE Sample) //
	
	
esttab csec all surb srur using "${tabledir}/Table4_Returns_inc.tex", replace ///
	booktabs label wrap b(3) se(3) se star(* .1 ** .05 *** .01) ///
	title(Observational Returns to Migration: Income Measures.) ///
	stats(hours_control Individual_FE Year_FE Sample) /// 
	nonote addnotes( ///
"Note: This table presents the estimated coefficients of urban dummy" ///
"variables from regressions of log household income per adult on urban" ///
"dummies and other covariates in the six countries. Column (1) presents" ///
"the cross-sectional estimates, with no other controls. Column (2) adds" ///
"year and individual fixed effects, plus quadratic controls for age and" ///
"household size. Column (3) has year and individual fixed effects, plus" ///
"quadratic controls for age and household size, and restricts the sample to" ///
"only those starting in an urban location. Column (4) is the same model" ///
"as in column (3), but restricts the sample to only those starting from a" ///
"rural location. Robust standard errors, clustered at the level of the wave" ///
"1 household, are in parenthesis. $\sym{*} p<.1, \sym{**}p<.05, \sym{***}p<.01$")
		

				
