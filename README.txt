This repository contains replication data and code for the paper "Migration costs and observational returns to migration in the developing world", published in 2020 in volume 113 of the Journal of Monetary Economics.

Link to published version:https://www.sciencedirect.com/science/article/abs/pii/S0304393220300428

The directory is organized as follows:
* Code: contains all code for replicating the project
	* Replication_SetUp.do: Defines all filepath globals. Run this first.
	* Build: Contains scripts for cleaning data for analysis
	* Analysis: Contains scripts for analysing clean data and constructing tables
* Data: Contains raw and cleaned data for the project
	* Raw: Original secondary datasets
	* Build: Data constructed from scripts in Code/Build
* Output: Contains LaTeX tables 
	* AllTables: Compiles all tables into a single document.

To produce the tables from the paper:
1. Open and run Code/Replication_SetUp.do
2. Open and run runStudy.do (in the main directory)
3. Open and recompile Output/AllTables.tex