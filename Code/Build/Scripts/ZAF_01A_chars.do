/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Build South Africa demographics	
AUTHORS: 		Sam Marshall, Liana Wang, Sebastian Quaade			
VERSION:		2.0.1
CREATED:		7/9/2019
DESC: 			Create demographic info for each wave of South Africa
ORG:			SECTION 1: Adult and Proxy info
				SECTION 2: Household info and consumption
				SECTION 3: Clean Up			
INPUTS: 				
OUTPUTS: 		wavei_chars.dta			
NOTE:			
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Adult and Proxy info
****************************************************************/
forvalues i = 1/5 {
	use "${ZAFraw}/Wave `i'/Adult_W`i'.dta", clear
	rename w`i'_a_* w`i'_p_*
	append using "${ZAFraw}/Wave `i'/Proxy_W`i'.dta"
	rename w`i'_p_* *
	keep if outcome == 1

	gen intrv_dt = mdy( intrv_m, intrv_d, intrv_y)
	format intrv_dt %td
	
	* move variable changes
	if `i' == 2 {
		rename (mvprovy mvtwny) (move_province move_city)
	}
	else {
		rename moveyr move_year
	}
	
	capture rename marstt marr_stat

	rename (lng brnprov brncc brndc_2001 brndc_2011) ///
		(language birth_prov birth_country birth_district2001 birth_district_2011)
	
	keep pid language mar* move_* birth* intrv_dt

	merge 1:1 pid using "${ZAFraw}/Wave `i'/indderived_W`i'.dta", keep(match) nogen
	rename w`i'_* *
	drop if quest_typ == 2 // child interviews

	gen female = best_gen == 2

	rename (best_race best_age_yrs) (race age)

	replace age = . if age < 0

	//Recode years of education
	recode best_edu (-9/-1 24 = .) (13 27 30 = 9) (14 28 31 = 10) (15 29 32 55 = 11) (16 = 12) ///
		(17 18 = 13) (19 = 14) (20 21 = 15) (22 = 16) (23 = 17) (25 = 0), gen(educ)
	replace educ = 0 if educ == . & age < 5
	
	capture rename best_marstt marr_stat
	
	//Create adult equivalence variable according to scale given in Tanzania Wave 3 BID.
	gen ae = .
	replace ae = 0.40 if inrange(age,0,2)
	replace ae = 0.48 if inrange(age,3,4)
	replace ae = 0.56 if inrange(age,5,6) 
	replace ae = 0.64 if inrange(age,7,8)
	replace ae = 0.76 if inrange(age,9,10)
	replace ae = 0.88 if inrange(age,11,12) & female==1
	replace ae = 0.80 if inrange(age,11,12) & female==0
	replace ae = 0.84 if inrange(age,11,12) & female==.
	replace ae = 1.00 if inrange(age,13,14)
	replace ae = 1.00 if inrange(age,15,18) & female==1
	replace ae = 1.20 if inrange(age,15,18) & female==0
	replace ae = 1.10 if inrange(age,15,18) & female==.
	replace ae = 0.88 if inrange(age,19,59) & female==1
	replace ae = 1.00 if inrange(age,19,59) & female==0
	replace ae = 0.94 if inrange(age,19,59) & female==.
	replace ae = 0.72 if inrange(age,60,999) & female==1
	replace ae = 0.80 if inrange(age,60,999) & female==0
	replace ae = 0.76 if inrange(age,60,999) & female==.
	assert ae!=. if age!=.
	bys hhid: egen adulteq = total(ae), missing
	
	keep hhid pid quest_typ female race age educ language marr_stat move_* birth* intrv_dt adulteq

	save "${ZAFbuild}/intermediate/wave`i'_indiv.dta", replace
}

/****************************************************************
	SECTION 2: Household info and consumption
****************************************************************/

* data on household assets starting in wave 2
forvalues i = 1/5 {	
	use "${ZAFraw}/Wave `i'/hhderived_W`i'.dta", clear
	rename w`i'_* *
	gen urban = geo2011 == 2
	
	rename hhsizer hhsize
	rename (expenditure expf expnf) (consumption food_consumption nonfood_consumption) 
	
	if `i' == 1 {
		replace dwgt = dtwgt
		keep hhid urban hhsize consumption* prov* dc* mdbdc2011 cluster hhincome ///
			dwgt *food* 
		rename hhid w1_hhid
		merge 1:1 w1_hhid using "${ZAFraw}/Wave 1/hhQuestionnaire_W1.dta"
		rename w1_h_* *
		rename w1_hhid hhid 
		keep hhid urban hhsize consumption* prov* dc* mdbdc2011 cluster hhincome dwgt *food* 
		save "${ZAFbuild}/intermediate/wave`i'_hhold.dta", replace
	}
	else if `i' == 3 {
		ren hhid w3_hhid
		merge 1:1 w3_hhid using "${ZAFraw}/Wave 3/hhQuestionnaire_W3.dta"
		rename w3_h_* *
		ren w3_hhid hhid
		keep hhid urban hhsize consumption* *food* prov* dc* mdbdc2011 hhincome dwgt
		save "${ZAFbuild}/intermediate/wave`i'_hhold.dta", replace
	}
	else if `i' == 2 {
		ren hhid w2_hhid
		merge 1:1 w2_hhid using "${ZAFraw}/Wave 2/hhQuestionnaire_W2.dta"
		rename w2_h_* *
		ren w2_hhid hhid
		keep hhid urban hhsize consumption* *food* prov* dc* mdbdc2011 hhincome dwgt  
		save "${ZAFbuild}/intermediate/wave`i'_hhold.dta", replace
	}
	else if `i' == 5 {
		ren hhid w5_hhid
		drop sample intrv_c
		merge 1:1 w5_hhid using "${ZAFraw}/Wave 5/hhQuestionnaire_W5.dta"
		rename w5_h_* *
		ren w5_hhid hhid
		keep hhid urban hhsize consumption* *food* prov* dc* mdbdc2011 hhincome dwgt 
		save "${ZAFbuild}/intermediate/wave5_hhold.dta", replace
	}
	else {
		ren hhid w`i'_hhid
		merge 1:1 w`i'_hhid using "${ZAFraw}/Wave `i'/hhQuestionnaire_W`i'.dta"
		ren w`i'_h_* *
		ren w`i'_hhid hhid
		keep hhid urban hhsize consumption* *food* prov* dc* mdbdc2011 hhincome dwgt 
		save "${ZAFbuild}/intermediate/wave`i'_hhold.dta", replace
	}
}

/****************************************************************
	SECTION 3: Clean Up
****************************************************************/
forvalues i = 1/5 {	
	use "${ZAFbuild}/intermediate/wave`i'_indiv.dta", clear
	merge m:1 hhid using "${ZAFbuild}/intermediate/wave`i'_hhold.dta", keep(match) nogen
	save "${ZAFbuild}/intermediate/wave`i'_chars.dta", replace
	erase "${ZAFbuild}/intermediate/wave`i'_indiv.dta"
	erase "${ZAFbuild}/intermediate/wave`i'_hhold.dta"
}

