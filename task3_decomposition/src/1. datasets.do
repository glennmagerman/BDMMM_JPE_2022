* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

Keep seller and buyer fixed effects from the two-way FE regression. 
(collapse to firm level from bilateral observations)
Merge with other observables at the frm level to construct the decomposition.
______________________________________________________________________________*/

*-----------
* 1. Firm FE
*-----------
// retain 1 FE per seller/buyer from 2way FE
forvalues t = $start/$end {
use "$task2/output/mobilitygroup_`t'", clear
	gcollapse (first) lnpsi_i, by(vat_i) fast
	ren *_i *
save "tmp/sellerFE", replace
use "$task2/output/mobilitygroup_`t'", clear
	gcollapse (first) lntheta_j, by(vat_j) fast
	ren *_j *
	merge 1:1 vat using "tmp/sellerFE", nogen
save "output/firm_FE_`t'", replace
}

*------------------------
* 2. Firm characteristics
*------------------------
// merge firms datasets for analysis
forvalues t = $start/$end {
	use "output/firm_FE_`t'", clear
	gen year = `t'
	merge 1:1 vat year using "$task1/output/firms_annac", nogen keep(match master)
	merge 1:1 vat year using "$task1/output/firms_nace", nogen keep(match master)
	merge 1:1 vat year using "$task1/output/firms_zip_nuts", nogen keep(match master)
save "output/firms_chars_`t'", replace	
}
