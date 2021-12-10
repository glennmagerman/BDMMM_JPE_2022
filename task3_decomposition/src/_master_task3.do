* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This task performs the firm size decomposition into components.
We provide several variants of the decomposition, as reported in the Appendix.
______________________________________________________________________________*/

// change to task directory
clear all
cd "$task3"

// globals/constants
global cutoff_ip = 5

// initialize task (build from inputs)
foreach dir in tmp output results {
	cap !rm -rf "`dir'"
}

// create task folders
foreach dir in input src output tmp results {
	cap !mkdir "`dir'"
}	

// prep datasets
	do "src/1. datasets.do"							// prep datasets to calculate components
	
// main results 	
	do "src/2. create_components.do"				// create firm-level components (non-demeaned)
	do "src/3. table2_decomposition.do"				// variance decomposition firm size (Table 2)
	do "src/4. table3_correlations.do"				// correlation matrix components (Table 3)
	
// additional results - Appendix	
	do "src/5. E1 decomp_bysector.do"				// Table 13 & 14 - decomposition by 2- & 4-digit sectors
	do "src/6. E3 decomp_differences.do"			// Table 16 - decomposition in long differences	
	do "src/7. E4 decomp_nace4_nuts3.do"			// Table 17 - controlling for seller location
	do "src/8. E4 decomp_nace4xnuts3.do"			// Table 17 - controlling for seller location
	do "src/9. E5 nonparametric.do"					// Figure 11 - conditional expectation function
	do "src/10. D2 sellerFE_tau.do"					// Empirical confirmation of appendix D2
	
// maintenance
cap !rm -rf "tmp"									// Unix
cap !rmdir /q /s "tmp"								// Windows		

// back to main folder of tasks
cd "$folder"		
