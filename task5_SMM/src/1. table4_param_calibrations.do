* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This code calibrates the hyper parameters of the SMM as in Table 4
We calibrate the model with internally consistent values from the micro data.
______________________________________________________________________________*/

// prep file to save results to 
tempname memhold
postfile `memhold' alpha mu GDP using "results/calibrations", replace

*----------------------------
* 1. Labor cost share (alpha)
*----------------------------
use "$task4/output/seller_chars_$end", clear

// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// add variables for labor share	
	ren vat_i vat
	gen year = $end
	merge 1:1 vat year using "$task1/output/firms_annac",  nogen keep(match)

// firm-level labor cost share
	gen alpha_i = wL/(wL + M)
	su alpha_i 											// 0.24 (unweighted average across all firms)
	collapse (mean) alpha_i , by(nace4_i)
	su alpha_i 											// 0.24 (avg across sectors)
	local alpha = r(mean)

*----------------	
* 2. Markups (mu)
*----------------	
use "$task4/output/seller_chars_$end", clear

// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip	

// add variables for markups	
	ren vat_i vat
	gen year = $end
	merge 1:1 vat year using "$task1/output/firms_annac",  nogen keep(match)	

// firm-level markup as sales over total variable costs
	gen mu_i = S_i/(wL + M)
	su mu_i												// 1.25 (unweighted average across all firms)
	collapse (mean) mu_i, by(nace4_i) 
	su mu_i												// 1.24
	local mu = r(mean)
	
*-------	
* 3. GDP
*-------
use "$task4/output/seller_chars_$end", clear

// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip	

// add variables for labor share	
	ren vat_i vat
	gen year = $end
	merge 1:1 vat year using "$task1/output/firms_annac",  nogen keep(match)	

// GDP
	gcollapse (sum) S_i Snet_i
	gen GDP = S_i - Snet_i								// 350 billion euro
	su GDP
	local GDP = r(mean)
	
// save output
    post `memhold' (`alpha') (`mu') (`GDP') 
postclose `memhold'			
