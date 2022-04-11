/*****************************************************************
PROJECT: 		LMMVW Replication Files
				
TITLE:			globals.do
			
AUTHOR: 		Sam Marshall

DATE CREATED:	31 May 2018

LAST EDITED:	21st July 2018

DESCRIPTION: 	This File sets up the global directory paths for all other do 
				files in this project. 

ORGANIZATION:	Section 1: Global definitions
				Section 2: 

NOTE:			Execute this file before running anything else
******************************************************************/

clear
set more off

global user "/Users/SMARSH/Dropbox (Personal)"
if "`c(username)'" == "cv324" global user "/Users/`c(username)'/Y-RISE Dropbox/Corey Vernot"

***** No need to edit anything below this line *****

global projdir "${user}/LMMVW Replication"

global rawdata "${projdir}/Data/Raw"

global BGDraw "${projdir}/Data/Raw/Bangladesh"
global CHNraw "${projdir}/Data/Raw/China"
global GHAraw "${projdir}/Data/Raw/Ghana"
global IDNraw "${projdir}/Data/Raw/Indonesia"
global MWIraw "${projdir}/Data/Raw/Malawi"
global ZAFraw "${projdir}/Data/Raw/South Africa"
global TZAraw "${projdir}/Data/Raw/Tanzania"
global pxraw  "${projdir}/Data/Raw/Prices"

global BGDbuild "${projdir}/Data/Build/Bangladesh"
global CHNbuild "${projdir}/Data/Build/China"
global GHAbuild "${projdir}/Data/Build/Ghana"
global IDNbuild "${projdir}/Data/Build/Indonesia"
global MWIbuild "${projdir}/Data/Build/Malawi"
global ZAFbuild "${projdir}/Data/Build/South Africa"
global TZAbuild "${projdir}/Data/Build/Tanzania"
global pxbuild  "${projdir}/Data/Build/Prices"
global xcbuild  "${projdir}/Data/Build/Cross Country"

global bldcode "${projdir}/Code/Build"
global acode "${projdir}/Code/Analysis"
global tabledir "${projdir}/Output"
