* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

Fact 3 - negative assortative matching
Note: all statistics are based on the decomposition sample we use in the paper.
______________________________________________________________________________*/

set scheme lean1

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
* 1. Figure 4 - Assortativity  
*----------------------------
use "output/network_i", clear 
// construct vars
	bys vat_j: egen n_s_j = count(vat_i)
	foreach x in n_s_j n_c_i {	
		gen ln`x' = ln(`x')
	}	
	fcollapse (mean) avglnn_s_j = lnn_s_j (first) lnn_c_i nace4_i, by(vat_i)
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip	
	
// sector demeaning        
	foreach x in avglnn_s_j lnn_c_i {	
        reghdfe `x',  a(FE_`x' = nace4_i) resid
		predict double r_`x', r
	}
	
	local vars "r_avglnn_s_j r_lnn_c_i"
	local x "r_lnn_c_i"
	
// firm-level regressions	
	reg `vars', robust
	local r2: di %5.2f e(r2)
	local b: di %5.2f _b[`x'] 
	local se: di %5.2f _se[`x']
	
// binscatter	
	binscatter `vars', n(20) line(none) ms(circle) ///
	yt("Average number of suppliers, demeaned") xt("Number of customers, demeaned") ///
	xl(`lm1' `l0' `l1') ///
	note("Linear slope: `b' (`se')" "R-squared: `r2'", box ring(0) pos(7))
    graph export "results/fact3.eps", replace	

clear
