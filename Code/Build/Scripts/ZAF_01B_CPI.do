/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Build South Africa CPI		
AUTHORS: 		Sam Marshall
CREATED:		7/15/2019
DESC: 			Create year-month CPI deflators for SA
ORG:			SECTION 1: Prepare data 	
INPUTS: 				
OUTPUTS: 		CPI.dta		
NOTE:			data downloaded from http://www.statssa.gov.za/?page_id=1854&PPN=P0141&SCH=7561
						on 7/15/2019. See right hand panel time series.
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Prepare data
****************************************************************/
import excel "${ZAFraw}/CPI.xlsx", sheet("Excel table from 2008") firstrow clear
keep if H04 == "All Items"
rename H13 location
keep location M*
forvalues yr = 2008/2019 {
	rename MO*`yr' MO`yr'*
}
reshape long MO, i(location) j(month)

rename MO CPI
tostring month, gen(date_id)
gen year = substr(date_id, 1, 4)
gen mo = substr(date_id, 5, 2)
destring year, replace
destring mo, replace
gen intrv_mo = ym(year, mo)
format intrv_mo %tm

keep location CPI intrv_mo

gen prov2011 = 1 if location == "Western Cape"
replace prov2011 = 2 if location == "Eastern Cape"
replace prov2011 = 3 if location == "Northern Cape"
replace prov2011 = 4 if location == "Free State"
replace prov2011 = 5 if location == "Kwazulu-Natal"
replace prov2011 = 6 if location == "North-West"
replace prov2011 = 7 if location == "Gauteng"
replace prov2011 = 8 if location == "Mpumalanga"
replace prov2011 = 9 if location == "Limpopo"
replace prov2011 = 101 if location == "All urban areas"
replace prov2011 = 102 if location == "Rural Areas"
replace prov2011 = 103 if location == "Total country"

save "${ZAFbuild}/intermediate/CPI.dta", replace
