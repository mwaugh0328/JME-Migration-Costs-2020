/*****************************************************************
PROJECT: 		LMMVW Replication Files
				
TITLE:			Table 2: Characteristics of the Panel Tracking Studies.do
			
DESCRIPTION: 	Descripe all panel datasets 

NOTE:			Execute Replication_SetUp.do before executing this file
				Need to install frmttable. To do so:
				1. type findit frmttable 
				2. Choose the option starting with sg97_5
				3. Choose click here to install
				
Problems: 1. China - number of observations
		  2. Ghana - everything
		  3. Indonesia - p rural
		  4. Malawi - number of communities
		  5. P migrate for all except tanzania 
******************************************************************/


local ctrynames `""China" "Ghana" "Indonesia" "Malawi" "South Africa" "Tanzania" "'
local ctrys chn gha idn mwi saf tza

local nctry = wordcount(`" `ctrys' "')
matrix b = J(`nctry', 6,.)
matrix rownames b = "China" "Ghana" "Indonesia" "Malawi" "South Africa" "Tanzania" 
matrix colnames b = "Waves" "Communities" "Individuals" "Observations" "P(Rural)" "P(Migrate R\-U)"
loc i = 0
qui foreach ctry of local ctrynames {
	loc ++ i
	noi di " ----- `ctry'  -----"
	use "${xcbuild}/`ctry'.dta", clear
		cap drop rl
	sum wave, detail
	matrix b[`i',1] = `r(max)'
	
	tab ea
	matrix b[`i',2] = `r(r)'
	
	*egen ptag = tag(pid)
	count if ptag
	matrix b[`i',3] = `r(N)'
	
	matrix b[`i', 4] = _N
	
	
	if "`ctry'" == "Indonesia" replace urban = urban_hklm 
	sum urban if wave == 1
	matrix b[`i', 5] = round(1 - `r(mean)', .01)
	
	cap drop max_urb
	egen max_urb = max(urban), by(pid)
	gen rl = max_urb == 1 if startUrban == 0
	bysort pid (year): gen y12 = year[_N] - year[1] 
	sum y12 if wave == 1
	loc y = `r(mean)'
	sum rl if wave == 1 
	matrix b[ `i', 6] = round(`r(mean)'/`y', .001) ///b[`i',1]
	
}

frmttable using "${tabledir}/Table2_descriptive.tex", statmat(b) tex replace ///
	sfmt(gc) fragment title(Characteristics of six panel datasets) ///
	note( Note: Columns 1–4 list the number of survey waves, the number of communities (i.e. enumeration areas) ///
surveyed, the number of individuals surveyed, and the total number of observations, for each country. ///
Column 5 lists the fraction of adults living in a rural location in wave 1. Column 6 presents the annualized ///
rural-urban migration rate for adults in wave 1.	)


