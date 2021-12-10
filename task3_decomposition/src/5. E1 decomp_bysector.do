* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This code performs the size decomposition by 2-digit and 4-sigit sectors 
separately, where the baseline decomposition demeans and aggregates across sectors.
This refers to Tables 13 and 14 in the Appendix E1.
______________________________________________________________________________*/


*-----------
* 0. Prelims
*-----------
// generate high-level industries
qui {
use "output/components_$end", clear
	gen nace2_i = floor(nace4_i/100)
	capture gen industry_i =. 
	replace industry_i = 1 if nace2_i <=9 						// primary and extraction
	replace industry_i = 2 if nace2_i >=10 & nace2_i <=33 		// manufacturing
	replace industry_i = 3 if nace2_i >=35 & nace2_i <=39 		// utilities
	replace industry_i = 4 if nace2_i >=41 & nace2_i <=43 		// construction
	replace industry_i = 5 if nace2_i >=45 & nace2_i <=82 		// market services
	replace industry_i = 6 if nace2_i >=84 & !missing(nace2_i)	// non-market services
save "tmp/industries_$end", replace			        
}

// word descriptions of NACE codes
import delimited "input/NACE_REV2_2digit.csv", clear varnames(1)
	ren code nace2
	drop parent
save "tmp/NACE2d_desc", replace
import delimited "input/NACE_REV2_4digit.csv", clear varnames(1)
	tostring code, replace force format("%5.2f") 
	replace code = subinstr(code, ".","",.)
	destring code, gen(nace4)
	drop code
save "tmp/NACE4d_desc", replace

*----------------------------------
* 1. Decomposition, by 6 industries
*----------------------------------
local v "S_i psi_i n_c_i thetabar_i W_c_i beta_i"

// prep file to save results
tempname memhold
postfile `memhold' sector N b_psi b_n_c b_thetabar b_W_c b_beta ///
				   se_psi se_n_c se_thetabar se_W_c se_beta sumtest ///
				   using "results/table_decomp_by_industry", replace

qui {
forvalues s = 1/6 {											
use "tmp/industries_$end", clear
	keep if industry == `s'
	noi di "Industry `s'"
	
// incidental parameters, drop cells with less than k obs	
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip

// sector demeaning        
    foreach x in `v' {									
		reghdfe ln`x',  a(FE_`x' = nace4_i) resid
        predict double r_ln`x', r
        drop ln`x'
        ren r_ln`x' ln`x'
    }	

// nobs	
    distinct vat_i
    local N = r(ndistinct)	
	
// decomposition on demeaned variables
	foreach x in psi_i n_c_i thetabar_i W_c_i beta_i {	
		reg ln`x' lnS_i
		local b_`x': di _b[lnS_i]
        local se_`x': di _se[lnS_i]
	}
	
// do components sum up to 1?	
	local sumtest = `b_psi_i' + `b_n_c_i' + `b_thetabar_i' + `b_W_c_i' + `b_beta_i'

// save output
    post `memhold' (`s') (`N') ///
	(`b_psi_i') (`b_n_c_i') (`b_thetabar_i') (`b_W_c_i') (`b_beta_i') ///
	(`se_psi_i') (`se_n_c_i') (`se_thetabar_i') (`se_W_c_i') (`se_beta_i') ///
    (`sumtest')
	}
}	
postclose `memhold'	

*-----------------------------
* 2. Decomposition, by NACE2/4
*-----------------------------
foreach D in 2 4 {
	
// prep file to save results	
tempname memhold
postfile `memhold' nace`D' N b_psi b_n_c b_thetabar b_W_c b_beta ///
				   se_psi se_n_c se_thetabar se_W_c se_beta sumtest using /// 
				   "results/table_decomp_by_`D'd_sector", replace
	
use "tmp/industries_$end", clear

// create counter to loop over
	levelsof(nace`D'_i), local(sector)											

qui {
	foreach s of local sector {
		use "tmp/industries_$end", clear
		keep if nace`D'_i ==`s'
		noi di "Sector `s'"
		
		// report only if >= 3 firms in sector (confidentiality)
		if _N>= $cutoff_ip {												
		
	// sector demeaning        
		foreach x in `v' {									
			reghdfe ln`x',  a(FE_`x' = nace`D'_i) resid
			predict double r_ln`x', r
			drop ln`x'
			ren r_ln`x' ln`x'
		}	

	// nobs	
		distinct vat_i
		local N = r(ndistinct)		
		
	// decomposition on demeaned variables
		foreach x in psi_i n_c_i thetabar_i W_c_i beta_i {	
			reg ln`x' lnS_i
			local b_`x': di _b[lnS_i]
			local se_`x': di _se[lnS_i]
		}
		
	// do components sum to 1?	
		local sumtest = `b_psi_i' + `b_n_c_i' + `b_thetabar_i' + `b_W_c_i' + `b_beta_i'	

	// save output
		post `memhold' (`s') (`N') ///
		(`b_psi_i') (`b_n_c_i') (`b_thetabar_i') (`b_W_c_i') (`b_beta_i') ///
		(`se_psi_i') (`se_n_c_i') (`se_thetabar_i') (`se_W_c_i') (`se_beta_i') ///
		(`sumtest')
		}
	}	
		else {
			clear
		}	
	}
	postclose `memhold'
}

// attach descriptions of NACE sectors to exported file
foreach D in 2 4 {
use "results/table_decomp_by_`D'd_sector", clear
	merge 1:1 nace`D' using "tmp/NACE`D'd_desc", nogen keep(match)
	save "results/table_decomp_by_`D'd_sector", replace
}

*---------------
* 4. Mean and sd. CV is then calculated as sd/mean  
*---------------
foreach D in 2 4 {
	use "results/table_decomp_by_`D'd_sector"
	tabstat b_*, stat(mean sd) save
	return list
	mat li r(StatTotal)
	putexcel set "results/mean_CV_`D'd_sector.xlsx", replace
	putexcel A1 = matrix(r(StatTotal)), names
}	
	
clear
