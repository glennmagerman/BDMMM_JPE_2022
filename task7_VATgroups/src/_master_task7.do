* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: March 26, 2020

// change to task directory
clear all
cd "$task7"

// globals/constants
global cutoff_ip = 5

// initialize task (build from inputs)
foreach dir in tmp output results {
	cap !rm -rf "./`dir'"
}

// create task folders
foreach dir in input src output tmp results {
	cap !mkdir "./`dir'"
}	

// code	
	do "./src/1. VATgroups.do"
	do "./src/2. FE_regression.do"
	do "./src/3. create components.do"
	do "./src/4. decomposition.do"
	
// maintenance
cap !rm -rf "./tmp"									// Unix
cap !rmdir /q /s "./tmp"							// Windows		

// back to main folder of tasks
cd "$folder"		
