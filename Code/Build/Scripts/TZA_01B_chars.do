/*****************************************************************
PROJECT: 		Rural-Urban Migration 
				
TITLE:			Build Tanzania characteristics 
			
AUTHORS: 		Sam Marshall, Hannah Moreno, John Mori, Sebastian Quaade

DATE CREATED:	05/14/2019

DESCRIPTION: 	Clean Tanzania demographic data

ORGANIZATION:	SECTION 1: Wave 1
				SECTION 2: Wave 2
				SECTION 3: Wave 3
				
INPUTS: 		s1d.dta s1fi.dta s6a.dta
				
OUTPUTS: 		gha_clean_new.dta

NOTE:			Intermediary outputs: wave1_demog.dta wave1_edu.dta
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 0: Education Function
****************************************************************/

/*This recoding of the schoolyears variable is based on information provided
in the 2012-2013 BID found in the Sebastian/RAW DATA/Wave 3 2012-2013 folder,
and information from https://www.nuffic.nl/en/publications/find-a-publication/education-system-tanzania.pdf
Please refer to these to see if these match your expectations and use.*/
capture program drop edurecode
program define edurecode
	qui replace educ = educ_curr if inschool == 1
	qui replace educ = educ_last if inschoollast == 1 & inschool == 0 & ~mi(educ)
	qui replace attsch = 0 if age < 7
	qui replace educ = 0 if attsch == 0 | age < 7  //don't start school prior to 7
	
	qui recode educ (1 2=0) (11=1) (12=2) (13=3) (14=4) (15=5) (16=6) (17/19=7) ///
		(20 21=8) (22=9) (23=10) (24=11) (25 31=12) (32 34=13) (33 41=14) ///
		(42=15) (43=16) (44=17) (45=18)
end

/****************************************************************
*****************************************************************
	SECTION 1: Wave 1
*****************************************************************
****************************************************************/

/****************************************************************
	SECTION 1.1: Demographics
****************************************************************/

use "${TZAraw}/Wave 1 2008-2009/SEC_B_C_D_E1_F_G1_U.dta", clear

rename (sbq4 sbq5) (age relat)

gen female = sbq2 == 2

/****************************************************************
	SECTION 1.2: Education
****************************************************************/

rename scq2 attsch
rename scq4 inschool
rename scq5 inschoollast
rename scq6 educ
rename scq7 educ_curr
rename scq8 educ_last

edurecode // program to recode educ variable

/****************************************************************
	SECTION 1.3: Variables for use in moving cost
****************************************************************/

* value of items in self employment
rename (seq32 seq33 seq34) (value_capital value_inputs value_finalgoods)

rename sbq9 monthsaway
rename sbq26 movereason


keep hhid sbmemno female age relat educ  monthsaway movereason 

save "${TZAbuild}/intermediate/wave1_indiv_chars.dta", replace

/****************************************************************
	SECTION 1.4: Household level vars
****************************************************************/

use "${TZAraw}/Wave 1 2008-2009/SEC_A_T.dta", clear

merge 1:1 hhid using "${TZAraw}/Wave 1 2008-2009/HH.Geovariables_Y1.dta"


gen urban = rural == "Urban"

rename thhmem hh_size
rename hh_weight weight

rename st2q1 any_ag
recode any_ag (2 4 = 0)

gen intrv_dt = ym( sa2q18y, sa2q18m)
format intrv_dt %tm


