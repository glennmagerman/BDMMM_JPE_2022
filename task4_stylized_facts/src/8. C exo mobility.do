* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

C Exogenous mobility 
______________________________________________________________________________*/


*----------------------
* 1. Figure 9 - Heatmap
*----------------------
use "output/network_i", clear

// incidental parameters, drop cells with less than k obs	(consistency sample)
	egen nobs = count(vat_i), by(nace4_i) 
	egen nobs2 = count(vat_j), by(nace4_j)
	drop if nobs < $cutoff_ip 
	drop if nobs2 < $cutoff_ip 
	
// Calculate average buyer and seller size (leave-out mean)
	bys vat_i: egen double tmp = total(lnm_ij)				// seller
	bys vat_i: egen double deg = count(lnm_ij)
	gen mSi = (tmp-lnm_ij)/(deg-1)
	drop if deg==1
	drop tmp deg
	
	bys vat_j: egen double tmp = total(lnm_ij)				// buyer
	bys vat_j: egen double deg = count(lnm_ij)
	gen mMj = (tmp-lnm_ij)/(deg-1)
	drop if deg==1
	drop tmp deg
	
// calculate deciles	
	preserve													// S and B deciles (hence unequal obs in terms of PAIRS in each cell)
		contract vat_i mSi
		xtile QmSi = mSi, n(10)
		drop _freq
		drop if missing(QmSi)
		save "tmp/sellers", replace
	restore
	preserve
		contract vat_j mMj
		xtile QmMj = mMj, n(10)
		drop _freq
		drop if missing(QmMj)
		save "tmp/buyers", replace
	restore
	merge m:1 vat_i mSi using "tmp/sellers", nogen
	merge m:1 vat_j mMj using "tmp/buyers", nogen

	drop if vat_i==.
	
	collapse (mean) lnm_ij (count) numpairs=vat_i ///
	(semean) se=lnm_ij, by(QmSi QmMj)
 	
// graph
	heatplot lnm_ij QmMj QmSi, colors(spmap greys) ///
	aspectratio(1) cuts(6.5(0.2)10) statistic(asis)  ///
	xtitle("Seller decile group") ytitle("Buyer decile group")
	graph export "results/heatmap.eps", replace
	graph save "results/heatmap", replace
	
*---------------------
* 2. Figure 10 - Lines
*---------------------
sort QmSi QmMj
forvalues i = 1/10 {
	local graphs `graphs' (line lnm QmMj if QmSi == `i')
	sum lnm if QmSi==`i' & QmMj==1, meanonly
    local call `call' text(`r(mean)' .8 "`i'", place(w) size(3.4)) 
	}
graph twoway `graphs', graphregion(color(white)) bgcolor(white) `call' legend(off)
	graph export "results/exo_mobility_lines.eps", replace
	graph save "results/exo_mobility_lines", replace

*--------------------------------------
* 2. Table 12 - exogenous mobility test
*--------------------------------------
// Calculate average buyer and seller size (leave-out mean)
use "output/network_i", clear

// incidental parameters, drop cells with less than k obs	(consistency sample)
	egen nobs = count(vat_i), by(nace4_i) 
	egen nobs2 = count(vat_j), by(nace4_j)
	drop if nobs < $cutoff_ip 
	drop if nobs2 < $cutoff_ip 
	
	keep vat* lnm_ij 
	bys vat_i: egen double tmp = total(lnm_ij)				// seller
	bys vat_i: egen double deg = count(lnm_ij)
	gen mSi = (tmp-lnm_ij)/(deg-1)
	drop if deg==1
	drop tmp deg
	
	bys vat_j: egen double tmp = total(lnm_ij)				// buyer
	bys vat_j: egen double deg = count(lnm_ij)
	gen mMj = (tmp-lnm_ij)/(deg-1)
	drop if deg==1
	drop tmp deg
	
// calculate deciles	
	preserve													// S and B deciles (hence unequal obs in terms of PAIRS in each cell)
		contract vat_i mSi
		xtile QmSi = mSi, n(10)
		drop _freq
		drop if missing(QmSi)
		save "tmp/sellers", replace
	restore
	preserve
		contract vat_j mMj
		xtile QmMj = mMj, n(10)
		drop _freq
		drop if missing(QmMj)
		save "tmp/buyers", replace
	restore
	merge m:1 vat_i mSi using "tmp/sellers", nogen
	merge m:1 vat_j mMj using "tmp/buyers", nogen
	
	collapse (mean) lnm_ij (count) n=vat_i (semean) se=lnm_ij, by(QmSi QmMj)

	tsset QmSi QmMj
	gen ml1 = lnm_ij-l1.lnm_ij
	gen ml9 = lnm_ij-l9.lnm_ij if QmMj==10
	gen sel1 = sqrt(se^2+l.se^2)
	gen sel9 = sqrt(se^2+l9.se^2) if QmMj==10

	tsset QmMj QmSi
	gen ch11 = ml1-l1.ml1
	gen se11 = sqrt(sel1^2+l1.sel1^2)
	gen df11 = (sel1^2+l1.sel1^2)^2/(sel1^2/(n-1)+l1.sel1^2/(n-1))
	gen t11 = ch11/se11
	gen sig11 = abs(t11)>invttail(df11,0.05)
	drop if missing(ml1)
	keep QmSi QmMj ml1 ch11 sig11 n se11
	reshape wide ml1 ch11 sig11 n se11, i(QmSi) j(QmMj)
save "results/exo_mobility_test", replace
