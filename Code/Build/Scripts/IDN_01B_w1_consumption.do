/*****************************************************************
PROJECT: 	Rural-Urban Migration 			
TITLE:		Build Indonesia Consumption		
AUTHORS: 	Min Byung Chae, Sam Marshall
CREATED: 	6/10/2019
MODIFIED:	7/22/2019 
DESC: 		Create a consumption aggregate for Indonesia 
ORG:		SECTION 1: Food Transfers
			SECTION 2: Education
			SECTION 3: Weekly Food Expenditure
			SECTION 4: Monthly Non-Food
			SECTION 5: Yearly Non-Food
			SECTION 6: Monthly housing
			SECTION 7: Urban-Rural Indicator
			SECTION 8: Household Size
			SECTION 9: Merging the Datasets
INPUTS: 	b1_ks0.dta, buk1ks1.dta, b1_ks2.dta, b1_ks3.dta, buk1kr1.dta			
OUTPUT: 	"${build}/IFLS1_consumption.dta"			
NOTE:		Waves 2-5 are run in a loop
******************************************************************/

* initiate globals if not done already

********* Wave 1 ***************************************************************

/****************************************************************
	SECTION 1: buk1ks2a.dta (Food Transfers) **past week**
	Food transfers = food received - food given
****************************************************************/
use "${IDNraw}/IFLS1/Household/buk1ks2a.dta", clear 
ren (ks04a1 ks04b1) (received given)
replace received = . if received >= 995995
replace given = . if given >= 995995
replace given = -1 * given
egen food_transfers = rowtotal(received given)
keep hhid93 food_transfers
label var food_transfers "weekly food transfers (net)"
save "${IDNbuild}/intermediate/food_transfers.dta", replace

/****************************************************************
	SECTION 2: buk1ks3b.dta (Education) **monthly and annual**
****************************************************************/
use "${IDNraw}/IFLS1/Household/buk1ks3b.dta", clear 
foreach var of varlist ks10a1-ks12b1 {
	replace `var' = . if `var' >= 999995
}

* make expenditure annual (boarding is monthly in the questionaire so assume that is the value here)
foreach var of varlist ks10a1 ks10b1 ks12b1 {
	replace `var' = 12* `var' 
}

egen educ = rowtotal(ks10a1-ks12b1)
label var educ "annual education expenditure"
keep hhid93 educ
save "${IDNbuild}/intermediate/educ.dta", replace

/****************************************************************
	SECTION 3: buk1ks1.dta (Weekly Food)
****************************************************************/
use "${IDNraw}/IFLS1/Household/buk1ks1.dta", clear 
ren (ks02rp ks03rp) (consumed produced) 
replace consumed = . if consumed >= 999995 
replace produced = . if produced >= 999995
collapse (sum) produced consumed, by(hhid93)
egen food_c = rowtotal(produced consumed)
label var food_c "weekly food expenditure"
keep hhid93 food_c
save "${IDNbuild}/intermediate/weekly_food.dta", replace

/****************************************************************
	SECTION 4: buk1ks2b.dta (Monthly Non-Food)
****************************************************************/
use "${IDNraw}/IFLS1/Household/buk1ks2b.dta", clear  
rename ks06rp nonfood_m
replace nonfood = . if nonfood >= 999995
collapse (sum) nonfood, by(hhid93)
label var nonfood_m "monthly non-food expenditure"
save "${IDNbuild}/intermediate/nonfood.dta", replace

/****************************************************************
	SECTION 5: buk1ks3a.dta (Yearly Non-Food)
****************************************************************/
use "${IDNraw}/IFLS1/Household/buk1ks3a.dta", clear 
rename ks08rp nonfood_ann
replace nonfood = . if nonfood >= 9899995
collapse (sum) nonfood, by(hhid93)
label var nonfood_ann "annual non-food expenditure"
save "${IDNbuild}/intermediate/nonfood2.dta", replace

/****************************************************************
	SECTION 6: buk1kr1.dta (Monthly housing)
****************************************************************/
use "${IDNraw}/IFLS1/Household/buk1kr1.dta", clear
egen rent = rowtotal(kr04r1 kr05r1)
label var rent "monthly housing expenditure"
replace rent = . if rent >= 999995
keep hhid93 rent
save "${IDNbuild}/intermediate/rent.dta", replace

/****************************************************************
	SECTION 7: bukksc1.dta (Urban-Rural Indicator)
****************************************************************/
use "${IDNraw}/IFLS1/Household/bukksc1.dta", clear

tostring sc01, gen(provid)
label var provid "Code of Province"

tostring sc02, gen(kabid)
replace kabid = "0" + kabid if length(kabid) == 1
replace kabid = provid + kabid
label var kabid "Code of Province + Kabupatan"
gen ea = sc07

