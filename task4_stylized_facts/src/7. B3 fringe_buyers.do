* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

B.3 Fringe buyers - Table 11
______________________________________________________________________________*/

*------------
* Column (2): Drop transactions below the 25th percentile (within firm)
*------------
use "output/network_i", clear

// keep firms with at least 5 buyers (25th percentile only meaningful for firms with at least 4 buyers)
	drop if n_c_i < 5
	
// compute quantiles (by firm)
	bys vat_i: egen p25 = pctile(lnm_ij), p(25)
	
// drop below p25	
	drop if lnm_ij < p25
	gcollapse (sum) Snet_top = m_ij (count) n_c_top = vat_j (first) nace4_i, by(vat_i)
		
// incidental parameters, drop cells with less than k obs 
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
		
// sector demeaning        
    foreach x in Snet_top n_c_top {	
		gen ln`x' = ln(`x')
		reghdfe ln`x',  a(FE_`x' = nace4_i) resid
        predict double r_ln`x', r
    }			
	
// firm-level regression
	eststo: reg r_lnSnet_top r_lnn_c_top, robust	
	
*--------------
* Column (3): Drop transactions below the 25th percentile (overall)
*--------------
use "output/network_i", clear

// keep firms with at least 5 buyers (25th percentile only meaningful for firms with at least 4 buyers)
	drop if n_c_i < 5

// compute quantiles (overall)
	egen p25 = pctile(lnm_ij), p(25)
	
// drop below p25	
	drop if lnm_ij < p25
	gcollapse (sum) Snet_top = m_ij (count) n_c_top = vat_j (first) nace4_i, by(vat_i)
		
// incidental parameters, drop cells with less than k obs 
	egen nobs = count(vat_i), by(nace4_i) 
	drop if nobs < $cutoff_ip
		
// sector demeaning        
    foreach x in Snet_top n_c_top {	
		gen ln`x' = ln(`x')
		reghdfe ln`x',  a(FE_`x' = nace4_i) resid
        predict double r_ln`x', r
    }			
	
// firm-level regression
	eststo: reg r_lnSnet_top r_lnn_c_top, robust
	
	esttab using "results/Snet_ranks_drop_p25.csv", ///
	b(3) se(3) r2(3) not nogaps star parentheses ar2 replace	
	