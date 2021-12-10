* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

*-----------
* 1. network
*-----------
// identify groups for both seller and buyer
// drop all intra-firm flows
// sum all ingoing/outgoing flows with partners

use "$task1/output/network_2014", clear							// 17,304,408 obs
*use "./output/network_2014", clear							// 17,304,408 obs
// merge group ID on both seller and buyer side
	ren vat_i vat
	merge m:1 vat using "./input/group_id_14", keep(match master)
	replace head_vat = vat if _m == 1
	ren head_vat vat_i
	drop _m vat
	
	ren vat_j vat
	merge m:1 vat using "./input/group_id_14", keep(match master)
	replace head_vat = vat if _m == 1
	ren head_vat vat_j
	drop _m vat

// calculate intrafirm flows	
	gcollapse (sum) m_ij, by(vat_i vat_j year)				// 16,586,561
	preserve	
		keep if vat_i == vat_j
		ren vat_i vat
		drop vat_j
		ren m_ij intragroup
		save "./tmp/intragroup_trade", replace
	restore
	drop if vat_i == vat_j
save "./output/network_robVAT_2014", replace				// 16,574,824

*---------
* 2. firms
*---------
use "$task1/output/firms_annac", clear
	keep if year == 2014
	merge 1:1 vat year using "$task1/output/firms_nace", ///
	nogen keep(match master) keepusing(nace4)

	merge 1:1 vat year using "./input/group_id_14", keep(match master)
	replace head_vat = vat if _m == 1
	drop _m vat
	ren head_vat vat
	order vat year, first
	gsort vat year -S
	bys vat year: gen main_nace = nace4[1]
	gcollapse (sum) M S FTE (first) nace4 = main_nace, by(vat year)
	merge 1:1 vat using "./tmp/intragroup_trade", keep(match master)

	replace M = M - intragroup if _m == 3
	replace S = S - intragroup if _m == 3
	drop if S <= 0 | M <= 0
	drop intragroup _m
	
	// cleaning and selection criteria
	drop if missing(S) | missing(M)							// if 0, will drop out of network
	drop if missing(FTE) | FTE < 1 							// sole traders, shell or management 
save "./output/firms_robVAT_2014", replace					// 100,691 obs
	
