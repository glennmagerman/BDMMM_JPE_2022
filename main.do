* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This do-file calls all codes to replicate the results of
"The origins of firm heterogeneity: a production network approach".

To replicate the results, change the project folder location to your preferred 
location and run the master do-file. Ado files are installed automatically when 
necessary.

IMPORTANT: We use reghdfe version 5.7.1 20mar2019 in the paper. 
There might be differences in the command syntax across versions.
______________________________________________________________________________*/

// constants and globals
	global start 		2002
	global end 			2014

// auto install ado files/packages if necessary
	foreach package in gtools reghdfe heatplot {
		cap which `package'
		if _rc == 111 ssc install `package'
	}	
	
// project folder
	clear all
	*global folder 	"D:/User Documents/MAGERMG/BDMMM/tasks"			// NBB Server
	global folder	"~/Dropbox/work/research/papers/published/BDMMM/codes_for_publication" 

	cd "$folder"
	set scheme lean1

// tasks
	global task0		"$folder/task0_randomdata"
	global task1		"$folder/task1_getdata"
	global task2		"$folder/task2_FE_regression"
	global task3		"$folder/task3_decomposition" 
	global task4		"$folder/task4_stylized_facts" 
	global task5 		"$folder/task5_SMM" 
	global task6 		"$folder/task6_SMMresults" 
	global task7 		"$folder/task7_VATgroups" 


// rebuild all tasks
	do "$task0/src/_master_task0.do"   
	do "$task1/src/_master_task1.do"    
	do "$task2/src/_master_task2.do"
	do "$task3/src/_master_task3.do"
	do "$task4/src/_master_task4.do"
	do "$task5/src/_master_task5.do"
	*do "$task6/src/_master_task6.do"	
	do "$task7/src/_master_task7.do"
