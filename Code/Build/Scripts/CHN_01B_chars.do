/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			A-demog.do		
AUTHORS: 		Sam Marshall, John Mori			
CREATED:		7/1/2019
MODIFIED:		9/4/2019
DESC: 			Create demographic info for each wave of CFPS
ORG:			SECTION 1: Tracker
				SECTION 2: CFPS 2010
				SECTION 3: CFPS 2012
				SECTION 4: CFPS 2014
				SECTION 5: CFPS 2016
INPUTS: 		CFPS_traker_2016.dta CFPS_adult_2010.dta			
OUTPUTS: 		intermediate/traker.dta intermediate/w1_demog.dta			
NOTE:			
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Tracker
****************************************************************/
use "${CHNraw}/2016/CFPS_traker_2016.dta", clear

gen female = gender == 0
	replace female = . if gender == -8
	


forvalues yr = 10(2)16 {
	recode urban`yr' (-9/-1 = .)  // urban status
	rename cfps20`yr'eduy_im educ`yr'  //imputed years of education
	replace marriage_`yr' = . if marriage_`yr' < 0  //marrital status
	replace migrant`yr' = . if migrant`yr' < 0  // migrant status
	
	rename hk`yr' hukou`yr'
	gen non_chinese_`yr' = hukou`yr' == 79
	recode hukou`yr' (-9/-1 5 79 = .)
	
	rename jobstatus_`yr' employed`yr'
		replace employed`yr' = . if employed`yr' < 0
		
	* some name deviations here
	if `yr' == 10 | `yr' == 12 {
		rename fincome1_per_adj`yr' faminc_pc_real`yr'
		capture rename fincome2_per_adj`yr' faminc_pc_nom`yr'
	}
	else {
		rename fincome1_per`yr' faminc_pc_real`yr'
		rename fincome2_per`yr' faminc_pc_nom`yr'
	}
	
	* no income for 2016 in this version
	capture replace income_`yr' = . if income_`yr' < 0
}

egen non_chinese = rowmax(non_chinese_*)
drop non_chinese_*

***** create weights for migration rate in table *****
rename rswt_respn1012 weight12
rename rswt_respn1014 weight14
rename rswt_respn1016 weight16

keep pid female  death_year entrayear urban* educ* hukou* ///
	non_chinese faminc_pc* income* employed* marriage* migrant* weight*

compress
save "${CHNbuild}/intermediate/traker.dta", replace

/****************************************************************
	SECTION 2: CFPS 2010
****************************************************************/
use "${CHNraw}/2010/CFPS_adult_2010.dta", clear

rename qa1age age

*interview date
gen intrv_dt = ym(cyear, cmonth)
format intrv_dt %tm


* might want to limit to only ppl with valid hukou
rename (qa102acode qa102c_code) (birth_province birth_county)

* years of education... a bit tricky
* cap the number of years for each type of school at the max
recode qc703 (-8 = .) (-2/-1 = 6) (7/max = 6), gen(primary)
recode qc603 (-8 = .) (-2/-1 = 3) (4/max = 3), gen(middle)
recode qc503 (-8 = .) (-2/-1 = 3) (4/max = 3), gen(highschool)
recode qc405 (-8 = .) (-2/-1 = 3) (4/max = 3), gen(jrcoll)
recode qc305 (-8 = .) (-2/-1 = 4) (5/max = 4), gen(college)
recode qc205 (-8 = .) (-2/-1 = 3) (4/max = 3), gen(master)
recode qc105 (-8 = .) (-2/-1 = 4) (5/max = 4), gen(phd)

gen educ = 0 if qc1 == 1
	replace educ = primary if qc1 == 2
	replace educ = 6 + middle if qc1 == 3
	replace educ = 9 + highschool if qc1 == 4
	replace educ = 12 + jrcoll if qc1 == 5
	replace educ = 12 + college if qc1 == 6
	replace educ = 16 + master if qc1 == 7
	replace educ = 16 + phd if qc1 == 8
rename educ educ_cons  // give a different name to the one that I construct


egen nadult = count(pid), by(fid)
keep pid fid cid provcd countyid psu nadult age birth* educ   ///
	mathtest wordtest intrv_dt 

compress

merge 1:1 pid using "${CHNbuild}/intermediate/traker.dta", keep(match) nogen

drop *12* *14* *16*
rename *10 *
merge m:1 fid using "${CHNraw}/2010/CFPS_familyecon_2010.dta", ///
	keepusing(indinc)
rename indinc fincome
save "${CHNbuild}/intermediate/w1_demog.dta", replace

/****************************************************************
	SECTION 3: CFPS 2012
****************************************************************/
use "${CHNraw}/2012/CFPS_adult_2012.dta", clear

rename cfps2012_age age
	replace age = . if age < 0

*interview date
gen intrv_dt = ym(cyear, cmonth)
format intrv_dt %tm



* might want to limit to only ppl with valid hukou
rename (qa302ccode qa401ccode) (curr_province birth_province)


egen nadult = count(pid), by(fid12)
keep pid fid12 provcd countyid cid nadult urbancomm ///
	intrv_dt age *province 

compress
merge 1:1 pid using "${CHNbuild}/intermediate/traker.dta", keep(match) nogen
drop *10* *14* *16*
rename *12 *
gen fid12 = fid
merge m:1 fid12 using "${CHNraw}/2012/CFPS_familyecon_2012.dta", ///
	keepusing(fincome2_per_adj)
rename fincome2 fincome
save "${CHNbuild}/intermediate/w2_demog.dta", replace

/****************************************************************
	SECTION 4: CFPS 2014
****************************************************************/
use "${CHNraw}/2014/CFPS_adult_2014.dta", clear

rename cfps2014_age age
	replace age = . if age < 0

*interview date
gen intrv_dt = ym(cyear, cmonth)
format intrv_dt %tm

rename (qa302ccode qa401ccode) (curr_province birth_province)

egen nadult = count(pid), by(fid14)
keep pid fid14 provcd14 countyid14 cid14 nadult intrv_dt age *province
	
compress

merge 1:1 pid using "${CHNbuild}/intermediate/traker.dta", keep(match) nogen
drop *10* *12* *16*
rename *14 *

gen fid14 = fid
merge m:1 fid14 using "${CHNraw}/2014/CFPS_familyecon_2014.dta", ///
	keepusing(fincome2_per)
rename fincome2 fincome
save "${CHNbuild}/intermediate/w3_demog.dta", replace

/****************************************************************
	SECTION 5: CFPS 2016
****************************************************************/
use "${CHNraw}/2016/CFPS_adult_2016.dta", clear

rename cfps_age age
	replace age = . if age < 0

*interview date
gen intrv_dt = ym(cyear, cmonth)
format intrv_dt %tm

rename (pa302ccode pa401ccode) (curr_province birth_province)

egen nadult = count(pid), by(fid16)

rename income income_
keep pid fid16 provcd16  income_ countyid16 cid16 intrv_dt nadult age *province
	
compress

merge 1:1 pid using "${CHNbuild}/intermediate/traker.dta", keep(match) nogen
drop *10* *12* *14*
rename *16 *

gen fid16 = fid
merge m:1 fid16 using "${CHNraw}/2016/CFPS_familyecon_2016.dta", ///
	keepusing(fincome2_per)
rename fincome2 fincome
save "${CHNbuild}/intermediate/w4_demog.dta", replace

