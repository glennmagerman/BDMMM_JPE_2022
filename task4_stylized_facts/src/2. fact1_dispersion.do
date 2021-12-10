* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

Fact 1 - disperson in several dimensions.
Note: all statistics are based on the decomposition sample we use in the paper.
______________________________________________________________________________*/

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

// put all graphs on same axes
local axes "xl(`lm4' `lm3' `lm2' `lm1' `l0' `l1' `l2' `l3' `l4')"

// set scheme
	set scheme s1color

*-------------------------------------
* 1. Figure 1a - distribution of sales
*-------------------------------------
// Kernel density turnover (demeaned at 4d)
use  "output/seller_chars_$end", clear	    	

// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// sector demeaning        
	 foreach x in S_i {
		gen ln`x' = ln(`x')
		qui reghdfe ln`x',  a(FE_`x' = nace4_i) resid
		predict r_ln`x', r
	}	
	
// graph	
	kdensity r_lnS,  `axes' ///
	xt("total sales, demeaned") lcolor(blue) note("") title("")
	graph export "results/fact1_kdens_S.png", replace	

*----------------------------------------------------------------------	
* 2. Figure 1b & 1c - distribution of number of customers and suppliers 
*----------------------------------------------------------------------
// calculate number of suppliers for firms that have a decomposition 
use "$task2/output/mobilitygroup_$end", clear
	gcollapse (count) n_s = vat_i, by (vat_j)
	ren vat_j vat_i
save "tmp/nsup", replace

// calculate number of customers for firms that have a decomposition 
use "$task2/output/mobilitygroup_$end", clear
	gcollapse (count) n_c = vat_j, by (vat_i)
	merge 1:1 vat_i using "./tmp/nsup", nogen keep(match)
	merge 1:1 vat_i using "$task3/output/components_$end", nogen ///
	keep(match) keepusing(nace4_i)    	

// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// sector demeaning        
	 foreach x in n_c n_s {
		gen ln`x' = ln(`x')
		qui reghdfe ln`x',  a(FE_`x' = nace4_i) resid
		predict r_ln`x', r
	}	
	
// graph kdensity number of customers	
	kdensity r_lnn_c,  `axes' ///
	xt("number of customers, demeaned") lcolor(blue) note("") title("")
	graph export "results/fact1_kdens_n_c.png", replace	
	
// graph kdensity number of customers	
	kdensity r_lnn_s,  `axes' ///
	xt("number of suppliers, demeaned") lcolor(blue) note("") title("")
	graph export "results/fact1_kdens_n_s.png", replace	

clear
