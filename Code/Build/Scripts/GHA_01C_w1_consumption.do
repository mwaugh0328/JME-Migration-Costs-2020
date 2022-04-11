/*****************************************************************
PROJECT: 		Rural-Urban Migration 
				
TITLE:			Ghana Build Wave 1 consumption.do
			
AUTHOR: 		Sam Marshall

DATE CREATED:	5/1/2019

LAST EDITED:	5/1/2019

DESCRIPTION: 	Clean Ghana Data and build dataset

ORGANIZATION:	SECTION 1: Food
				SECTION 2: Prices
				SECTION 3: Clothing
				SECTION 4: Other expenditures
				SECTION 5: Fuel
				SECTION 6: Consumption Aggregate
				
INPUTS: 		S11A.dta S11B.dta S11C.dta S11D.dta
				
OUTPUTS: 		int/wave1_consumption
				
NOTE:			
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Food
****************************************************************/
use "${GHAraw}/Wave 1/S11A.dta", clear

local ltrs "b c d e"

* convert expenditures to cedis from cedis and peswas
foreach l of local ltrs {
	replace s11a_`l'iii = s11a_`l'iii / 100
	egen X`l' = rowtotal(s11a_`l'ii s11a_`l'iii), m
	rename s11a_`l'i Q`l'
}

* Qi = quantity, Xi = expenditure
rename (Qb Qc Qd Qe) (Q_prod Q_purch Q_rec Q_gift)
rename (Xb Xc Xd Xe) (X_prod X_purch X_rec X_gift)

preserve

rename (X_prod X_purch X_rec X_gift) (produced purchased received given)

* collapse to one obs per hhold
collapse (sum) produced purchased received given, by(hhno)

egen food = rowtotal(produced purchased received given)

foreach var in produced purchased received given food {
	replace `var' = 12 * `var'
}

label var food "total food expenditure"
label var produced "value of food produced"
label var purchased "value of food purchased"
label var received "value od food received"
label var given "value of food given"

save "${GHAbuild}/intermediate/wave1_food.dta", replace

/****************************************************************
	SECTION 2: Prices
****************************************************************/

restore

* create aggregate expenditures and quantities by item-unit
egen X = rowtotal(X_prod X_purch X_rec X_gift)
egen Q = rowtotal(Q_prod Q_purch Q_rec Q_gift)

rename s11a_f unit
drop s11* food_id

* gen rural urban indicators
merge m:1 hhno using "${GHAraw}/Wave 1/key_hhld_info.dta", keep(match) nogen

gen urban = urbrur == 1
encode itname, gen(food_id)

replace X_purch = 0 if X_purch == .
replace Q_purch = 0 if Q_purch == .
gen N = Q > 0  // number of households who bought item in that unit

* get average expenditure and quantity per hhold for each item-unit combo
collapse (sum) N (mean) X Q X_purch Q_purch, by(food_id unit urban)

keep if unit != .

* drop food-item combos that are very infrequent
bysort food_id unit: egen freq = total(N)

*calculate fraction of total consumption bundle
egen total_cons = sum(N*X), by(urban)
gen cons_frac = N*X/total_cons
drop if freq < 10
egen cons_f = sum(cons_frac), by(urban)
tab cons_f urban //Percentage of food consumption included in index in both regions.

* estimate prices from aggregate avg quantities and expenditures
gen P = X / Q

drop if P == 0 //for combos with no total expenditure


* split out urban and rural prices and quantities
gen P_u = P if urban == 1
gen P_r = P if urban == 0
gen Q_u = Q if urban == 1
gen Q_r = Q if urban == 0

collapse (mean) P_u P_r Q_u Q_r , by(food_id unit)

* calculate top and bottom of Passche and Laspreyes Price index. Urban as base
gen L_top = P_r * Q_u
gen L_bottom = P_u * Q_u
gen P_top = P_r * Q_r
gen P_bottom = P_u * Q_r

//drop if P_r == . | P_u == .

collapse (sum) L_top L_bottom P_top P_bottom

gen P_l = L_top / L_bottom
gen P_p = P_top / P_bottom
gen P_f = sqrt( P_l * P_p)

keep P_f
label var P_f "Fischer relative price of rural consumption"

save "${GHAbuild}/intermediate/wave1_prices.dta", replace


/****************************************************************
	SECTION 2: Clothing
****************************************************************/
use "${GHAraw}/Wave 1/S11B.dta", clear

local ltrs "a b c d e"

* convert expenditures to cedis from cedis and peswas
foreach l of local ltrs {
	replace s11b`l'_2 = s11b`l'_2 / 100
	egen X`l' = rowtotal(s11b`l'_1 s11b`l'_2), m
}

* use the max of total expenditure and sum of categorical expenditures
egen X_sum = rowtotal(Xa Xb Xc Xd)
egen clothing = rowmax (X_sum Xe)

collapse (sum) clothing, by(hhno)

label var clothing "clothing expenditure"

save "${GHAbuild}/intermediate/wave1_clothing.dta", replace

/****************************************************************
	SECTION 3: Other expenditures
****************************************************************/
use "${GHAraw}/Wave 1/S11C.dta", clear

* convert expenditures to cedis from cedis and peswas
replace s11c_2 = s11c_2 / 100

egen other = rowtotal(s11c_1 s11c_2)

collapse (sum) other, by(hhno)

label var other "total other expenditures"

save "${GHAbuild}/intermediate/wave1_other.dta", replace

/****************************************************************
	SECTION 4: Fuel
****************************************************************/
use "${GHAraw}/Wave 1/S11D.dta", clear

foreach l in b d f {
	replace s11d_`l' = s11d_`l' / 100
}
	
egen purchased = rowtotal(s11d_e s11d_f)
egen produced = rowtotal(s11d_c s11d_d)
egen fuel = rowtotal(produced purchased)
egen used = rowtotal(s11d_a s11d_b) 
replace used = used * s11d_1



collapse (sum) fuel, by(hhno)

label var fuel "fuel expenditure"

save "${GHAbuild}/intermediate/wave1_fuel.dta", replace

/****************************************************************
	SECTION 5: Consumption Aggregate
****************************************************************/

use "${GHAbuild}/intermediate/wave1_food.dta", clear
merge 1:1 hhno using "${GHAbuild}/intermediate/wave1_clothing.dta", nogen
merge 1:1 hhno using "${GHAbuild}/intermediate/wave1_other.dta", nogen
merge 1:1 hhno using "${GHAbuild}/intermediate/wave1_fuel.dta", nogen

egen consumption = rowtotal(food clothing other fuel)
label var consumption "total annual expenditure"

foreach var of varlist produced-fuel {
	replace `var' = 0 if mi(`var')
}

save "${GHAbuild}/intermediate/wave1_consumption.dta", replace

* clean up
erase "${GHAbuild}/intermediate/wave1_food.dta" 
* erase "${cons}/prices.dta"
erase "${GHAbuild}/intermediate/wave1_clothing.dta"
erase "${GHAbuild}/intermediate/wave1_other.dta"
erase "${GHAbuild}/intermediate/wave1_fuel.dta"








