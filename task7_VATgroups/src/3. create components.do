* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

*-----------------------------------------
* 1. Construct variables for decomposition
*-----------------------------------------
// construct Snet, Mnet, lnS, lnbeta, xi_term
use "./output/mobilitygroup_robVAT_2014", clear
	ren vat_i vat											// attach firm chars						
	merge m:1 vat using "./output/firms_robVAT_2014", ///
	nogen keep(match) keepusing(S nace4) 
    ren (vat S nace4) (vat_i S_i nace4_i)
	
	egen double Snet_i = total(m_ij), by(vat_i)				// sum after AKM for internal consistency
	replace S_i = max(S_i, Snet_i) if !missing(S_i)			// don't correct small firms with B2B sales only!
	
	gen double lnS_i = ln(S_i)
	gen double lnSnet_i = ln(Snet_i)
	gen double lnbeta_i = ln(S_i/Snet_i)
	gen double xi_term = exp(lntheta_j)*exp(lnw_ij)			// to construct downstream components
	save "./tmp/network2", replace							// 436,715 sellers, 743,326 buyers					

*---------------------------------------------------------
* 2. list of firms with both a buyer and seller FE AND S_i (needed for decomp)
*--------------------------------------------------------- 
use "./tmp/network2", clear
	fcollapse (first) lnpsi lnS_i, by(vat_i) fast
	ren *_i *
	drop if missing(lnS)
save "./tmp/sellerFE", replace 
use "./tmp/network2", clear
	fcollapse (first) lntheta, by(vat_j) fast
	ren *_j *
	merge 1:1 vat using "./tmp/sellerFE", nogen keep(match)
save "./tmp/decomp_list", replace	

*------------------------
* 3. Construct components (firm-level, raw)
*------------------------
// lnS lng lnpsi lnn_c lnthetabar lnW_c lnbeta    
use  "./tmp/network2", clear	
	gcollapse (sum) xi_i = xi_term (mean) lnthetabar_i = lntheta_j ///
	(count) n_c_i = vat_j (first) lnS_i lnSnet_i lnpsi_i lnbeta_i ///
	nace4_i lng, by(vat_i)
	gen double lnxi_i = ln(xi_i) 
	gen double lnn_c_i = ln(n_c_i)
	gen double lnW_c_i = ln(xi_i/(exp(lnthetabar_i)*n_c_i))	
	keep vat_i ln* nace 
	
// need both FE and sales for var decomp
	ren vat_i vat
	merge 1:1 vat using "./tmp/decomp_list", nogen keep(match) keepusing(vat)	
	foreach x in S_i Snet_i psi_i xi_i n_c_i thetabar_i W_c_i beta_i {
		drop if missing(ln`x')
	}
	ren vat vat_i
// identity test: do components sum up?	
	gen double test = lnS_i - lng - lnpsi_i - lnn_c_i - lnthetabar_i - lnW_c_i - lnbeta_i 
	noi sum test 
	drop test 
save "./output/components_robVAT", replace		 				// 94,334 obs in 2014
clear

*----------
* 4. checks
*----------
use "./output/components_robVAT", clear
	su															// all variables no missing obs
