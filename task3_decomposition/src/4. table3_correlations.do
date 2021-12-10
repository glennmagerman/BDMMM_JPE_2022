* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This code constructs the correlations of Table 3. 
______________________________________________________________________________*/

cap log close
log using "results/covariance", text replace

*--------------------------
* 1. Covariances components
*-------------------------- 	
local v "S_i psi_i n_c_i thetabar_i W_c_i beta_i"

use "output/components_2014", clear

// incidental parameters, drop cells with less than k obs
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// sector demeaning (4-digit level)        
    foreach x in `v' {									
        reghdfe ln`x',  a(FE_`x' = nace4_i) resid
        predict double r_ln`x', r
        drop ln`x'
        ren r_ln`x' ln`x'
    }			
	
// correlation table	
	noi corr lnS_i lnpsi_i lnn_c_i lnthetabar_i lnW_c_i lnbeta_i
	
/*
             |    lnS_i  lnpsi_i  lnn_c_i lnthet~i  lnW_c_i lnbeta_i
-------------+------------------------------------------------------
       lnS_i |   1.0000
     lnpsi_i |   0.2320   1.0000
     lnn_c_i |   0.4913  -0.3285   1.0000
lnthetabar_i |   0.2041   0.2177  -0.1768   1.0000
     lnW_c_i |   0.4466   0.1585   0.0890   0.2289   1.0000
    lnbeta_i |   0.0157  -0.3600  -0.3340  -0.1626  -0.4200   1.0000
*/	

cap log close	
clear
