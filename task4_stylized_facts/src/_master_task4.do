* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This task creates the stylized facts (Section 2) of the paper.
______________________________________________________________________________*/

// change to task directory
clear all
cd "$task4"

// globals/constants
global cutoff_ip = 5

set scheme lean1

// initialize task (build from inputs)
foreach dir in tmp output results {
	cap !rm -rf "`dir'"
}

// create task folders
foreach dir in input src output tmp results {
	cap !mkdir "`dir'"
}	
	
// prep datasets 	
	do "src/1. datasets.do"							// prepare datasets 
	
// main results 
	do "src/2. fact1_dispersion.do"					// Fact 1
	do "src/3. fact2_correlations.do"				// Fact 2
	do "src/4. fact3_assortativity.do"				// Fact 3
	
// additional results appendix
	do "src/5. B1 distributions_lnS_lnnc_lnns.do"	// Additional moments
	do "src/6. B2 fact2_sector_pair_demeaning.do"	// Robustness with sector pair demeaning
	do "src/7. B3 fringe_buyers.do"					
	do "src/8. C exo mobility.do"					// Exogenous mobility tests

// maintenance
cap !rm -rf "tmp"									// Unix
cap !rmdir /q /s "tmp"								// Windows		

// back to main folder of tasks
cd "$folder"		
