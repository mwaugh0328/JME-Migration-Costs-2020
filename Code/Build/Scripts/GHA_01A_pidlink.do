/*****************************************************************
PROJECT: 		Ghana Panel Tracking data
				
TITLE:			splitoff_matches.do
			
AUTHOR: 		Sam Marshall / Min Byung Chae

DATE CREATED:	5th November 2018

LAST EDITED:	5/3/2019

DESCRIPTION: 	Import splitoff matching spreadsheet from Northwestern 


ORGANIZATION:	Section 1: Import excel
				Section 2: Create pid
				Section 3: Create common pid
				
INPUTS: 		Splitoff Matching Spreadsheet_11Dec2018.xlsx
				Wave 2/01b2_roster.dta
				Wave 1/s1d.dta
				
OUTPUTS: 		intermediate/pidlink.dta
				
NOTE:			Import the set of cross-wave id matches
				Using the latest Splitoff Matching Spreadsheet - MBC
******************************************************************/

* initiate globals if not done already

/****************************************************************
	SECTION 1: Clean up Excel doc
****************************************************************/

import excel "${GHAraw}/Crosswave/Splitoff Matching Spreadsheet_11Dec2018.xlsx", ///
	sheet("all") firstrow allstring clear

gen pid_w1 = RootFPrimary + Roothhmid

gen pid_w2 = SplitoffFPrimary + Splithhmid
	replace pid_w2 = SplitoffFPrimary + Roothhmid if Splithhmid == ""

destring Roothhmid, replace
destring Splithhmid, replace

rename SplitoffFPrimary FPrimary
rename RootFPrimary hhno

* drop obs that don't have a match in wave 1
drop if pid_w1 == ""

duplicates drop pid_w1, force

drop E Note1 Note2 H Note

* make the pidlink household and member id. Default to first wave
gen pid_hh = hhno
	replace pid_hh = FPrimary if pid_hh == ""
	
gen pid_mem = Roothhmid
	replace pid_mem = Splithhmid if pid_mem == .
	tostring pid_mem, replace

destring hhno, replace

/****************************************************************
	SECTION 2: Make pid for all of wave 2
****************************************************************/
preserve 

gen hhmid = Splithhmid
	replace hhmid = Roothhmid if hhmid == .
merge 1:1 FPrimary hhmid using "${GHAraw}/Wave 2/01b2_roster.dta"

replace pid_hh = FPrimary if pid_hh == ""
replace pid_mem = string(hhmid) if pid_mem == ""

gen pidlink = pid_hh + pid_mem

duplicates tag pidlink, gen(dup)
drop if dup > 0 & _merge == 2

keep FPrimary hhno Splithhmid Roothhmid pid_w1 pid_w2 hhmid pid_hh pid_mem pidlink

replace pid_w2 = pidlink if pid_w2 == ""

save "${GHAbuild}/intermediate/wave2_pidlink.dta", replace

restore

/****************************************************************
	SECTION 3: Make pid for all of wave 1
****************************************************************/

gen hhmid = Roothhmid

merge 1:1 hhno hhmid using "${GHAraw}/Wave 1/s1d.dta"
drop if _merge == 1

replace pid_hh = strofreal(hhno, "%12.0g") if pid_hh == ""
replace pid_mem = string(hhmid) if pid_mem == ""

keep FPrimary hhno Splithhmid Roothhmid pid_w1 pid_w2 hhmid pid_hh pid_mem

gen pidlink = pid_hh + pid_mem

replace pid_w1 = pidlink if pid_w1 == ""

merge 1:1 pidlink using "${GHAbuild}/intermediate/wave2_pidlink.dta"

gen survey_wave = "Round 1 only" if _merge == 1
	replace survey_wave = "Round 2 only" if _merge == 2
	replace survey_wave = "Both" if _merge == 3

replace pid_w2 = pidlink if pid_w2 == ""
replace pid_w1 = pidlink if pid_w1 == ""

keep pid_w1 pid_w2 pidlink survey_wave

save "${GHAbuild}/intermediate/pidlink.dta", replace

erase "${GHAbuild}/intermediate/wave2_pidlink.dta"

