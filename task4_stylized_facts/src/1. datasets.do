* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This task creates the stylized facts (Section 2) of the paper.
______________________________________________________________________________*/

*-----------------
* 1. Prep datasets
*-----------------
// start from output 2wayFE regressions (network data)
use "$task2/output/mobilitygroup_$end", clear
	keep vat* m_ij lnm_ij									// drop FEs 
	
// keep only sellers also in decomposition sample (sample of analysis)
	merge m:1 vat_i using "$task3/output/components_$end", nogen ///
	keep(match) keepusing(nace4_i) 						
	distinct vat_i 											// 94,334
	
// add seller characteristics: S_i, nuts3_i, Snet_i, n_c_i
	gen year = $end
	ren vat_i vat 
	merge m:1 vat year using "$task1/output/firms_annac", ///	
	nogen keep(match) keepusing(S)
	merge m:1 vat year using "$task1/output/firms_zip_nuts", ///	
	nogen keep(match master) keepusing(nuts_3_name)
	encode nuts_3_name, gen(nuts3)
	drop nuts_3_name
	ren (vat S nace4 nuts3) (vat_i S_i nace4_i nuts3_i)
	egen n_c_i = count(vat_j), by(vat_i)
	egen Snet_i = total(m_ij), by(vat_i)

// add buyer characteristics: M_j, nace4_j, nust3_j, Mnet_j 
	ren vat_j vat
	merge m:1 vat year using "$task1/output/firms_annac", ///	
	nogen keep(match master) keepusing(M)					// M_j available for firms in annac	
	merge m:1 vat year using "$task1/output/firms_nace", ///	
	nogen keep(match master) keepusing(nace4)
	merge m:1 vat year using "$task1/output/firms_zip_nuts", ///	
	nogen keep(match master) keepusing(nuts_3_name)
	encode nuts_3_name, gen(nuts3)
	drop nuts_3_name 
	ren (vat M nace4 nuts3) (vat_j M_j nace4_j nuts3_j)
	distinct vat_j											// 730,507
	
	egen Mnet_j = total(m_ij), by(vat_j)					// Network inputs
	replace M_j = max(M_j, Mnet_j) if !missing(M_j)			
	replace M_j = Mnet_j if missing(M_j)					
	
	gen lnshare_Mnet_j = ln(m_ij/Mnet_j)
	gen lnshare_M_j = ln(m_ij/M_j)
	su
save "output/network_i", replace

*--------------------------
* 2. Collapse to firm level
*--------------------------
// seller i characteristics
use "output/network_i", clear
	gcollapse (mean) avglnshare_M_j = lnshare_M_j avglnshare_Mnet_j = lnshare_Mnet_j ///
	(first) S_i Snet_i n_c_i nace4_i nuts3_i, by(vat_i)	
	gen Snetn_c_i = Snet_i/n_c_i
save "output/seller_chars_$end", replace	
// vars: vat_i avglnshare_M_j avglnshare_Mnet_j S_i Snet_i n_c_i Snetn_c_i  nace4_i  nuts3_i
	

