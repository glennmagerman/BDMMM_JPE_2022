* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

*---------------------------------
* 1. Iterated twoway FE estimation 
*---------------------------------
use "./output/network_robVAT_2014", clear			
	keep vat* m_ij	
    gen double lnm_ij = ln(m_ij)  
	
// estimate 2way FE on mobility group and demean LHS
	noi reghdfe lnm_ij, a(lnpsi_i=vat_i lntheta_j=vat_j) old
	drop if !e(sample)
	predict lnw_ij, r
	egen double lng = mean(lnm_ij)
save "./output/mobilitygroup_robVAT_2014", replace 	// mobilitygroup = connected component	
clear
