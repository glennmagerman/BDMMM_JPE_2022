* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

*-----------------
* 1. Decomposition
*-----------------
local v "S_i psi_i n_c_i thetabar_i W_c_i beta_i"

tempname memhold
postfile `memhold' N b_psi b_n_c b_thetabar b_W_c b_beta ///
				   se_psi se_n_c se_thetabar se_W_c se_beta sumtest ///
				   using "./results/table_decomp_robVAT", replace
	
use "./output/components_robVAT", clear		
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// sector demeaning        
    foreach x in `v' {									
		reghdfe ln`x',  a(FE_`x' = nace4_i) resid
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
	local sumtest = `b_psi_i' + `b_n_c_i' + `b_thetabar_i' + `b_W_c_i' + `b_beta_i'	// exact decomposition
	
// save output
    post `memhold' (`N') ///
	(`b_psi_i') (`b_n_c_i') (`b_thetabar_i') (`b_W_c_i') (`b_beta_i') ///
	(`se_psi_i') (`se_n_c_i') (`se_thetabar_i') (`se_W_c_i') (`se_beta_i') ///
    (`sumtest')
postclose `memhold'			

clear	
