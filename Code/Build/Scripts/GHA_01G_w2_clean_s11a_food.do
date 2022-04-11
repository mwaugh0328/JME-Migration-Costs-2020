/*****************************************************************
PROJECT: 		Rural-Urban Migration 
				
TITLE:			Ghana Clean Food Consumption Wave 2.do
			
AUTHOR: 		Sam Marshall

DATE CREATED:	04/29/2019

LAST EDITED:	04/29/2019

DESCRIPTION: 	Clean data in food consumption module

ORGANIZATION:	SECTION 0: Set global directory paths
				SECTION 1: Adjustments
				SECTION 2: Notes
				
INPUTS: 		Wave 2/11a_foodcomsumption_prod_purch.dta
				
OUTPUTS: 		intermediate/wave2_s11a_food.dta
				
NOTE:			
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Adjustments
****************************************************************/
use "${GHAraw}/Wave 2/11a_foodcomsumption_prod_purch.dta", clear

* format data
encode foodshortname, gen(food_id)
destring unitcode, replace
replace unitname = strlower(unitname)

***** Create units for common other values *****
* units are: cube, heap, plate, serving
replace unitname = "plate" if inlist(unitname, "pla", "plaate", "plaltes", "lates", ///
	"pplates", "per plate", "pplate") | substr(unitname, 1, 5) == "plate"
	
replace unitname = "cube" if substr(unitname, 1, 4) == "cube"

replace unitname = "heap" if inlist(unitname, "hea", "heapp", "heao") | ///
substr(unitname, 1, 4) == "heap"

replace unitname = "serving" if inlist(unitname, "servigs", "per seving", ///
	"servings", "servicings", "service", "per servings", "per serving") 

replace unitcode = 101 if unitname == "cube"
replace unitcode = 102 if unitname == "heap"
replace unitcode = 103 if unitname == "plate"
replace unitcode = 104 if unitname == "serving"

***** recode 95s that have acual labels *****
replace unitcode = 6 if unitname == "per bowl"	
replace unitcode = 7 if unitname == "box" | unitname == "boxes" 
replace unitcode = 18 if unitname == "maxi bag" 	
replace unitcode = 19 if unitname == "mini bag" 	
replace unitcode = 26 if unitname == "tubers" 	
replace unitcode = 40 if unitname == "calabash" 
replace unitcode = 42 if unitname == "sachet" 
replace unitcode = 43 if inlist(unitname, "pack", "packs", "packets")


* recode all of the variations on 'beer bottle'
replace unitcode = 5 if food_id == 1 & inlist(unitname, "beer", "club beer", ///
	"glass", "guiness", "spirit beer bottle", "bottle", "5", "guinease")
replace unitname = "beer bottle" if unitcode == 5

* recode all of the variations on 'fanta/coke bottle'
replace unitcode = 10 if food_id == 10 & (substr(unitname, 1, 3) == "can" | ///
	substr(unitname, 1, 4) == "malt" | substr(unitname, 1, 5) == "fanta" | ///
	inlist(unitname, "bottle", "juice", "bottles",  "sprite, cok,fanta bottle", "10", ///
	 "bottles", "battles", "cok bottle", "bottlee") | substr(unitname, 1, 4) == "faan")
replace unitname = "fanta/coke bottle" if unitcode == 10

* recode when unitname is recorded as unitcode
replace unitcode = 2 if unitname == "2"
replace unitcode = 20 if unitname == "20"
replace unitcode = 22 if unitname == "22"
replace unitcode = 30 if unitname == "30"
replace unitcode = 36 if unitname == "36"


***** case by case adjustments *****
replace purchasedquant = 3 * purchasedquant if unitname == "3 pounds"
	replace unitcode = 21 if unitname == "3 pounds"
	replace unitname = "pounds" if unitname == "3 pounds"
	
replace purchasedquant = 0.5 * purchasedquant if unitname == "half crate"
	replace unitcode = 30 if unitname == "half crate"
	replace unitname = "crate" if unitname == "half crate"
	
* Create a chicken unit for chicken, guinea, fowl
replace producedquant = 2 * producedquant if unitname == "2 chickens"
replace producedquant = 3 * producedquant if unitname == "3 fowls" | unitname == "three chickens"
replace producedquant = 5 * producedquant if unitname == "5 chickens"
replace producedquant = 6 * producedquant if unitname == "6 chickens"
	replace unitname = "chicken" if inlist(unitname, "2 chickens", "3 fowls", ///
	"5 chickens", "one chicken", "full chicken", "three chickens", ///
	"one live bird", "fowl")
	replace unitname = "chicken" if foodshortname == "chickenguineafowl" & unitname == "full"
	replace unitcode = 110 if unitname == "chicken"
	
* get the unitname and apply it to changed values with 
bysort unitcode: egen prob_uname = mode(unitname)
replace unitname = prob_uname if unitname != prob_uname & unitname != "gallon" & unitcode < 95

save "${GHAbuild}/intermediate/wave2_s11a_food.dta", replace


