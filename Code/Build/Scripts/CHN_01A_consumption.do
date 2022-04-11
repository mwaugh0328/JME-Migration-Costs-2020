/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Build China Consumption
AUTHORS: 		Sam Marshall, Min Byung Chae		
CREATED:		9/4/2019
DESC: 			Create consumption files for China
INPUTS: 		CFPS_familyecon_2016.dta	
OUTPUTS: 		w1_consumption.dta				
NOTE:			
******************************************************************/


* initiate globals if not done already

/****************************************************************
	SECTION 1:CFPS 2010
****************************************************************/
use "${CHNraw}/2010/CFPS_familyecon_2010.dta", clear
keep fid expense food familysize
rename expense consumption
rename familysize hhsize
save "${CHNbuild}/intermediate/w1_consumption.dta", replace

/****************************************************************
	SECTION 2: CFPS 2012
****************************************************************/
use "${CHNraw}/2012/CFPS_familyecon_2012.dta", clear
keep fid12 expense food familysize
rename fid12 fid
rename expense consumption
rename familysize hhsize
save "${CHNbuild}/intermediate/w2_consumption.dta", replace

/****************************************************************
	SECTION 3: CFPS 2014
****************************************************************/
use "${CHNraw}/2014/CFPS_familyecon_2014.dta", clear
keep fid14 expense food familysize
rename fid14 fid
rename expense consumption
rename familysize hhsize
save "${CHNbuild}/intermediate/w3_consumption.dta", replace

/****************************************************************
	SECTION 4: CFPS 2016
****************************************************************/
use "${CHNraw}/2016/CFPS_familyecon_2016.dta", clear
keep fid16 expense food familysize
rename fid16 fid
rename expense consumption
rename familysize hhsize
save "${CHNbuild}/intermediate/w4_consumption.dta", replace
