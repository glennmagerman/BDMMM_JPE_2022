* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

Additional results on fact 1 in the Appendix
______________________________________________________________________________*/

*-------------------------------------------------
* 1. Table 7 - moments of distributions firm sales
*-------------------------------------------------
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
	
// table 
	tabstat r_lnS_i, ///
	stats(var skew kurt p1 p5 p10 p25 p50 p75 p90 p95 p99) format(%3.2f) col(stat)
	
*------------------------------------------------------------------------
* 2. Table 7 - moments of distributions number of customers and suppliers
*------------------------------------------------------------------------
// calculate number of suppliers for firms that have a decomposition 
use "$task2/output/mobilitygroup_$end", clear
	gcollapse (count) n_s = vat_i, by (vat_j)
	ren vat_j vat_i
save "tmp/nsup", replace

// calculate number of customers for firms that have a decomposition 
use "$task2/output/mobilitygroup_$end", clear
	gcollapse (count) n_c = vat_j, by (vat_i)
	merge 1:1 vat_i using "tmp/nsup", nogen keep(match)
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
	
// table 
	tabstat r_lnn_c r_lnn_s, ///
	stats(var skew kurt p1 p5 p10 p25 p50 p75 p90 p95 p99)	format(%3.2f) col(stat)
	
*------------------------------------------------
* 3. Table 8 - Firm size distribution by industry  
*------------------------------------------------
// high level industries by seller	
use  "output/seller_chars_$end", clear	    	
	gen nace2_i = floor(nace4_i/100)
	gen industry_i =. 
	replace industry_i = 1 if nace2_i <=9 						// primary and extraction
	replace industry_i = 2 if nace2_i >=10 & nace2_i <=33 		// manufacturing
	replace industry_i = 3 if nace2_i >=35 & nace2_i <=39 		// utilities
	replace industry_i = 4 if nace2_i >=41 & nace2_i <=43 		// construction
	replace industry_i = 5 if nace2_i >=45 & nace2_i <=82 		// market services
	replace industry_i = 6 if nace2_i >=84 & !missing(nace2_i)	// non-market services
save "tmp/sellers_byindustry_$end", replace	

// prep file to save results to 
tempname memhold
postfile `memhold' Industry N Mean sd p10 p25 p50 p75 p90 p95 p99 ///
	using "results/fact1_sumstats_turnover_${end}", replace
	
// table by industry	
forvalues s = 1/6 {																									
use  "tmp/sellers_byindustry_$end", clear	    
	keep if industry == `s'
	
// incidental parameters, drop cells with less than k obs	(consistency sample)
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// calc stats	
	qui distinct vat
	local N = r(ndistinct)
	replace S_i = S_i/1000000									// in mln euro
	su S_i, d	
	post `memhold' (`s') (`N') (r(mean)) (r(sd)) (r(p10)) ///
	(r(p25)) (r(p50)) (r(p75)) (r(p90)) (r(p95)) (r(p99)) 	
}		

// table last row (all obs across sectors)	
use  "tmp/sellers_byindustry_$end", clear	   														
	local s 7		
	
// incidental parameters, drop cells with less than k obs	(consistency sample)
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
	
// calc stats	
	qui distinct vat
	local N = r(ndistinct)
	replace S_i = S_i/1000000									// in mln euro
	su S_i, d	
	post `memhold' (`s') (`N') (r(mean)) (r(sd)) (r(p10))  ///
	(r(p25)) (r(p50)) (r(p75)) (r(p90)) (r(p95)) (r(p99))
postclose `memhold'	

*----------------------------------------------------------
* 4. Table 9 - Number of customers distribution by industry 
*----------------------------------------------------------	
// customers by industry of i
	use "$task2/output/mobilitygroup_$end", clear
	merge m:1 vat_i using "$task3/output/components_$end", nogen ///
	keep(match) keepusing(nace4_i) 
	gen nace2_i = floor(nace4_i/100)
	gen industry_i =. 
	replace industry_i = 1 if nace2_i <=9 						// primary and extraction
	replace industry_i = 2 if nace2_i >=10 & nace2_i <=33 		// manufacturing
	replace industry_i = 3 if nace2_i >=35 & nace2_i <=39 		// utilities
	replace industry_i = 4 if nace2_i >=41 & nace2_i <=43 		// construction
	replace industry_i = 5 if nace2_i >=45 & nace2_i <=82 		// market services
	replace industry_i = 6 if nace2_i >=84 & !missing(nace2_i)	// non-market services
save "tmp/network_of_customers_by_industry", replace	

// prep file to save results to 
tempname memhold											
postfile `memhold' Industry N Mean sd p10 p25 p50 p75 p90 p95 p99 ///
	using "results/fact1_sumstats_n_c_${end}", replace		
	
