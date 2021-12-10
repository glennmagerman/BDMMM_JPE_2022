* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This file generates random data that mimic the 4 datasets used in the paper.
The seed ensures random draws are identical across draws.
______________________________________________________________________________*/

global nlinks = 500000
global nfirms = 50000

set seed 871835

*-----------
* 1. network
*-----------
forvalues t = $start/$end {
	clear
	set obs $nlinks
	gen year = `t'
	gen vat_i = floor(($nfirms - 1)*runiform() + 1) 		// random links
	gen vat_j = floor(($nfirms - 1)*runiform() + 1)
	drop if vat_i==vat_j 									// no self-loops
	duplicates drop vat_i vat_j, force 						// no multiple edges
	gen sales_ij = 250+ exp(rnormal()*5 + 5)  				// lognormal() link values 
	save "tmp/network_`t'", replace
}	

use "tmp/network_$start", clear
	forvalues t = 2003/2014 {
		append using  "tmp/network_`t'"
	}
save  "output/Belgian B2B flows_large_cleaned_n_balanced", replace	

*--------------
* 2. NACE codes
*--------------
// NACE source 1
forvalues t = $start/$end {
	clear
	set obs $nfirms	
	gen year = `t'
	gen vat = _n											// balanced panel (for unbalanced draw from uniform)
	gen cnace = 100 + int((9600)*runiform()) 				// 4-digit NACE
    replace cnace = floor(cnace/10)*10                      // scale back on # sectors to have enough firms within each sector
	tostring cnace, replace
save "tmp/nace_`t'", replace						
}

use "tmp/nace_$start", clear
	forvalues t = 2003/2014 {
		append using  "tmp/nace_`t'"
	}
save  "output/NACE_0214", replace	

// NACE source 2 + zip codes
forvalues t = $start/$end {
	clear
	set obs $nfirms	
	gen year = `t'
	gen vat = _n											// balanced panel (for unbalanced draw unif)
	
	gen C_NACE = 100 + int((9600)*runiform()) 				// 4-digit NACE
    replace C_NACE = floor(C_NACE/10)*10            		// scale back on # sectors to have enough firms within each sector
	tostring C_NACE, replace
	gen POST_CODE = 100*(10 + int((99-10+1)*runiform())) 			// zip code
save "tmp/nacebel_`t'", replace						
}

use "tmp/nacebel_$start", clear
	forvalues t = 2003/2014 {
		append using  "tmp/nacebel_`t'"
	}
save  "output/NBB_B2B_sample_large_nace_n_zip_codes", replace	

*--------------------------------------
* 3. annual accounts + VAT declarations
*--------------------------------------
forvalues t = $start/$end {
	clear
	set obs $nfirms	
	gen year = `t'
	gen vat = _n											// balanced panel (for unbalanced draw unif)
	foreach x in turnover total_inputs laborcost {			// firm chars
		gen `x' = floor(exp(rnormal()*5) + 1) + 1000
	}
	foreach x in empl {
		gen `x' = floor(exp(rnormal()*2) + 1)
	}	
save "tmp/firms_`t'", replace						
}

use "tmp/firms_$start", clear
	forvalues t = 2003/2014 {
		append using  "tmp/firms_`t'"
	}	
save  "output/annualized_annac_02_14", replace	
	
clear
