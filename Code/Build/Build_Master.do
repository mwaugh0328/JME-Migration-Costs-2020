/*****************************************************************
PROJECT: 		LMMVW Replication Files
				
TITLE:			Build Master.do
			
AUTHOR: 		Sam Marshall

DESCRIPTION: 	Build all datasets 

ORGANIZATION:	Section 1: Build Price Data
				Section 2: Build China
				Section 3: Build Ghana
				Section 4: Build Indonesia
				SECTION 5: Build Malawi
				SECTION 6: Build South Africa
				SECTION 7: Build Tanzania

NOTE:			Execute Replication_SetUp.do before executing this file
******************************************************************/

/****************************************************************
	SECTION 1: Build Price Data
****************************************************************/

do "${bldcode}/Scripts/01-import_CPI_GDPPC.do"

/****************************************************************
	SECTION 2: Build China
****************************************************************/
do "${bldcode}/Scripts/CHN_01A_consumption.do"
do "${bldcode}/Scripts/CHN_01B_chars.do"
do "${bldcode}/Scripts/CHN_02_panel.do"

/****************************************************************
	SECTION 3: Build Ghana
****************************************************************/
do "${bldcode}/Scripts/GHA_01A_pidlink.do"
do "${bldcode}/Scripts/GHA_01B_w1_chars.do"
do "${bldcode}/Scripts/GHA_01C_w1_consumption.do"
do "${bldcode}/Scripts/GHA_01D_w1_income.do"
do "${bldcode}/Scripts/GHA_01E_w2_chars.do"
do "${bldcode}/Scripts/GHA_01F_w2_income.do"
do "${bldcode}/Scripts/GHA_01G_w2_clean_s11a_food.do"
do "${bldcode}/Scripts/GHA_02_w2_consumption.do"
do "${bldcode}/Scripts/GHA_03_panel.do"

/****************************************************************
	SECTION 4: Build Indonesia
****************************************************************/
do "${bldcode}/Scripts/IDN_01A_chars.do"
do "${bldcode}/Scripts/IDN_01B_w1_consumption.do"
do "${bldcode}/Scripts/IDN_01C_urban.do"
do "${bldcode}/Scripts/IDN_01D_hhold_income.do"
do "${bldcode}/Scripts/IDN_01E_W1_income.do"
do "${bldcode}/Scripts/IDN_01F_W2_income.do"
do "${bldcode}/Scripts/IDN_01G_W3_income.do"
do "${bldcode}/Scripts/IDN_01H_W4_income.do"
do "${bldcode}/Scripts/IDN_01I_W5_income.do"
do "${bldcode}/Scripts/IDN_01J_migration.do"
do "${bldcode}/Scripts/IDN_02_panel.do"

/****************************************************************
	SECTION 5: Build Malawi
****************************************************************/
do "${bldcode}/Scripts/MWI_01A_chars.do"
do "${bldcode}/Scripts/MWI_01B_consumption.do"
do "${bldcode}/Scripts/MWI_01C_income.do"
do "${bldcode}/Scripts/MWI_02_panel.do"

/****************************************************************
	SECTION 6: Build South Africa
****************************************************************/
do "${bldcode}/Scripts/ZAF_01A_chars.do"
do "${bldcode}/Scripts/ZAF_01B_CPI.do"
do "${bldcode}/Scripts/ZAF_01C_income.do"
do "${bldcode}/Scripts/ZAF_02_panel.do"

/****************************************************************
	SECTION 7: Build Tanzania
****************************************************************/
do "${bldcode}/Scripts/TZA_01A_consumption.do"
do "${bldcode}/Scripts/TZA_01B_chars.do"
do "${bldcode}/Scripts/TZA_01C_income.do"
do "${bldcode}/Scripts/TZA_02_panel.do"

/****************************************************************
	SECTION 8: Build Bangladesh Seasonal Migration
****************************************************************/

do "${bldcode}/Scripts/Bangladesh_seasonal_migration.do"

