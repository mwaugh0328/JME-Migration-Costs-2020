/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Import Price and GDPPC data	
AUTHOR: 		Sam Marshall
CREATED:		3/4/2019
MODIFIED:		9/4/2019
DESC: 			import data from FRED with CPI (2010=100) and GDP per capita
					in constant dollars (US 2010 $).
ORG:			Section 1: Import and Clean Up		
INPUTS: 		Panel_Migration.xls			
OUTPUTS: 		CPI_GDPPC.dta			
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Import and Clean Up
****************************************************************/

import excel "${pxraw}/Panel_Migration.xls", sheet("Annual") firstrow clear

save "${pxbuild}/CPI_GDPPC.dta", replace

import excel "${pxraw}/Panel_Migration.xls", sheet("Annual,_End_of_Year") ///
	firstrow clear


rename DDOE01MWA086NWDB CPI_malawi

rename DDOE01UGA086NWDB CPI_uganda

merge 1:1 DATE using "${pxbuild}/CPI_GDPPC.dta"

rename CHNCPIALLAINMEI CPI_china

rename DDOE02IDA086NWDB CPI_indonesia

rename DDOE02TZA086NWDB CPI_tanzania

rename ZAFCPIALLAINMEI CPI_south_africa

rename NYGDPPCAPKDCHN GDPPC_china

rename NYGDPPCAPKDIDN GDPPC_indonesia

rename NYGDPPCAPKDMWI GDPPC_malawi

rename NYGDPPCAPKDTZA GDPPC_tanzania

rename NYGDPPCAPKDUGA GDPPC_uganda

rename NYGDPPCAPKDZAF GDPPC_south_africa

gen year = year(DATE)

drop DATE _merge

order year

sort year

save "${pxbuild}/CPI_GDPPC.dta", replace
