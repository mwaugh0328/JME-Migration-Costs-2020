/*****************************************************************
PROJECT: 		Cross Country Panel Tracking Surveys
				
TITLE:			IFLS_migration.do
			
AUTHOR: 		Sam Marshall, John Mori

DATE CREATED:	12/11/2018

LAST EDITED:	1/31/2019 John Mori

DESCRIPTION: 	Create migration history


ORGANIZATION:	Section 1: IFLS 1
				Section 2: Labels
				
INPUTS: 		
				
OUTPUTS: 		
				
NOTE:			
******************************************************************/

* initiate globals if not done already

label define rur 1 "Village" 3 "Small town" 5 "Big city"

/****************************************************************
	SECTION 1: IFLS1 Migration History
****************************************************************/
* select the sample
use "${IDNraw}/IFLS1/Household/buk3mg2.dta", clear

gen year = 1900 + mg24yr if mg24yr < 95

bysort pidlink: egen first_move = max(movenum) if year <= 1988

* drop moves that occurred before 1988 if there was another one after that.
drop if movenum < first_move & first_move != .

drop if year == .

* if move happened before 88 make that move happen in 88
replace year = 1988 if year < 1988

* when more than one move happened in a year, keep only the last one
bysort pidlink year: egen last_move = max(movenum)
drop if last_move != movenum

* define relevant variables	
rename mg21b2 Kecamatan_ID
rename mg21c2 Kabupatan_ID
rename mg21d2 Province_ID

recode mg26 (6/9 = .), gen(rural)
label values rural rur

gen move_dist = mg27a if mg27a < 9000

rename mg28 move_reason
rename mg29 whose_work

keep pidlink year rural *_ID move* whose_work

gen wave = 1993
	
save "${IDNbuild}/intermediate/IFLS1_migration.dta", replace


/****************************************************************
	SECTION 1: IFLS2 Migration History
****************************************************************/
* select the sample
use "${IDNraw}/IFLS2/Household/b3a_mg2.dta", clear

rename mg24yr year

bysort pidlink: egen first_move = max(movenum) if year <= 1988

* drop moves that occurred before 1988 if there was another one after that.
drop if movenum < first_move & first_move != .

drop if year == .

* if move happened before 88 make that move happen in 88
replace year = 1988 if year < 1988

* when more than one move happened in a year, keep only the last one
bysort pidlink year: egen last_move = max(movenum)
drop if last_move != movenum

* define relevant variables	
rename mg21b Kecamatan_ID
rename mg21c Kabupatan_ID
rename mg21d Province_ID

recode mg26 (6/9 = .), gen(rural)
label values rural rur

gen move_dist = mg27a if mg27a < 9000

rename mg28 move_reason
rename mg29 whose_work

keep pidlink year rural *_ID move* whose_work

gen wave = 1997
	
save "${IDNbuild}/intermediate/IFLS2_migration.dta", replace

/****************************************************************
	SECTION 3: IFLS3 Migration History
****************************************************************/
* select the sample
use "${IDNraw}/IFLS3/Household/b3a_mg2.dta", clear

rename mg24yr year

bysort pidlink: egen first_move = max(movenum) if year <= 1988

* drop moves that occurred before 1988 if there was another one after that.
drop if movenum < first_move & first_move != .

drop if year == .

* if move happened before 88 make that move happen in 88
replace year = 1988 if year < 1988

* when more than one move happened in a year, keep only the last one
bysort pidlink year: egen last_move = max(movenum)
drop if last_move != movenum

* define relevant variables	
rename mg21b Kecamatan_ID
rename mg21c Kabupatan_ID
rename mg21d Province_ID

recode mg26 (6/9 = .), gen(rural)
label values rural rur

gen move_dist = mg27 if mg27 < 99990

rename mg28 move_reason
rename mg29 whose_work

keep pidlink year rural *_ID move* whose_work

gen wave = 2000
	
save "${IDNbuild}/intermediate/IFLS3_migration.dta", replace

/****************************************************************
	SECTION 4: IFLS4 Migration History
****************************************************************/
* select the sample
use "${IDNraw}/IFLS4/Household/b3a_mg2.dta", clear

rename mg24yr year

bysort pidlink: egen first_move = max(movenum) if year <= 1988

* drop moves that occurred before 1988 if there was another one after that.
drop if movenum < first_move & first_move != .

drop if year == .

* if move happened before 88 make that move happen in 88
replace year = 1988 if year < 1988

* when more than one move happened in a year, keep only the last one
bysort pidlink year: egen last_move = max(movenum)
drop if last_move != movenum

* define relevant variables	
rename mg21b Kecamatan_ID
rename mg21c Kabupatan_ID
rename mg21d Province_ID

recode mg26 (6/9 = .), gen(rural)
label values rural rur

gen move_dist = mg27 if mg27 < 99990

rename mg28 move_reason
rename mg29 whose_work

keep pidlink year rural *_ID move* whose_work

gen wave = 2007
	
save "${IDNbuild}/intermediate/IFLS4_migration.dta", replace


/****************************************************************
	SECTION 5: IFLS5 Migration History
****************************************************************/
* select the sample
use "${IDNraw}/IFLS5/Household/b3a_mg2.dta", clear

rename mg24yr year

bysort pidlink: egen first_move = max(movenum) if year <= 1988

* drop moves that occurred before 1988 if there was another one after that.
drop if movenum < first_move & first_move != .

drop if year == .
drop if year == 9998

* if move happened before 88 make that move happen in 88
replace year = 1988 if year < 1988

* when more than one move happened in a year, keep only the last one
bysort pidlink year: egen last_move = max(movenum)
drop if last_move != movenum

* define relevant variables	
rename mg21b Kecamatan_ID
rename mg21c Kabupatan_ID
rename mg21d Province_ID

recode mg26 (6/9 = .), gen(rural)
label values rural rur

gen move_dist = mg27 if mg27 < 99990

rename mg28 move_reason
rename mg29 whose_work

keep pidlink year rural *_ID move* whose_work

gen wave = 2014
	
save "${IDNbuild}/intermediate/IFLS5_migration.dta", replace

/****************************************************************
	SECTION 6: Full Migration History
****************************************************************/

use "${IDNbuild}/intermediate/IFLS1_migration.dta", clear
append using "${IDNbuild}/intermediate/IFLS2_migration.dta"
append using "${IDNbuild}/intermediate/IFLS3_migration.dta"
append using "${IDNbuild}/intermediate/IFLS4_migration.dta"
append using "${IDNbuild}/intermediate/IFLS5_migration.dta"

duplicates drop Kecamatan_ID Kabupatan_ID Province_ID move_reason whose_work ///
	pidlink year rural move_dist, force

rename wave year_reported
gen wave = 1
replace wave = 2 if year > 1993
replace wave = 3 if year > 1997
replace wave = 4 if year > 2000
replace wave = 5 if year > 2007
keep if !mi(movenum)
keep if wave != 1

duplicates drop pidlink wave, force
save "${IDNbuild}/intermediate/IFLS_migration.dta", replace

erase "${IDNbuild}/intermediate/IFLS1_migration.dta"
erase "${IDNbuild}/intermediate/IFLS2_migration.dta"
erase "${IDNbuild}/intermediate/IFLS3_migration.dta"
erase "${IDNbuild}/intermediate/IFLS4_migration.dta"
erase "${IDNbuild}/intermediate/IFLS5_migration.dta"

