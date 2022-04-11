/*****************************************************************
PROJECT: 		LMMVW Replication Files
				
TITLE:			Table 3: Observational Returns to Migration in Six Developing Countries
			
DESCRIPTION: 	Estimate cross section and obs return to migration 
******************************************************************/

local ctrynames `""China" "Ghana" "Indonesia" "Malawi" "South Africa" "Tanzania" "'
local ctrys chn gha idn mwi saf tza

local mods csec all surb srur 

* initialize matrix 
local nctry = wordcount(`" `ctrys' "')


foreach t of local mods {

	matrix b_`t' = J(1, `nctry', .)
	
	matrix v_`t' = J(`nctry', `nctry', 0)
	
	matrix colnames b_`t' = `ctrys'
	matrix colnames v_`t' = `ctrys'
	matrix rownames v_`t' = `ctrys'
}

loc i = 0

* estimate model for each country
qui foreach ctry of local ctrynames {
	loc ++ i
	use "${xcbuild}/`ctry'.dta", clear
	if "`ctry'" == "chn" replace logearnings = logfearnings
	noi di " `ctry'  "
	
	reg logcons_pa urban
	matrix b_csec[1, `i'] = _b[urban]
	matrix v_csec[`i', `i'] = _se[urban]^2 
	areg logcons_pa urban hhsize hhsize2 age agesq i.wave, absorb(pid) vce(cluster fhhid)
	matrix b_all[1, `i'] = _b[urban]
	matrix v_all[`i', `i'] = _se[urban]^2
	areg logcons_pa urban hhsize hhsize2 age agesq i.wave if startUrban == 1, absorb(pid) vce(cluster fhhid)
	matrix b_surb[1, `i'] = _b[urban]
	matrix v_surb[`i', `i'] = _se[urban]^2
	areg logcons_pa urban hhsize hhsize2 age agesq i.wave if startUrban == 0, absorb(pid) vce(cluster fhhid)
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

* label each row with country name
loc i = 0
tokenize `"`ctrynames'"'
foreach ctry of local ctrys {
	loc ++ i
	cap drop `ctry'
	gen `ctry' = .
	label var `ctry' `" ``i'' "'
}

esttab csec all surb srur , replace ///
	 label wrap b(3) se(3) se star(* .1 ** .05 *** .01) ///
	title(Observational Returns to Migration in Six Developing Countries.) //
	
esttab csec all surb srur using "${tabledir}/Table3_Obs_Returns_to_Migration.tex", replace ///
	booktabs label wrap b(3) se(3) se star(* .1 ** .05 *** .01) ///
	title(Observational Returns to Migration in Six Developing Countries.) ///
	stats(Individual_FE Year_FE Sample) nonote addnotes( ///
"Note: This table presents the estimated coefficients of urban dummy" ///
"variables from regressions of log consumption per adult on urban dummies" ///
"and other covariates in the six countries. Column (1) presents" ///
"the cross-sectional estimates, with no other controls. Column (2) adds" ///
"year and individual fixed effects, plus quadratic controls for age and" ///
"household size. Column (3) has year and individual fixed effects, plus" ///
"quadratic controls for age and household size, and restricts the sample to" ///
"only those starting in an urban location. Column (4) is the same model" ///
"as in column (3), but restricts the sample to only those starting from a" ///
"rural location. Robust standard errors, clustered at the level of the wave" ///
"1 household, are in parenthesis. $\sym{*} p<.1, \sym{**}p<.05, \sym{***}p<.01$") 
	

				
