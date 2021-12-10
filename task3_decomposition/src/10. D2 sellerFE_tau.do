* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

This code evalues the link between the seller FE and the average market share 
(Appendix D.2)
______________________________________________________________________________*/

*--------------------------------	
* Correlation between psi and tau
*--------------------------------	
use "$task2/output/mobilitygroup_$end", clear
	gen year = $end
	ren vat_j vat
	merge m:1 vat year using "$task1/output/firms_annac", nogen keep(match master) keepusing(M)
	ren (vat M) (vat_j M_j)
	
// create market shares	
	egen Mnet_j = total(m_ij), by(vat_j)
	replace M_j = max(M_j, Mnet_j) if !missing(M_j)			// 1.3 mln out of 17mln
	replace M_j = Mnet_j if missing(M_j)
	gen share_Mnet_j = m_ij/Mnet_j	
	gen share_M_j = m_ij/M_j
	gen lnshare_M_j = ln(share_M_j)
	gen lnshare_Mnet_j = ln(share_Mnet_j)

// tau of all the suppliers of j
	gen tmp = exp(lnw_ij + lnpsi)
	egen tau = sum(tmp),  by(vat_j) 
	gen lntau = log(tau)
	collapse (first) lnpsi (mean) lnshare_M_j lnshare_Mnet_j lntau, by(vat_i)

// Correlation seller fixed effect and geometric average market share
	scatter lnpsi lnshare_Mnet_j
	graph export "results/scatter_sellerFE_avgMktShare.png", replace

// Correlation psi-tau and geometric average market share
	gen new = lnpsi-lntau
	scatter new lnshare_Mnet_j								// these line up perfectly
	graph export "results/scatter_new_avgMktShare.png", replace

	corr lnshare_M_j lnshare_Mnet_j lnpsi lntau	

