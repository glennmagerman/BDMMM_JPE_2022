* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This code runs the two-way fixed effects regression as in 
http://scorreia.com/software/reghdfe/

In particular, we run lnmij = lnpsi_i + lntheta_j + lnw_ij. 

IMPORTANT: We use reghdfe version 5.7.1 20mar2019 in the paper. 
There might be differences in the command syntax across versions.

We retain the giant connected component (each firm requires at least 2 
observations as a supplier/buyer to obtain identified fixed effects).
______________________________________________________________________________*/
		
scalar drop _all

// prep file to save results
tempname memhold
postfile `memhold' t N R2 R2_adj Fstat using "results/2wayFE", replace 
		
*---------------------------------
* 1. Iterated twoway FE estimation (Equation 1)
*---------------------------------
qui {
forvalues t = $start/$end {
	
// load data	
	use "$task1/output/network_`t'", clear					
	noi di "Year `t'"
	keep vat* m_ij	
    gen double lnm_ij = ln(m_ij)  
	
// estimate 2way FE on mobility group, obtain residuals and demean LHS
	noi reghdfe lnm_ij, a(lnpsi_i=vat_i lntheta_j=vat_j) old
	drop if !e(sample)
	predict lnw_ij, r
	egen double lng = mean(lnm_ij)
		
// sample statistics	
	su lnpsi lntheta lnw 
	local N = e(N)
	local R2 = e(r2)
	local R2_adj = e(r2_a)
	local Fstat = e(F)
	
	save "output/mobilitygroup_`t'", replace 				
	post `memhold' (`t') (`N') (`R2') (`R2_adj') (`Fstat')
 	}
}
postclose `memhold'		

clear
