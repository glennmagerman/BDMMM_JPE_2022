* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This code formats the datasets for the SMM analysis.
We prepare datasets for downstream analysis and upstream analysis separately.
The focal unit is the firm for which we have the decomposition.
______________________________________________________________________________*/

*--------------
* 1. downstream
*--------------
// sector means (for m_ij observations)
use "$task4/output/network_i", clear 		
	gcollapse (mean) avg_lnm_i = lnm_ij (first) nace4_i, by(vat_i)	// geo mean by seller i
	gcollapse (mean) avg_lnm = avg_lnm_i, by(nace4_i)				// unweighted mean of sector S
save "tmp/sector_means", replace

// to firm-level obs
use "$task4/output/network_i", clear 
	gen weight = m_ij/Snet_i
	gen wlnshare_M_j = weight*lnshare_M_j	
	gen wlnshare_Mnet_j = weight*lnshare_Mnet_j	
	bys vat_j: egen n_s_j = count(vat_i)
	gen lnn_s_j = ln(n_s_j)
				
	gcollapse (sum) wavglnshare_M_j = wlnshare_M_j wavglnshare_Mnet_j = wlnshare_Mnet_j ///
	(p10) lnp10 = lnm_ij (p50) lnp50 = lnm_ij (p90) lnp90 = lnm_ij ///
	(mean) avglnn_s_j = lnn_s_j avglnshare_Mnet_j = lnshare_Mnet_j ///
	avglnshare_M_j = lnshare_M_j (first) S_i Snet_i n_c_i nace4_i, by(vat_i)	
	gen Snetn_c_i = Snet_i/n_c_i
	gen S_Snet_i = S_i/Snet_i

// value added per worker
	ren vat_i vat
	gen year = $end
	merge 1:1 vat year using "$task1/output/firms_annac", ///
	nogen keep(match master) keepusing(M FTE)
	ren (vat M FTE) (vat_i M_i L_i)
	gen laborprod = (S_i - M_i)/L_i
	replace laborprod = . if laborprod < 0							// 4000 obs < 0		
		
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// sector demeaning 
	foreach x in n_c_i S_i Snet_i Snetn_c_i laborprod S_Snet_i {
		gen ln`x' = ln(`x')
	}
	
	merge m:1 nace4_i using "tmp/sector_means", nogen keep(match)
	gen r_lnp10 = lnp10 - avg_lnm 
	gen r_lnp50 = lnp50 - avg_lnm 
	gen r_lnp90 = lnp90 - avg_lnm 
	
    foreach x in lnS_i lnSnet_i lnn_c_i lnSnetn_c_i lnlaborprod lnS_Snet_i ///
	wavglnshare_Mnet_j wavglnshare_M_j avglnn_s_j {	
		reghdfe `x',  a(FE_`x' = nace4_i) resid
        predict double r_`x', r
    }		
	keep vat_i r_* lnn_c_i n_c_i
save "output/SMM_downstream", replace

*------------
* 2. upstream
*------------
// start from output 2wayFE regressions (network)
use "$task2/output/mobilitygroup_$end", clear
	keep vat* m_ij lnm_ij	
	
// now see firms i in the decomposition as buyers
// (we write j sfrom structure of the data, but we consider same firms i as decomposition)
	ren (vat_i vat_j) (vat vat_i)
	merge m:1 vat_i using "$task3/output/components_$end", nogen ///
	keep(match) keepusing(nace4_i) 			
	ren (vat vat_i nace4_i) (vat_i vat_j nace4_j)
	distinct vat_j 											// 94,334 - OK								
	
// add characteristics
	gen year = $end
	ren vat_j vat 
	merge m:1 vat year using "$task1/output/firms_annac", ///	
	nogen keep(match) keepusing(M)
	ren (vat M) (vat_j M_j)
	drop year
	egen n_s_j = count(vat_i), by(vat_j)
	egen Mnet_j = total(m_ij), by(vat_j)
	bys vat_i: egen n_c_i = count(vat_j)
	distinct vat_j 

	replace M_j = max(M_j, Mnet_j) if !missing(M_j)			// avoid sum(shares) > 1. 488k out of 11.6 mln links
	replace M_j = Mnet_j if missing(M_j)		
	
	gen Mnetn_s_j = Mnet_j/n_s_j
	gen Mn_s_j = M_j/n_s_j
	gen lnn_c_i = ln(n_c_i)
	
	gcollapse (mean) avglnn_c_i = lnn_c_i ///
	(first) M_j n_s_j Mnet_j Mnetn_s_j Mn_s_j nace4_j, by(vat_j)
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_j), by(nace4_j) 
	drop if nobs < $cutoff_ip
	
// sector demeaning      
	foreach x in M_j Mnet_j n_s_j Mnetn_s_j Mn_s_j  {
		gen ln`x' = ln(`x')
	}
	  
    foreach x in lnM_j lnn_s_j lnMnet_j lnMnetn_s_j lnMn_s_j avglnn_c_i  {	
		reghdfe `x',  a(FE_`x' = nace4_j) resid
        predict double r_`x', r
    }		
	keep vat_j r_* lnn_s_j n_s_j
save "output/SMM_upstream", replace

				
