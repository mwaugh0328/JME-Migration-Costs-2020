/*****************************************************************
PROJECT: 		Cross Country Panel Tracking Surveys		
TITLE:			A-urban.do		
AUTHOR: 		Min Byung Chae, Sam Marshall
CREATED:		6/17/2019
MODIFIED:		7/30/2019 
DESC: 			Create education and other main demographic variables
ORG:				SECTION 1: Traker file
						SECTION 2: IFLS 1-2
						SECTION 3: IFLS 3-5			
INPUTS: 		buk3mg2.dta buk3mg1.dta				
OUTPUTS: 	IFLS*_urban.dta				
NOTE:		urban codes: 1 = village; 3 = small town; 5 = big city; 8 = DK
*label define move_reason 1 "Work-related" 2 "Education/training-related" ///
	3 "Military career-related" 4 "Family-related" 5 "Other" 6 "Urban" 7 "Force"	
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: IFLS1
****************************************************************/
forvalues i = 1/2 {
* make the file stub
	if (`i' == 1) local stub buk3
	if (`i' == 2) local stub b3a_
	
	use "${IDNraw}/IFLS`i'/Household/`stub'mg2.dta", clear  // migration history

*keep only the most recent move
	bysort pidlink: egen last_move = max(movenum)
	keep if movenum == last_move

	replace mg26 = . if ~inlist(mg26, 1, 3, 5)
	rename mg26 urban_det

	gen move_dist = mg27a if mg27a < 9000

	rename mg29 whose_work
	gen own_work = whose_work == 1

	if (`i' == 1) recode mg28 (3 9 = 5), gen(move_reason)
	if (`i' == 2) recode mg28 (3 14/23 98 = 5) (5/13 24 = 4), gen(move_reason)

	keep pidlink urban_det move_dist  move_reason whose_work own_work

	* merge in birth and age 12 location information
	merge 1:1 pidlink using "${IDNraw}/IFLS`i'/Household/`stub'mg1.dta"

	replace mg04 = . if ~inlist(mg04, 1, 3, 5)
	replace mg08 = . if ~inlist(mg08, 1, 3, 5)

	rename (mg04 mg08) (born_urban_det age12_urban_det)

	replace urban_det = age12_urban_det if urban_det == .
	replace urban_det = born_urban_det if urban_det == .

	keep pidlink urban_det age12 born move_dist  move_reason whose_work own_work
	
	if (`i' == 1) gen wave = 1993
	if (`i' == 2) gen wave = 1997
	
	save "${IDNbuild}/intermediate/IFLS`i'_urban.dta", replace
}

/****************************************************************
	SECTION 1: IFLS3-5
****************************************************************/
forvalues i = 3/5 {
	use "${IDNraw}/IFLS`i'/Household/b3a_mg2.dta", clear  // migration history

*keep only the most recent move
	bysort pidlink: egen last_move = max(movenum)
	keep if movenum == last_move

	replace mg26 = . if ~inlist(mg26, 1, 3, 5)
	rename mg26 urban_det

	gen move_dist = mg27 if mg27 < 9000

	rename mg29 whose_work
	gen own_work = whose_work == 1

	if (`i' == 3) recode mg28 (3 14/21 23 99 = 5) (5/13 22 24 = 4), gen(move_reason)
	if (`i' == 4) recode mg28 (3 14/21 23 25 95 99 = 5) (5/13 22 24 = 4), gen(move_reason)
	if (`i' == 5) recode mg28 (3 14/21 23 25 95 99 = 5) (5/13 22 24 = 4), gen(move_reason)

	keep pidlink urban_det move_dist  move_reason whose_work own_work

* merge in birth and age 12 location information
	merge 1:1 pidlink using "${IDNraw}/IFLS`i'/Household/b3a_mg1.dta"

	replace mg04 = . if ~inlist(mg04, 1, 3, 5)
	replace mg08 = . if ~inlist(mg08, 1, 3, 5)

	rename (mg04 mg08) (born_urban_det age12_urban_det)

	replace urban_det = age12_urban_det if urban_det == .
	replace urban_det = born_urban_det if urban_det == .

	keep pidlink urban_det age12 born move_dist  move_reason whose_work own_work
	
	if (`i' == 3) gen wave = 2000
	if (`i' == 4) gen wave = 2007
	if (`i' == 5) gen wave = 2014
	
	save "${IDNbuild}/intermediate/IFLS`i'_urban.dta", replace
}

