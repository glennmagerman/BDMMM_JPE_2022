* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021


/*______________________________________________________________________________

This task runs the two-way fixed effects regressions to estimate the seller
and buyer fixed effects. We also obtain some descriptive statistics on these.

This only uses the B2B network data.

It may take a while to run the codes: hdfe regression on 13-17 million links, 
and this for all years separately.
______________________________________________________________________________*/


// change to task directory
clear all
cd "$task2"

// initialize task (build from inputs)
foreach dir in tmp output results {
	cap !rm -rf "`dir'"
}

// create task folders
foreach dir in input src output tmp results {
	cap !mkdir "`dir'"
}	
	
// code	
	do "src/1. FE_regression.do" 					// run 2way FE 	
	do "src/2. table1_var_2wayFE.do" 				// Table 1 - var/covar 2way FE 
		
// maintenance
cap !rm -rf "tmp"									// Unix
cap !rmdir /q /s "tmp"								// Windows		

// back to main folder of tasks
cd "$folder"		
