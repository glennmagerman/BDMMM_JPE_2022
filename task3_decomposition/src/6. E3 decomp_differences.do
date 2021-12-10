* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This code performs the size decomposition in long differences 2002-2014
(Table 16 in the Appendix).
Note, this restricts the analysis to firms that are present in both 2002 and 2014.
______________________________________________________________________________*/

global D  12	  										// long differences
global long_diff = $start + $D

*--------------------------
* 1. Variance decomposition 
*--------------------------
qui {
local v "S_i psi_i n_c_i thetabar_i W_c_i beta_i"

// prep file to save results	
tempname memhold
postfile `memhold' start end N b_psi b_n_c b_thetabar b_W_c b_beta ///
				   se_psi se_n_c se_thetabar se_W_c se_beta sumtest /// 
				   using "results/table_decomp_${start}_${long_diff}", replace

use "output/components_$start", clear
	gen year = $start
	append using "output/components_$long_diff"
	replace year = $long_diff if missing(year)
	xtset vat year, delta($D)
	
// keep only surviving firms
	order year vat	
	bys vat: keep if _N==2										

// long differences
	foreach x in `v' g {				    
		gen D_ln`x' = D.ln`x'	
		drop ln`x'
		ren D_ln`x' ln`x'
	}

	drop if year ==$start
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip	

// sector demeaning (4-digit level)         
    foreach x in `v' g {					
        reghdfe ln`x',  a(FE_`x' = nace4_i) resid
        predict r_ln`x', r
        drop ln`x'
        ren r_ln`x' ln`x'
    }	
	
// nobs	
    distinct vat_i
    local N = r(ndistinct)		

// decomposition on demeaned variables
	foreach x in psi_i n_c_i thetabar_i W_c_i beta_i {	
		reg ln`x' lnS_i
		local b_`x': di _b[lnS_i]
        local se_`x': di _se[lnS_i]
	}
	
// do components sum to 1?	
	local sumtest = `b_psi_i' + `b_n_c_i' + `b_thetabar_i' + `b_W_c_i' + `b_beta_i'	
	
// save output
    post `memhold' ($start) ($long_diff) (`N') ///
	(`b_psi_i') (`b_n_c_i') (`b_thetabar_i') (`b_W_c_i') (`b_beta_i') ///
	(`se_psi_i') (`se_n_c_i') (`se_thetabar_i') (`se_W_c_i') (`se_beta_i') ///
    (`sumtest')
	}	
postclose `memhold'

clear
