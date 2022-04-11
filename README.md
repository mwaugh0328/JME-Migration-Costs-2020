### [Migration Costs and Observational Returns to Migration in the Developing World, Journal of Monetary Economics](https://www.sciencedirect.com/science/article/abs/pii/S0304393220300428), Volume 113, August 2020

---

This repository contains replication data and code for the paper ["Migration costs and observational returns to migration in the developing world"](https://www.sciencedirect.com/science/article/abs/pii/S0304393220300428), published in 2020 in Volume 113 of the Journal of Monetary Economics.

Published version here: [https://www.sciencedirect.com/science/article/abs/pii/S0304393220300428](https://www.sciencedirect.com/science/article/abs/pii/S0304393220300428)

Dependencies: The code relies on the following packages in Stata:

* estout

* outreg2

* geodist

The directory is organized as follows:

* [Code](/Code): contains all code for replicating the project:

	* [Replication_SetUp.do](/Code/Replication_SetUp.do): Defines all file path globals. Run this first.

	* [Build](/Code/Build): Contains scripts for cleaning data for analysis

	* [Analysis](/Code/Analysis): Contains scripts for analyzing clean data and constructing tables

* [Data](/Data): Contains raw and cleaned data for the project

	* [Build](/Data/Build): Cleaned data constructed from scripts in Code/Build

	* The original raw datasets are too large to post on github. As of now please contact [David Lagakos](lagakos@gmail.com) to access them.

* [Output](/Output): Contains LaTeX tables

	* [AllTables](/Output/AllTables.tex): Compiles all tables into a single document.

To produce the tables from the paper:
1. Open and run [Code/Replication_SetUp.do](/Code/Replication_SetUp.do)

2. Open and run [RunStudy.do](RunStudy.do)

3. Open and recompile [Output/AllTables.tex](/Output/AllTables.tex)
