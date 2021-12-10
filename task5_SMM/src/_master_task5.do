* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This task performs the Simulated Method of Moments
______________________________________________________________________________*/

// change to task directory
clear all
cd "$task5"

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

// main results 
	do "./src/1. table4_param_calibrations.do"
	do "./src/2. prep_datasets.do"
	do "./src/3. SMM_moments.do"
	do "./src/4. bootstrap.do"

// maintenance
cap !rm -rf "./tmp"									// Unix
cap !rmdir /q /s "./tmp"							// Windows		

// back to main folder of tasks
cd "$folder"		

	
