/*****************************************************************
PROJECT: 		Rural-Urban Migration 			
TITLE:			Build country variables		
DESC: 			Create and modify variables for each country
******************************************************************/

bysort pid (wave): gen fhhid = hhid[1]
label var fhhid "HHID first interview round"


***********  dropping outlier eas  **************
egen ptag = tag(pid)
gen ptagR = ptag*(1-urban)
egen earn = sum(ptagR) if !mi(ea), by(ea)
egen eaurb =mean(startUrban) if !mi(ea), by(ea)
bysort pid (wave): gen rl = urban[_n] == 1 if urban[_n - 1] == 0
egen rlrate = mean(rl), by(ea wave)
egen eaw = tag(ea wave)
sum rlrate if eaw
egen rln = sum(rl), by(ea wave)
gen mrlrate = rlrate
gen mrln = rln
bysort ea eaw (wave): replace mrlrate = mrlrate[_n-1] if !mi(mrlrate[_n-1]) & mrlrate[_n-1] > mrlrate[_n]
bysort ea eaw (wave): replace mrln = mrln[_n-1] if !mi(mrln[_n-1]) & mrln[_n-1] > mrln[_n]
replace urban = . if mrlrate == 1 & earn > 4

*Categorizing high vs. low rural-urban migrant EAs
egen max_urb = max(urban), by(pid)
egen min_urb = min(urban), by(pid)
cap drop switcher
gen switcher = max_urb != min_urb
gen switcher_p = switcher if ptag	
	
 
	replace ea = . if ea < 0
	cap drop m_ea
	egen m_ea = max(ea), by(hhid wave)
	replace ea =m_ea if mi(ea)
		
	egen earl = mean(switcher_p) if startUrban == 0 & !mi(ea), by(ea)
	egen earls = sum(switcher_p) if startUrban == 0, by(ea)
	codebook earl ea switcher_p startUrban
	sum earl if switcher_p == 1 & !startUrban & !mi(ea), detail
	gen highrl2 = earl > `r(p50)' if !mi(earl)


* create and label additional variables
gen hhsize2 = hhsize^2
cap gen age2 = age^2
cap drop migr_status
gen migr_status = 1 if ever_rural == 1 & ever_urban == 0
	replace migr_status = 2 if startUrban == 0 & ever_urban == 1
	replace migr_status = 3 if ever_urban == 1 & ever_rural == 0
	replace migr_status = 4 if startUrban == 1 & ever_rural == 1
lab define status 1 "Rural Stayer" 2 "Rural Leaver" 3 "Urban Stayer" 4 "Urban Leaver"
lab val migr_status status

label var urban "Urban"
label var female "Female"
label var educ "Years of education"
label var educ2 "Years of education squared"
lab var agesq "Age squared"
label var age "Age"
label var switcher "Migrating during panel"
label var hhsize "Household size"
label var hhsize2 "Household size squared"
label var startUrban "Urban in first interview"
label var rural_leaver "Individual-wave specific rural-urban migration indicator"

label var rlrate "Rural leaving rate"
label var rl "Rural leaver"




