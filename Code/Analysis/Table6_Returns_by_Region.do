
/*****************************************************************
PROJECT: 		LMMVW Replication Files
				
TITLE:			Table 6: Observational Returns to Migration by Region
			
DESCRIPTION: 	Estimate results for high and low migration regions	
******************************************************************/

/****************************************************************
	SECTION 1: Consumption: Low vs. High Migration EAs
****************************************************************/

local ctrys chn gha idn mwi saf tza
local ctrynames `""China" "Ghana" "Indonesia" "Malawi" "South Africa" "Tanzania" "'

local mods lowmig highmig pdiff

local nctry = wordcount(`" `ctrys' "')
foreach t of local mods {
		matrix b_`t'= J(1, `nctry', .)
		matrix v_`t' = J(`nctry', `nctry', 0)
		matrix colnames b_`t' = `ctrys'
		matrix colnames v_`t' = `ctrys'
		matrix rownames v_`t' = `ctrys'
}

loc i = 0

qui foreach ctry of local ctrynames {
	loc ++ i
	noi di " `ctry'  "
	use "${xcbuild}/`ctry'.dta", clear
		
	areg logcons_pa c.urban#highrl2 age agesq hhsize hhsize2 i.wave ///
		if startUrban == 0, absorb(pid) vce(cluster fhhid)
		
	matrix b_highmig[1, `i'] = _b[1.highrl2#c.urban]
	matrix v_highmig[`i', `i'] = _se[1.highrl2#c.urban]^2
	matrix b_lowmig[1, `i'] = _b[0b.highrl2#c.urban]
	matrix v_lowmig[`i', `i'] = _se[0b.highrl2#c.urban]^2
	test 1.highrl2#c.urban = 0b.highrl2#c.urban
	matrix b_pdiff[1, `i'] = round(`r(p)', .001)
		
}

eststo clear
foreach t of local mods {
	di "    `t'     "
	cap drop b
	cap drop V
	matrix b = b_`t'
	matrix V = v_`t'
	if !regexm("`t'", "pdiff") ereturn post b V
	if regexm("`t'", "pdiff") ereturn post b
	eststo `t'
}

estadd local hours_control "No" : *
estadd local Individual_FE "Yes": highmig* lowmig* 
estadd local Year_FE "Yes": highmig* lowmig*  
estadd local Sample "High Migration": highmig*
estadd local Sample "Low Migration", replace: lowmig*



loc i = 0
tokenize `" `ctrynames' '"'
foreach ctry of local ctrys {
	loc ++ i
	cap drop `ctry'
	gen `ctry' = .
	label var `ctry' `" ``i'' "'
}

esttab highmig lowmig pdiff , ///
	replace  label wrap b(3) se(3) se star(* .1 ** .05 *** .01) ///
	title(Observational Returns to Migration by Region.) ///
	stats(Individual_FE Year_FE Sample) /// 
	mtitles("log(Cons. PA)"  "log(Cons. PA)" "p: C1 = C2"  ) 

esttab highmig lowmig pdiff using "${tabledir}/Table6_Returns_by_Region.tex", ///
	replace booktabs label wrap b(3) se(3) se star(* .1 ** .05 *** .01) ///
	title(Observational Returns to Migration by Region.) ///
	stats(Individual_FE Year_FE Sample) /// 
	mtitles("log(Cons. PA)"  "log(Cons. PA)" "p: C1 = C2"  ) ///
	nonotes addnotes( ///
"Note: This table presents the estimated coefficients of urban dummy variables" ///
"from regressions of log consumption per adult on urban dummies. Specifications" ///
"are as in Table 3 , Column (4), with year and individual fixed effects," ///
"plus quadratic controls in age and household size, and restricting the sample" ///
"to only those starting from a rural location. The sample is divided by" ///
"the rural-urban migration rate in the origin community, so that there are an" ///
"equal number of rural-urban migrants in each group. Column (2) restricts the" ///
"sample to include households from enumeration areas with rural-urban migration" ///
"rates above the median rate for rural-urban migrants. Column (2) re-" ///
"stricts the sample to include households from enumeration areas with rural-" ///
"urban migration rates below the median rate for rural-urban migrants. Column" ///
"(3) reports the p -value of the difference between the estimates in Column" ///
"(1) and Column (2). Robust standard errors, clustered at the level of the" ///
"wave 1 household, are in parenthesis. $\sym{*} p<.1, \sym{**}p<.05, \sym{***}p<.01$")
