* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This code creates the conditional expectation function of the firm-level decomposition.
In particular, the data is grouped into 20 equal sized bins.
At each bin, the value to lnS equals the sum of its components.
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

*--------------------------------------
* 1. Conditional expectation by 20 bins
*--------------------------------------
// at each bin, the sum of components equals the value of lnS
use "output/decomposition_$end", clear
	foreach x in psi n_c thetabar W_c beta {
		binscatter ln`x' lnS_i, n(20) genxq(bin) line(none) ///
		savedata("tmp/bins_`x'") replace
		drop bin
	}
	foreach x in psi n_c thetabar W_c beta {
		insheet using "tmp/bins_`x'.csv", clear
	save "tmp/bins_`x'", replace
	}
    
use "tmp/bins_psi", clear
	foreach x in n_c thetabar W_c beta {
		merge 1:1 lns using "tmp/bins_`x'", nogen
	}
	
// graph	
	sc lnpsi lns, ms(S) mc(purple) scheme(lean1) || ///
    sc lnn_c lns, ms(C) mc(navy) || /// 
	sc lnthetabar lns, ms(Oh) mc(black) || /// 
	sc lnw_c lns, ms(D) mc(pink) || ///
	sc lnbeta lns, ms(T) mc(green) ///
	xl(`lm1' `l0' `l1') yl(`lm1' `l0' `l1') xt(Turnover (S)) ///
	leg(ring(0) pos(11) rows(3) reg(lwidth(none)) ///
	lab(1 {&psi}{sub:i}) lab(2 n{sup:c}{sub:i}) lab(3 {&theta}bar{sub:i}) ///
	lab(4 {&Omega}{sup:c}{sub:i}) lab(5 {&beta}{sub:i})) 
    graph export "results/binscatter_decomp_overall_$end.eps", replace

clear