tostring sc03, gen(kecid)
replace kecid = "0" + kecid if length(kecid) == 2
replace kecid = kabid + kecid
label var kecid "Code of Province + Kabupatan + Kecamatan"

gen urban_hhld = sc05 == 1
lab var urban_hhld "urban/rural indicator: household"

keep hhid93 *id urban_hhld ea
drop hhid

save "${IDNbuild}/intermediate/geo.dta", replace 

/****************************************************************
	SECTION 8: bukkar1.dta (Household Size)
****************************************************************/
use hhid93 hhldsize using "${IDNraw}/IFLS1/Household/bukkar1.dta", clear
ren hhldsize hhsize
save "${IDNbuild}/intermediate/hhsize.dta", replace

/****************************************************************
	SECTION 9: Merging the Datasets
****************************************************************/
merge 1:1 hhid93 using "${IDNbuild}/intermediate/geo.dta", nogen
merge 1:1 hhid93 using "${IDNbuild}/intermediate/food_transfers.dta", nogen
merge 1:1 hhid93 using "${IDNbuild}/intermediate/educ.dta", nogen
merge 1:1 hhid93 using "${IDNbuild}/intermediate/weekly_food.dta", nogen
merge 1:1 hhid93 using "${IDNbuild}/intermediate/nonfood.dta", nogen
merge 1:1 hhid93 using "${IDNbuild}/intermediate/nonfood2.dta", nogen
merge 1:1 hhid93 using "${IDNbuild}/intermediate/rent.dta", nogen


*make food expenditures all annual
replace food_c = 52 * food_c
replace food_transfers = 52 * food_transfers
replace nonfood_m = 12 * nonfood_m
replace rent = 12 * rent

egen food = rowtotal(food_c food_transfers)
egen nonfood = rowtotal(educ nonfood_m nonfood_ann rent)
egen consumption = rowtotal(food nonfood)
gen food_share = food/consumption
keep hhid93 hhsize *id urban food nonfood food_share consumption
rename hhid93 hhid

save "${IDNbuild}/intermediate/IFLS1_consumption.dta", replace

erase "${IDNbuild}/intermediate/hhsize.dta"
erase "${IDNbuild}/intermediate/geo.dta"
erase "${IDNbuild}/intermediate/food_transfers.dta"
erase "${IDNbuild}/intermediate/educ.dta"
erase "${IDNbuild}/intermediate/weekly_food.dta"
erase "${IDNbuild}/intermediate/nonfood.dta"
erase "${IDNbuild}/intermediate/nonfood2.dta"
erase "${IDNbuild}/intermediate/rent.dta"

********* Wave 2 - 5 ***********************************************************


