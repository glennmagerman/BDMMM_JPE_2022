* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: March 26, 2020

/*______________________________________________________________________________

This task extracts the real data used in the paper, and prepares it for analysis.
See also the files in /docs for additional info on the various datasets.
______________________________________________________________________________*/

// change to task directory
clear all
cd "$task1"

// initialize task (build from inputs)
foreach dir in tmp output {
	cap !rm -rf "`dir'"
}

// create task folders
foreach dir in input src output tmp {
	cap !mkdir "`dir'"
}	
	
// code	
	do "src/1. getdata.do" 
	do "src/2. clean.do" 
	
// maintenance
cap !rm -rf "tmp"									// Unix
cap !rmdir /q /s "tmp"								// Windows		

// back to main folder of tasks
cd "$folder"		
