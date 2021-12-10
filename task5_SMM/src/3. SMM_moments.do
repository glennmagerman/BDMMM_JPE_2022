* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This code calculates the moments of interest for the SMM 
______________________________________________________________________________*/

// prep file to save results to
tempname memhold
postfile `memhold' mean_lnS_Snet_i var_lnS_Snet_i mean_lnn_c_i var_lnn_c_i /// 		
	var_lnSnetn_c_i b_lnSnet_n_c_i varlnS_i varlnSnet_i var_lnlaborprod var_wlnshare_Mnet /// 
	b_wlnshare_M b_wlnshare_Mnet b_lnp10 b_lnp50 b_lnp90 b_assort_down ///
	var_lnM_j var_lnMnet_j mean_lnn_s_j var_lnn_s_j b_lnM_n_s_j b_lnMnet_n_s_j b_assort_up ///
	b_psi b_n_c b_thetabar b_W_c b_beta sumtest ///
	using "results/SMM_moments", replace
	
*----------------------
* 1. Downstream moments
*----------------------
use "output/SMM_downstream", clear

// mean(lnS_Snet_i) and var(lnS_Snet_i)
	su r_lnS_Snet_i, d
	local mean_lnS_Snet_i = r(mean)
	local var_lnS_Snet_i = r(Var)
	
// mean(lnn_c_i) - non-demeaned
	su lnn_c_i, d
	local mean_lnn_c_i = r(mean)
	
// var(lnn_c_i)	(demeaned)
	su r_lnn_c_i, d
	local var_lnn_c_i = r(Var)

// var(lnSnet_n_c_i)
	su r_lnSnetn_c_i, d
	local var_lnSnetn_c_i = r(Var)
	
// beta from lnSnet_n_c_i on lnn_c_i (fact 2B)
	reg r_lnSnetn_c_i r_lnn_c_i, robust				                				
	local b_lnSnet_n_c_i : di %5.4f _b[r_lnn_c_i] 
	
// var(lnS_i)
	su r_lnS_i, d
	local var_lnS_i = r(Var)	

// var(lnSnet_i)
	su r_lnSnet_i, d
	local var_lnSnet_i = r(Var)	
	
// var(lnlaborprod)
	su r_lnlaborprod, d 
	local var_lnlaborprod = r(Var)	

// variance of weighted ln market shares
	su r_wavglnshare_Mnet_j, d
	local var_wlnshare_Mnet = r(Var)	

// beta from weighted ln market shares
	reg r_wavglnshare_M_j r_lnn_c_i, robust				                				
	local b_wlnshare_M: di %5.4f _b[r_lnn_c_i] 
	reg r_wavglnshare_Mnet_j r_lnn_c_i, robust				                				
	local b_wlnshare_Mnet: di %5.4f _b[r_lnn_c_i] 		

// p10/50/90 m_ij	
	foreach y in lnp10 lnp50 lnp90 {
		reg r_`y' r_lnn_c_i if n_c_i >= 10, robust				                				
		local b_`y': di %5.4f _b[r_lnn_c_i] 
	}	
	
// assortativity	
	reg r_avglnn_s_j r_lnn_c_i, robust
	local b_assort_down: di %5.4f _b[r_lnn_c_i] 

*--------------------
* 2. Upstream moments
*--------------------
use "output/SMM_upstream", clear
//	var(lnM_j)
	su r_lnM_j, d
	local var_lnM_j = r(Var)
	
// var(lnMnet_j)
	su r_lnMnet_j, d
	local var_lnMnet_j = r(Var)

// mean(lnn_s_j) - non-demeaned
	su lnn_s_j, d
	local mean_lnn_s_j = r(mean)		
	
// var(lnn_s_j) - demeaned
	su r_lnn_s_j, d
	local var_lnn_s_j = r(Var)	
	
// beta from lnMn_s on lnn_s_j 
	reg r_lnMn_s_j r_lnn_s_j, robust				                				
	local b_lnM_n_s_j : di %5.4f _b[r_lnn_s_j] 
	
// beta from lnMnetn_s on lnn_s_j 
	reg r_lnMnetn_s_j r_lnn_s_j, robust				                				
	local b_lnMnet_n_s_j : di %5.4f _b[r_lnn_s_j] 
	
// assortativity	
	reg r_avglnn_c_i r_lnn_s_j, robust
	local b_assort_up: di %5.4f _b[r_lnn_s_j] 
	
*-------------------------
* 3. Decomposition moments
*-------------------------				   
use "$task3/output/components_$end", clear		
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// sector demeaning        
    foreach x in S_i psi_i n_c_i thetabar_i W_c_i beta_i {									
		reghdfe ln`x',  a(FE_`x' = nace4_i) resid
        predict double r_ln`x', r
        drop ln`x'
        ren r_ln`x' ln`x'
    }	
	
// decomposition on demeaned variables
	foreach x in psi_i n_c_i thetabar_i W_c_i beta_i {	
		reg ln`x' lnS_i
		local b_`x': di _b[lnS_i]
	}
	local sumtest = `b_psi_i' + `b_n_c_i' + `b_thetabar_i' + `b_W_c_i' + `b_beta_i'	// exact decomposition
	
// collect and save	all moments
	post `memhold'	(`mean_lnS_Snet_i') (`var_lnS_Snet_i') (`mean_lnn_c_i') ///
	(`var_lnn_c_i') (`var_lnSnetn_c_i') (`b_lnSnet_n_c_i') (`var_lnS_i') ///
	(`var_lnSnet_i') (`var_lnlaborprod') (`var_wlnshare_Mnet') (`b_wlnshare_M') ///
	(`b_wlnshare_Mnet') (`b_lnp10') (`b_lnp50') (`b_lnp90') (`b_assort_down') ///
	(`var_lnM_j') (`var_lnMnet_j') (`mean_lnn_s_j') (`var_lnn_s_j') (`b_lnM_n_s_j') ///
	(`b_lnMnet_n_s_j') (`b_assort_up') (`b_psi_i') (`b_n_c_i') (`b_thetabar_i') ///
	(`b_W_c_i') (`b_beta_i') (`sumtest')
postclose `memhold'	
	
clear


