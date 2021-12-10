* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This code performs the baseline version of the exact variance decomposition in Table 2.

In particular: lnS_i = lnpsi_i + lnn_c_i + ln_thetabar_i + lnW_c_i + lnbeta_i.

In order to obtain the variance contribution of each component, we regress each
variable on lnS_i. The coefficient then returns the share of variance in lnS_i 
explained by the component.
______________________________________________________________________________*/

*-----------------
* 1. Decomposition
*-----------------
local v "S_i psi_i n_c_i thetabar_i W_c_i beta_i"

tempname memhold
postfile `memhold' year N b_psi b_n_c b_thetabar b_W_c b_beta ///
				   se_psi se_n_c se_thetabar se_W_c se_beta sumtest ///
				   using "results/table_decomp_nace4", replace
	
qui {
forvalues t = $start/$end { 
use "output/components_`t'", clear		
	noi di "Decomposition `t'"
	
// incidental parameters, drop cells with less than `k' obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// demean all variables at the 4-digit sector level       
    foreach x in `v' {									
		reghdfe ln`x',  a(FE_`x' = nace4_i) resid
        predict double r_ln`x', r
        drop ln`x'
        ren r_ln`x' ln`x'
    }	
	
// nobs	
    distinct vat_i
    local N = r(ndistinct)	
	
// decomposition on demeaned variables, reverse OLS regressions on lnS 
	foreach x in psi_i n_c_i thetabar_i W_c_i beta_i {	
		reg ln`x' lnS_i
		local b_`x': di _b[lnS_i]
        local se_`x': di _se[lnS_i]
	}
	
// sanity check: do all components sum up?	
	local sumtest = `b_psi_i' + `b_n_c_i' + `b_thetabar_i' + `b_W_c_i' + `b_beta_i'	// exact decomposition
	
// save output
    post `memhold' (`t') (`N') ///
	(`b_psi_i') (`b_n_c_i') (`b_thetabar_i') (`b_W_c_i') (`b_beta_i') ///
	(`se_psi_i') (`se_n_c_i') (`se_thetabar_i') (`se_W_c_i') (`se_beta_i') ///
    (`sumtest')
	save "output/decomposition_`t'", replace	
	}
}	
postclose `memhold'			

clear	
