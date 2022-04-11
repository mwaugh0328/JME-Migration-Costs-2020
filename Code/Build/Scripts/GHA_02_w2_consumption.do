/*****************************************************************
PROJECT: 		Rural-Urban Migration 
				
TITLE:			Ghana Build Wave 2 consumption
			
AUTHOR: 		Min Byung Chae, Sam Marshall

DATE CREATED:	03/27/2019

LAST EDITED:	04/15/2019

DESCRIPTION: 	Creating consumption metric for wave 2 by item category

ORGANIZATION:	SECTION 0: Set global directory paths
				SECTION 2: Food
				SECTION 3: Prices
				SECTION 3: Clothing
				SECTION 4: Others
				SECTION 5: Fuel
				SECTION 6: Final Consumption Aggregate
				
INPUTS: 		${GHAbuild}/intermediate/fc_clean_s11a.dta (created file)
				s11b.dta s11c.dta s11d.dta comm_matching_nonPII.dta
				
OUTPUTS: 		gha_cons.dta
				
NOTE:			
******************************************************************/

/****************************************************************
	SECTION 0: Set global directory paths
****************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Food
****************************************************************/
* load cleaned food expenditure file. Created by fc_clean_s11a.do
use "${GHAbuild}/intermediate/wave2_s11a_food.dta", clear

* Nomenclature follows X = P Q
rename (producedq purchasedq receivedgiftq givengiftq) (Q_prod Q_purch Q_rec Q_gift)
rename (producedc purchasedc receivedgiftc givengiftc) (X_prod X_purch X_rec X_gift)

drop unit
ren unitcode unit

* get indicator for whether urban or rural area
merge m:1 FPrimary using "${GHAraw}/Wave 2/comm_matching_nonPII", keep(match) nogen

drop if (urbrur_W2 == .)
drop urbrur_W1 commcode_W1 wave

* make expenditures dataset
preserve

rename (X_prod X_purch X_rec X_gift) (produced purchased received given)

* collapse to one obs per hhold
collapse (sum) produced purchased received given, by(FPrimary)

egen food = rowtotal(produced purchased received given)
replace food = food * 12  // make annual

label var food "total food expenditure"
label var produced "value of food produced"
label var purchased "value of food purchased"
label var received "value od food received"
label var given "value of food given"

save "${GHAbuild}/intermediate/wave2_food.dta", replace

/****************************************************************
	SECTION 2: Prices
****************************************************************/

restore

* create aggregate expenditures and quantities by item-unit
egen X = rowtotal(X_prod X_purch X_rec X_gift)
egen Q = rowtotal(Q_prod Q_purch Q_rec Q_gift)

replace X_purch = 0 if X_purch == .
replace Q_purch = 0 if Q_purch == .
gen N = any == 1  // number of households who bought item in that unit

* get average expenditure and quantity per hhold for each item-unit combo
collapse (sum) N (mean) X Q X_purch Q_purch, by(food_id unit urbrur_W2)

keep if unit != .

* drop food-item combos that are very infrequent
bysort food_id unit: egen freq = total(N)
drop if freq < 10

* estimate prices from aggregate avg quantities and expenditures
gen P = X / Q

drop if P == 0 //for combos with no total expenditure

* split out urban and rural prices and quantities
gen P_u = P if urbrur_W2 == 1
gen P_r = P if urbrur_W2 == 2
gen Q_u = Q if urbrur_W2 == 1
gen Q_r = Q if urbrur_W2 == 2

collapse (mean) P_u P_r Q_u Q_r, by(food_id unit)

* calculate top and bottom of Passche and Laspreyes Price index. Urban as base
gen L_top = P_r * Q_u
gen L_bottom = P_u * Q_u
gen P_top = P_r * Q_r
gen P_bottom = P_u * Q_r


collapse (sum) L_top L_bottom P_top P_bottom

gen P_l = L_top / L_bottom
gen P_p = P_top / P_bottom
gen P_f = sqrt( P_l * P_p)

keep P_f
label var P_f "Fischer relative price of rural consumption"


save "${GHAbuild}/intermediate/wave2_prices.dta", replace

/****************************************************************
	SECTION 3: Clothing
****************************************************************/
use "${GHAraw}/Wave 2/11b_clothingquestions.dta", clear

* create id for each clothing type
encode clothingtype, gen(item_id)

merge m:1 FPrimary using "${GHAraw}/Wave 2/comm_matching_nonPII", keep(match) nogen

drop if (urbrur_W2 == .)
drop urbrur_W1 commcode_W1 wave InstanceNumber

recode expendchildren expendelderly expendmale expendfemale expendtotal (.d = .)

egen clothes_sum = rowtotal(expendchildren expendelderly expendmale expendfemale)
egen clothing = rowmax (clothes_sum expendtotal)

collapse (sum) clothing, by(FPrimary)

label var clothing "clothing expenditure"

save "${GHAbuild}/intermediate/wave2_clothing.dta", replace

/****************************************************************
	SECTION 4: Others
****************************************************************/
use "${GHAraw}/Wave 2/11c_otheritems.dta", clear

*Create total expenditure on other 32 items
egen other = rowtotal(remittances-entertainment)

keep FPrimary other

merge m:1 FPrimary using "${GHAraw}/Wave 2/comm_matching_nonPII", keep(match) nogen

drop if (urbrur_W2 == .)
drop urbrur_W1 commcode_W1 wave 

label var other "total other expenditures"

save "${GHAbuild}/intermediate/wave2_others.dta", replace

/****************************************************************
	SECTION 5: Fuel
****************************************************************/
use "${GHAraw}/Wave 2/11d_fuelconsumptionquestions.dta", clear
encode fueltype, gen(fuel_id)

drop if months == 0  // hhold that did not use fuel type

merge m:1 FPrimary using "${GHAraw}/Wave 2/comm_matching_nonPII", keep(match) nogen

drop if (urbrur_W2 == .)

egen fuel = rowtotal(producedcollected purchased)
gen used = averagepermonth*months
gen mistake = (fuel != used)

collapse (sum) fuel, by(FPrimary)

label var fuel "fuel expenditure"

save "${GHAbuild}/intermediate/wave2_fuel.dta", replace

/****************************************************************
	SECTION 6: Final Consumption Aggregate
****************************************************************/
use "${GHAbuild}/intermediate/wave2_food.dta", clear
merge 1:1 FPrimary using "${GHAbuild}/intermediate/wave2_clothing.dta", nogen
merge 1:1 FPrimary using "${GHAbuild}/intermediate/wave2_others.dta", nogen
merge 1:1 FPrimary using "${GHAbuild}/intermediate/wave2_fuel.dta", nogen

egen consumption = rowtotal(food clothing other fuel)
label var consumption "total annual expenditure"
drop if urbrur_W2 == . /* dropping households with unclassified community code or urban-rural status (6 households in total) */
gen urban = urbrur_W2 == 1
drop urbrur_W2
save "${GHAbuild}/intermediate/wave2_consumption.dta", replace

* clean up
erase "${GHAbuild}/intermediate/wave2_food.dta" 
erase "${GHAbuild}/intermediate/wave2_prices.dta"
erase "${GHAbuild}/intermediate/wave2_clothing.dta"
erase "${GHAbuild}/intermediate/wave2_others.dta"
erase "${GHAbuild}/intermediate/wave2_fuel.dta"
