* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

Fact 2 - correlations
Note: all statistics are based on the decomposition sample we use in the paper.
______________________________________________________________________________*/

set scheme lean1

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

*------------------------------------------------
* 2. Figure 2a - larger firms have more customers
*------------------------------------------------
use "output/seller_chars_$end", clear

// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// sector demeaning        
    foreach x in Snet_i n_c_i {	
		gen ln`x' = ln(`x')
		reghdfe ln`x',  a(FE_`x' = nace4_i) resid
        predict double r_ln`x', r
    }	

// firm-level regression
	reg r_lnSnet_i r_lnn_c_i, robust				        				
	local r2: di %5.2f e(r2)
	local b: di %5.2f _b[r_lnn_c_i] 
	local se: di %5.2f _se[r_lnn_c_i] 

// binscatter
	binscatter r_lnSnet_i r_lnn_c_i, n(20) line(none) ms(circle) ///
	yt("Network sales, demeaned") xt("Number of customers, demeaned") ///
	yl(`lm1' `l0' `l1') xl(`lm1' `l0' `l1') ///
	note("Linear slope: `b' (`se')" "R-squared: `r2'", box ring(0) pos(11))
    graph export "results/fact2A.eps", replace
	
*-------------------------------------------	
* 3. Figure 2b - but less sales per customer 
*-------------------------------------------	
use "output/seller_chars_$end", clear

// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// sector demeaning        
    foreach x in Snetn_c_i n_c_i {	
		gen ln`x' = ln(`x')
		reghdfe ln`x',  a(FE_`x' = nace4_i) resid
        predict double r_ln`x', r
    }	

// firm-level regression
	reg r_lnSnetn_c_i r_lnn_c_i, robust				                				
	local r2: di %5.2f e(r2)
	local b: di %5.2f _b[r_lnn_c_i] 
	local se: di %5.2f _se[r_lnn_c_i] 
	
// binscatter
	binscatter r_lnSnetn_c_i r_lnn_c_i, n(20) line(none) ms(circle) ///
	yt("Network sales per customer, demeaned") xt("Number of customers, demeaned") ///
	yl(`lm1' `l0' `l1') xl(`lm1' `l0' `l1') ///
	note("Linear slope: `b' (`se')" "R-squared: `r2'", box ring(0) pos(11))
    graph export "results/fact2B.eps", replace
	
*----------------------------------------------------------------	
* 4. Figure 3a - and lower sales across the customer distribution
*----------------------------------------------------------------		
// sector means for m_ij and n_c
use "output/network_i", clear 		
	gcollapse (mean) avg_lnm_i = lnm_ij (first) n_c_i nace4_i, by(vat_i)	// geo mean by seller i
	gen lnn_c_i = ln(n_c_i)
	gcollapse (mean) avg_lnm = avg_lnm_i avg_lnn_c = lnn_c_i, by(nace4_i)	// unweighted mean of sector S
save "tmp/sector_means", replace

// quantiles of m_ij and n_c by firm
use "output/network_i", clear 		
	gcollapse (p10) lnp10 = lnm_ij (p50) lnp50 = lnm_ij ///
	(p90) lnp90 = lnm_ij (first) n_c_i nace4_i, by(vat_i) fast	
	gen lnn_c_i = ln(n_c_i)
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// sector demeaning 
	merge m:1 nace4_i using "tmp/sector_means", nogen keep(match)
	gen r_lnn_c_i = lnn_c_i - avg_lnn_c
	gen r_lnp10 = lnp10 - avg_lnm 
	gen r_lnp50 = lnp50 - avg_lnm 
	gen r_lnp90 = lnp90 - avg_lnm 
	
// firm-level regression
	foreach y in r_lnp10 r_lnp50 r_lnp90 {
		reg `y' r_lnn_c_i if n_c >= 10, robust				                				
		local r2_`y': di %5.2f e(r2)
		local b_`y': di %5.2f _b[r_lnn_c] 
		local se_`y': di %5.2f _se[r_lnn_c]	
	}	

// binscatter
	foreach x in r_lnp10 r_lnp50 r_lnp90 {
		binscatter `x' r_lnn_c if n_c >= 10, n(20) genxq(bin) line(none) ///
		savedata("tmp/bins_`x'") replace
		drop bin
	}
	foreach x in r_lnp10 r_lnp50 r_lnp90 {
		insheet using "tmp/bins_`x'.csv", clear
	save "tmp/bins_`x'", replace
	}
    
	use "tmp/bins_r_lnp10", clear
	foreach x in r_lnp50 r_lnp90 {
		merge 1:1 r_lnn_c using "tmp/bins_`x'", nogen
	}
    tw (sc r_lnp10 r_lnn_c, ms(O) mc(navy) scheme(lean1)) || /// 
    (sc r_lnp50 r_lnn_c, ms(D) mc(pink)) || ///
    (sc r_lnp90 r_lnn_c, ms(T) mc(green)),  ///
    yl(`lm1' `l0' `l1') xl(`lm1' `l0' `l1') ///
	yt("m{sub:ij}, demeaned") xt("Number of customers, demeaned") ///
	leg(pos(5) ring(0) rows(3) reg(lwidth(none)) lab(1 "p10") lab(2 "p50") lab(3 "p90")) 
    graph export "results/fact2C.eps", replace					
	
*--------------------------------------------------------	
* 5. Figure 3b - and lower market shares within customers
*--------------------------------------------------------	
use "output/network_i", clear 
	gen weight = m_ij/Snet_i
	gen wlnshare_Mnet_j = weight*lnshare_Mnet_j	
	
	fcollapse (sum) wavglnshare_Mnet_j = wlnshare_Mnet_j (count) n_c_i = vat_j (first) nace4_i, by(vat_i)
	gen lnn_c_i = ln(n_c_i)	
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip	
			
// demean vars by 4-digit sectors	
	foreach x in wavglnshare_Mnet_j lnn_c_i {
        reghdfe `x',  a(FE_`x' = nace4_i) resid
		predict r_`x', r
	}	
	
// firm-level regression
	reg r_wavglnshare_Mnet_j r_lnn_c_i, robust				                				
	local r2: di %5.2f e(r2)
	local b: di %5.2f _b[r_lnn_c] 
	local se: di %5.2f _se[r_lnn_c]
	
// binscatter
	binscatter r_wavglnshare_Mnet_j r_lnn_c_i, n(20) line(none) ms(circle) ///
	yt("Weighted avg. mkt share, demeaned") xt("Number of customers, demeaned") ///
	xl(`lm1' `l0' `l1') ///
	note("Linear slope: `b' (`se')" "R-squared: `r2'", box ring(0) pos(11))
    graph export "results/fact2D_Mnet_weighted.eps", replace

clear	
