* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021


/*______________________________________________________________________________

This code performs the size decomposition, demeaned at the NACE 4-digit x NUTS3
level (Table 17 in the Appendix).
______________________________________________________________________________*/

*-----------------
* 1. Decomposition (NACE4 x NUTS3)
*-----------------
local v "S_i psi_i n_c_i thetabar_i W_c_i beta_i"

// prep file to store results
tempname memhold
postfile `memhold' year N b_psi b_n_c b_thetabar b_W_c b_beta ///
				   se_psi se_n_c se_thetabar se_W_c se_beta sumtest ///
				   using "results/table_decomp_nace4_x_nuts3", replace
	
qui {
forvalues t = $start/$end { 
use "./output/components_`t'", clear		
	noi di "Decomposition `t'"
	
// attach NUTS info	
	gen year = `t' 
	ren vat_i vat
	merge m:1 vat year using "$task1/output/firms_zip_nuts", ///
	nogen keep(match master)
	encode nuts_3_code, gen(nuts3_i)
	ren vat vat_i
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i nuts3_i) 
	drop if nobs < $cutoff_ip	

// demeaning (nace4xnuts3)      
    foreach x in `v' {									
        reghdfe ln`x', a(FE_`x' = nace4_i#nuts3_i) resid
        predict double r_ln`x', r
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
	
// do the components sum to 1?	
	local sumtest = `b_psi_i' + `b_n_c_i' + `b_thetabar_i' + `b_W_c_i' + `b_beta_i'	
	
// save output
    post `memhold' (`t') (`N') ///
	(`b_psi_i') (`b_n_c_i') (`b_thetabar_i') (`b_W_c_i') (`b_beta_i') ///
	(`se_psi_i') (`se_n_c_i') (`se_thetabar_i') (`se_W_c_i') (`se_beta_i') ///
    (`sumtest')
	}
}	
postclose `memhold'			

clear	