/****************************************************************
	SECTION 1 b1_ks0.dta (Food Transfers, Self-Produced/Received Non-Food, Education)
	ks04b: past week
	ks07a: last month
	ks10/11/12: last year
****************************************************************/
forvalues i = 2/5 {
	if (`i' == 2) local yr = "97"
	if (`i' == 3) local yr = "00"
	if (`i' == 4) local yr = "07"
	if (`i' == 5) local yr = "14"
	use "${IDNraw}/IFLS`i'/Household/b1_ks0.dta", clear
	drop *x
	ren (ks07a ks04b) (received given)
	replace received = 12 * received
	replace given = -1 * 52 * given
	egen food_transfers = rowtotal(received given)

	egen educ = rowtotal(ks10aa-ks12bb)

	keep hhid`yr' food_transfers educ
	label var food_transfers "annual food transfers (net)"
	label var educ "annual education expenditure"
	save "${IDNbuild}/intermediate/food_transfers_`i'.dta", replace

/****************************************************************
	SECTION 2: b1_ks1.dta (Weekly Food)
****************************************************************/

	use "${IDNraw}/IFLS`i'/Household/b1_ks1.dta", clear
	ren (ks02 ks03) (consumed produced) 
	collapse (sum) produced consumed, by(hhid`yr')
	egen food_c = rowtotal(produced consumed)
	label var food_c "weekly food expenditure"
	keep hhid food_c
	save "${IDNbuild}/intermediate/weekly_food_`i'.dta", replace

/****************************************************************
	SECTION 3: b1_ks2.dta (Monthly Non-Food)
****************************************************************/
	use "${IDNraw}/IFLS`i'/Household/b1_ks2.dta", clear 
	rename ks06 nonfood_m
	collapse (sum) nonfood, by(hhid`yr')
	label var nonfood_m "monthly non-food expenditure"
	save "${IDNbuild}/intermediate/nonfood_`i'.dta", replace

/****************************************************************
	SECTION 4: b1_ks3.dta (Yearly Non-Food)
****************************************************************/
	use "${IDNraw}/IFLS`i'/Household/b1_ks3.dta", clear 
	rename ks08 nonfood_purch
	rename ks09a nonfood_prod
	egen nonfood_ann = rowtotal(nonfood_purch nonfood_prod)
	collapse (sum) nonfood_ann, by(hhid`yr')
	label var nonfood_ann "annual non-food expenditure"
	save "${IDNbuild}/intermediate/nonfood2_`i'.dta", replace

/****************************************************************
	SECTION 5: b2_kr.dta (Monthly housing)
****************************************************************/
	use "${IDNraw}/IFLS`i'/Household/b2_kr.dta", clear
	if (`i' <= 3) egen rent = rowtotal(kr04 kr05)
	if (`i' >= 4) egen rent = rowtotal(kr04a kr05a)
	label var rent "monthly housing expenditure"
	keep hhid`yr' rent
	save "${IDNbuild}/intermediate/rent_`i'.dta", replace

/****************************************************************
	SECTION 6: bk_sc1.dta (Urban-Rural Indicator)
****************************************************************/
	if `i' < 5 {
		use "${IDNraw}/IFLS`i'/Household/bk_sc.dta", clear 
	}
	else {
		use "${IDNraw}/IFLS`i'/Household/bk_sc1.dta", clear 
	}
	
	capture label drop prov
	capture drop sc*0700 // two options in 2007
	tostring sc01, gen(provid)
	label var provid "Code of Province"

	tostring sc02, gen(kabid)
	replace kabid = "0" + kabid if length(kabid) == 1
	replace kabid = provid + kabid
	label var kabid "Code of Province + Kabupatan"

	tostring sc03, gen(kecid)
	replace kecid = "0" + kecid if length(kecid) == 2
	replace kecid = kabid + kecid	
	label var kecid "Code of Province + Kabupatan + Kecamatan"

	gen urban_hhld = sc05 == 1
	lab var urban_hhld "urban/rural indicator: household"

	if (`i' >= 3) rename sc21x mover`yr'
	keep hhid`yr' *id urban_hhld mover`yr'

	save "${IDNbuild}/intermediate/geo_`i'.dta", replace 

/****************************************************************
	SECTION 7: bk_ar0.dta (Household Size)
****************************************************************/
	
	if (`i' < 5) {
		use hhid`yr' hhsize using "${IDNraw}/IFLS`i'/Household/bk_ar0.dta", clear
		*keep hhid`yr' hhsize
	}
	else {
		use "${IDNraw}/IFLS`i'/Household/bk_ar1.dta", clear
		gen hhsize = inlist(ar01a, 1, 2, 5, 11)
		collapse (sum) hhsize, by(hhid`yr')
	}
	save "${IDNbuild}/intermediate/hhsize_`i'.dta", replace
/****************************************************************
	SECTION 8: Merging the Datasets
****************************************************************/
	merge 1:1 hhid`yr' using "${IDNbuild}/intermediate/geo_`i'.dta", nogen
	merge 1:1 hhid`yr' using "${IDNbuild}/intermediate/food_transfers_`i'.dta", nogen
	merge 1:1 hhid`yr' using "${IDNbuild}/intermediate/weekly_food_`i'.dta", nogen
	merge 1:1 hhid`yr' using "${IDNbuild}/intermediate/nonfood_`i'.dta", nogen
	merge 1:1 hhid`yr' using "${IDNbuild}/intermediate/nonfood2_`i'.dta", nogen
	merge 1:1 hhid`yr' using "${IDNbuild}/intermediate/rent_`i'.dta", nogen

*make food expenditures all annual
	replace food_c = 52 * food_c
	replace nonfood_m = 12 * nonfood_m
	replace rent = 12 * rent

	egen food = rowtotal(food_c food_transfers)
	egen nonfood = rowtotal(educ nonfood_m nonfood_ann rent)
	egen consumption = rowtotal(food nonfood)
	gen food_share = food/consumption
	rename hhid`yr' hhid
	keep hhid hhsize *id urban mover`yr' food nonfood food_share consumption

	save "${IDNbuild}/intermediate/IFLS`i'_consumption.dta", replace

	erase "${IDNbuild}/intermediate/hhsize_`i'.dta"
	erase "${IDNbuild}/intermediate/geo_`i'.dta"
	erase "${IDNbuild}/intermediate/food_transfers_`i'.dta"
	erase "${IDNbuild}/intermediate/weekly_food_`i'.dta"
	erase "${IDNbuild}/intermediate/nonfood_`i'.dta"
	erase "${IDNbuild}/intermediate/nonfood2_`i'.dta"
	erase "${IDNbuild}/intermediate/rent_`i'.dta"
}