tempfile hh
save `hh'




rename *_modified *

keep hhid urban weight district ward locality clusterid ea region intrv_dt any_ag lat lon

/****************************************************************
	SECTION 1.5: Clean up
****************************************************************/

merge 1:m hhid using "${TZAbuild}/intermediate/wave1_indiv_chars.dta", nogen

save "${TZAbuild}/intermediate/wave1_chars.dta", replace

erase "${TZAbuild}/intermediate/wave1_indiv_chars.dta"

/****************************************************************
*****************************************************************
	SECTION 2: Wave 2
*****************************************************************
****************************************************************/

/****************************************************************
	SECTION 2.1: Demographics
****************************************************************/

use "${TZAraw}/Wave 2 2010-2011/HH_SEC_B.dta", clear

rename (hh_b04 hh_b05) (age relat)

gen female = hh_b02 == 2


rename (hh_b10 hh_b27) (monthsaway movereason)

keep y2_hhid indidy2 age relat female  monthsaway movereason

save "${TZAbuild}/intermediate/wave2_demog.dta", replace

/****************************************************************
	SECTION 2.2: Education
****************************************************************/

use "${TZAraw}/Wave 2 2010-2011/HH_SEC_C.dta", clear

* make a proxy for indiv at least 7 years old
recode hh_c01 (1 = 10) (2 = 0), gen(age)

rename hh_c03 attsch
rename hh_c05 inschool
rename hh_c06 inschoollast
rename hh_c07 educ
rename hh_c09 educ_curr
rename hh_c10 educ_last

edurecode // program to recode educ variable
label drop hh_c07

keep y2_hhid indidy2 educ

save "${TZAbuild}/intermediate/wave2_educ.dta", replace

/****************************************************************
	SECTION 2.3: Variables for use in moving cost
****************************************************************/


/****************************************************************
	SECTION 2.4: Household level vars
****************************************************************/

use "${TZAraw}/Wave 2 2010-2011/HH_SEC_A.dta", clear
merge 1:1 y2_hhid using "${TZAraw}/Wave 2 2010-2011/HH.Geovariables_Y2.dta"

rename y2_weight weight

gen urban = y2_rural == 0

gen intrv_dt = ym(hh_a18_year, hh_a18_month)
format intrv_dt %tm


save `hh', replace


rename *_modified *
keep y2_hhid urban  weight district ward ea region intrv_dt  ///
	 lat lon //
	

/****************************************************************
	SECTION 2.5: Clean up
****************************************************************/

merge 1:m y2_hhid using "${TZAbuild}/intermediate/wave2_demog.dta", nogen
merge 1:1 y2_hhid indidy2 using "${TZAbuild}/intermediate/wave2_educ.dta", nogen

save "${TZAbuild}/intermediate/wave2_chars.dta", replace

erase "${TZAbuild}/intermediate/wave2_demog.dta"
erase "${TZAbuild}/intermediate/wave2_educ.dta"


/****************************************************************
*****************************************************************
	SECTION 3: Wave 3
*****************************************************************
****************************************************************/

/****************************************************************
	SECTION 3.1: Demographics
****************************************************************/

use "${TZAraw}/Wave 3 2012-2013/HH_SEC_B.dta", clear

rename (hh_b04 hh_b05) (age relat)

gen female = hh_b02 == 2


rename (hh_b10 hh_b28) (monthsaway movereason)

keep y3_hhid indidy3 age relat female  monthsaway movereason

save "${TZAbuild}/intermediate/wave3_demog.dta", replace

/****************************************************************
	SECTION 3.2: Education
****************************************************************/

use "${TZAraw}/Wave 3 2012-2013/HH_SEC_C.dta", clear

* make a proxy for indiv at least 7 years old
recode hh_c01 (1 = 10) (2 = 0), gen(age)

rename hh_c03 attsch
rename hh_c05 inschool
rename hh_c06 inschoollast
rename hh_c07 educ
rename hh_c09 educ_curr
rename hh_c10 educ_last

edurecode // program to recode educ variable
label drop hh_c07

keep y3_hhid indidy3 educ

save "${TZAbuild}/intermediate/wave3_educ.dta", replace


/****************************************************************
	SECTION 3.4: Household level vars
****************************************************************/

use "${TZAraw}/Wave 3 2012-2013/HH_SEC_A.dta", clear
merge 1:1 y3_hhid using "${TZAraw}/Wave 3 2012-2013/HouseholdGeovars_Y3.dta"

rename lat* lat
rename lon* lon

rename y3_weight weight

gen urban = y3_rural == 0

rename (hh_a01_1 hh_a02_1 hh_a03_1 hh_a04_1) (region district ward ea)

gen intrv_dt = ym(hh_a18_3, hh_a18_2)
format intrv_dt %tm


tempfile hh
save `hh'


keep y3_hhid urban weight district y3_cluster ward ea region intrv_dt lat lon
	
/****************************************************************
	SECTION 3.5: Clean up
****************************************************************/
	
merge 1:m y3_hhid using "${TZAbuild}/intermediate/wave3_demog.dta", nogen
merge 1:1 y3_hhid indidy3 using "${TZAbuild}/intermediate/wave3_educ.dta", nogen

save "${TZAbuild}/intermediate/wave3_chars.dta", replace

erase "${TZAbuild}/intermediate/wave3_demog.dta"
erase "${TZAbuild}/intermediate/wave3_educ.dta"


