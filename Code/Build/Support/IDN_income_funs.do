/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Indonesia Income Functions		
DESC: 			Create loops called by all indonesia income build files
******************************************************************/

/****************************************************************
	SECTION 1: labels
****************************************************************/
capture label drop rur
capture label drop move_reason

label define rur 1 "Village" 3 "Small town" 5 "Big city"
label define move_reason 1 "work" 2 "education" 4 "family" 5 "other"	

/****************************************************************
	SECTION 2: Income Loops
****************************************************************/

***** create annualized earnings *****
capture program drop annearn
program define annearn
	syntax [, out(string) mon(string) ann(string) wks(string)]
	
	* replace DK and RF with .
	qui replace `mon' = . if substr(string(`mon'),1, 3) == "999"
	capture qui replace `ann' = . if substr(string(`ann'),1, 3) == "999"
	
	* monthly earnings annualized
	qui replace `mon' = `mon' * 12 * `wks' / 52
	
	*annual earnings
	capture qui gen earn_`out' = `ann'  // use annual earnings if inputted
	capture qui gen earn_`out' = `mon' // use monthly earnings if no annual earnings supplied
		qui replace earn_`out' = `mon' if mi(earn_`out') 
end

***** creating annualized hours *****
capture program drop annhours
program define annhours
	syntax [, out(string) hrs(string) wks(string) last(string) lowcap(integer 1)]
	
	* replace DK and RF with .
	replace `wks' = . if `wks' > 52
	if `lowcap' == 1 {
		replace `hrs' = . if `hrs' >= 95 
		capture replace `last' = . if `last' >= 95 
	} 
	else {
		replace `hrs' = . if `hrs' >= 24 * 7 
		capture replace `last' = . if `last' >= 24 * 7
	}
	gen ahrs_`out' = `hrs' * `wks'

end