forvalues s = 1/6 {											
use "tmp/network_of_customers_by_industry", clear	
	keep if industry == `s'
	di "Industry"" " `s' 
	
// calc stats	
	fcollapse (count) n_c = vat_j (first) nace4_i, by(vat_i)	
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip	
	
	qui distinct vat
	local N = r(ndistinct)
	su n_c, d	
	post `memhold' (`s') (`N') (r(mean)) (r(sd)) (r(p10))  ///
	(r(p25)) (r(p50)) (r(p75)) (r(p90)) (r(p95)) (r(p99))
}	

// last row (all observations across sectors)
use "tmp/network_of_customers_by_industry", clear	

// calc stats	
	fcollapse (count) n_c = vat_j (first) nace4_i, by(vat_i)	
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip	
	
	local s 7
	qui distinct vat
	local N = r(ndistinct)
	su n_c, d	
	post `memhold' (`s') (`N') (r(mean)) (r(sd)) (r(p10))  ///
	(r(p25)) (r(p50)) (r(p75)) (r(p90)) (r(p95)) (r(p99))
postclose `memhold'		
	
*-----------------------------------------------------------
* 4. Table 10 - Number of customers distribution by industry 
*-----------------------------------------------------------		
// suppliers by industry of i
use "$task2/output/mobilitygroup_$end", clear
	ren (vat_i vat_j) (vat vat_i)
	merge m:1 vat_i using "$task3/output/components_$end", nogen ///
	keep(match) keepusing(nace4) 
	ren (vat vat_i nace4) (vat_i vat_j nace4_j)
	gen nace2_j = floor(nace4_j/100)
	gen industry_j =. 
	replace industry_j = 1 if nace2_j <=9 						// primary and extraction
	replace industry_j = 2 if nace2_j >=10 & nace2_j <=33 		// manufacturing
	replace industry_j = 3 if nace2_j >=35 & nace2_j <=39 		// utilities
	replace industry_j = 4 if nace2_j >=41 & nace2_j <=43 		// construction
	replace industry_j = 5 if nace2_j >=45 & nace2_j <=82 		// market services
	replace industry_j = 6 if nace2_j >=84 & !missing(nace2_j)	// non-market services
save "tmp/network_of_suppliers_by_industry", replace	

// prep file to save results to 
tempname memhold											
postfile `memhold' Industry N Mean sd p10 p25 p50 p75 p90 p95 p99 ///
	using "results/fact1_sumstats_n_s_${end}", replace	

forvalues s = 1/6 {											
use "./tmp/network_of_suppliers_by_industry", clear	
	keep if industry == `s'
	di "Industry"" " `s' 
	
// calc stats	
	fcollapse (count) n_s = vat_i (first) nace4_j, by(vat_j)	
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_j), by(nace4_j) 
	drop if nobs < $cutoff_ip		
	
	qui distinct vat
	local N = r(ndistinct)
	su n_s, d	
	post `memhold' (`s') (`N') (r(mean)) (r(sd)) (r(p10))  ///
	(r(p25)) (r(p50)) (r(p75)) (r(p90)) (r(p95)) (r(p99))
}	
use "tmp/network_of_suppliers_by_industry", clear	
// calc stats	
	fcollapse (count) n_s = vat_i (first) nace4_j, by(vat_j)	
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_j), by(nace4_j) 
	drop if nobs < $cutoff_ip					
	local s 7
	qui distinct vat
	local N = r(ndistinct)
	su n_s, d	
	post `memhold' (`s') (`N') (r(mean)) (r(sd)) (r(p10))  ///
	(r(p25)) (r(p50)) (r(p75)) (r(p90)) (r(p95)) (r(p99))
postclose `memhold'			
	
	