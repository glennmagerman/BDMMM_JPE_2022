* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021
		
*-----------		
* 0. Prelims		
*-----------
// log axis labels
forvalues i  = 0(1)10 {
	local a`i' = `i'*2.3
	local b`i'  `" "10{sup:`i'}" "'
	local l`i' `a`i'' `"`b`i''"' 
}

forvalues i  = 1(1)10 {
	local am`i' = `i'*-2.3
	local bm`i'  `" "10{sup:-`i'}" "'
	local lm`i' `am`i'' `"`bm`i''"' 
}
		
*----------------------------
* 1. B2 - n_c vs market share 
*----------------------------
use "output/network_i", clear 	
	gen weight = m_ij/Snet_i
	gen wlnshare_Mnet_j = weight*lnshare_Mnet_j	
	gcollapse (count) n_c_is = vat_j (sum) wavglnshare_Mnet_is = wlnshare_Mnet_j (first) nace4_i, by(vat_i nace4_j)
	gen lnn_c_is = ln(n_c_is)
	preserve
		gcollapse (mean) wavglnshare_Mnet = wavglnshare_Mnet_is avg_lnn_c_is = lnn_c_is, by(nace4_i nace4_j)
		save "tmp/sectorpair_means", replace
	restore
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i nace4_j) 
	drop if nobs < $cutoff_ip	
	
// demeaning	
	merge m:1 nace4_i nace4_j using "tmp/sectorpair_means", nogen keep(match)
	gen r_wavglnshare_Mnet_is = wavglnshare_Mnet_is - wavglnshare_Mnet
	gen r_lnn_c_is = lnn_c_is - avg_lnn_c_is
	
// firm-level regression
	reg r_wavglnshare_Mnet_is r_lnn_c_is, robust				                				
	local r2: di %5.2f e(r2)
	local b: di %5.2f _b[r_lnn_c_is] 
	local se: di %5.2f _se[r_lnn_c_is]
	
// binscatter
	binscatter r_wavglnshare_Mnet_is r_lnn_c_is, n(20) line(none) ms(circle) ///
	yt("Weighted avg. market share, demeaned") xt("Number of customers, demeaned") ///
	xl(`lm1' `l0' `l1') ///
	note("Linear slope: `b' (`se')" "R-squared: `r2'", box ring(0) pos(11))
    graph export "results/fact2D_sectorpairFE_Mnet_weighted.eps", replace		
	
clear	
