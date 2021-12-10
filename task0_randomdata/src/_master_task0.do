* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This task creates random data along the same dimensions as the real but 
confidential data used in the paper. 

This random data allows to run all codes for replication, but cannot reconstruct 
the quantitative results of the paper. For full replication, all codes and real 
data are available for replication upon request. Please contact the Department 
of Studies at the National Bank of Belgium. 

______________________________________________________________________________*/

// change to task directory
clear all
cd "$task0"

// initialize task (build from inputs)
foreach dir in tmp output {
	cap !rm -rf "`dir'"
}

// create task folders
foreach dir in input src output tmp {
	cap !mkdir "`dir'"
}	
	
// code	
	do "./src/1. createdata.do" 					// generate network and firms
	do "./src/2. copy_to_task1.do" 					// copy to data task if no real data
	
// maintenance
cap !rm -rf "tmp"									// Unix
cap !rmdir /q /s "tmp"								// Windows		

// back to main folder of tasks
cd "$folder"		
