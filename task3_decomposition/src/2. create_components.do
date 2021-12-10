* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

/*______________________________________________________________________________

We first construct the data objects of the decomposition.
Then the components are constructed for each firm (non-demeaned).
______________________________________________________________________________*/

*-----------------------------------------
* 1. Construct variables for decomposition
*-----------------------------------------
// construct Snet, Mnet, lnS, lnbeta, xi_term
qui {
forvalues t = $start/$end {     
	
// load data for each cross-section	
	use "$task2/output/mobilitygroup_`t'", clear
	noi di "year `t'"
	
// merge firm observables (sales and NACE4)
	ren vat_i vat											
	merge m:1 vat using "output/firms_chars_`t'", ///
	nogen keep(match) keepusing(S nace4) 
    ren (vat S nace4) (vat_i S_i nace4_i)
	
// generate firm sales as maximum of sales in annac and sum of B2B sales	
	egen double Snet_i = total(m_ij), by(vat_i)				// do this sum after 2way FE for internal consistency
	noi replace S_i = max(S_i, Snet_i) if !missing(S_i)		// don't correct tiny firms with info on B2B sales only!
	
// generate logs 	
	gen double lnS_i = ln(S_i)
	gen double lnSnet_i = ln(Snet_i)
	gen double lnbeta_i = ln(S_i/Snet_i)
	gen double xi_term = exp(lntheta_j)*exp(lnw_ij)			
	save "tmp/network2_`t'", replace						// 436,715 sellers, 743,326 buyers	in 2014				
	}
}

*---------------------------------------------------------
* 2. list of firms with both a buyer and seller FE AND S_i 
*---------------------------------------------------------
// the decomposition can only be performed on firms with both a seller and buyer FE
forvalues t = $start/$end {   
	
	// sellers	
	use "tmp/network2_`t'", clear
		fcollapse (first) lnpsi lnS_i, by(vat_i) fast
		ren *_i *
		drop if missing(lnS)
	save "tmp/sellerFE", replace 

	// buyers
	use "tmp/network2_`t'", clear
		fcollapse (first) lntheta, by(vat_j) fast
		ren *_j *
		merge 1:1 vat using "tmp/sellerFE", nogen keep(match)
	save "tmp/decomp_list_`t'", replace	
}

*------------------------
* 3. Construct components (firm-level, non-demeaned) (Equation 2)
*------------------------
// lnS = lng + lnpsi + lnn_c + lnthetabar + lnW_c + lnbeta
qui {
forvalues t = $start/$end {     
	
	// load data	
	use  "tmp/network2_`t'", clear	
		noi di "Components `t'"
		
	// construct components at the firm level	
		gcollapse (sum) xi_i = xi_term (mean) lnthetabar_i = lntheta_j ///
		(count) n_c_i = vat_j (first) lnS_i lnSnet_i lnpsi_i lnbeta_i ///
		nace4_i lng, by(vat_i)
		gen double lnxi_i = ln(xi_i) 
		gen double lnn_c_i = ln(n_c_i)
		gen double lnW_c_i = ln(xi_i/(exp(lnthetabar_i)*n_c_i))
		keep vat_i ln* nace 
	
	// need FE_i, FE_j and sales_i for var decomp
		ren vat_i vat
		merge 1:1 vat using "tmp/decomp_list_`t'", nogen keep(match) keepusing(vat)	
		foreach x in S_i Snet_i psi_i xi_i n_c_i thetabar_i W_c_i beta_i {
			drop if missing(ln`x')
		}
		ren vat vat_i
		
	// sanity check: LHS = RHS? --> test value should be 0
		gen double test = lnS_i - lng - lnpsi_i - lnn_c_i - lnthetabar_i - lnW_c_i - lnbeta_i 
		noi sum test 
		drop test 
	save "output/components_`t'", replace		 				// 94,334 obs in 2014
	}
}			
clear

*--------------------------------------------------------------------
* 4. Sanity check: no missing observations for any of the components?
*--------------------------------------------------------------------
use "./output/components_2014", clear
	su															// all variables no missing obs

/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
       vat_i |     94,334    5.78e+08    1.93e+08   2.00e+08   9.00e+08
lnthetabar_i |     94,334    .1569765    .3650591  -1.634478   3.564543
       lnS_i |     94,334    13.94253    1.470185   6.684612   24.12205
    lnSnet_i |     94,334    12.63572    2.166892   6.235273   23.09863
     lnpsi_i |     94,334    .4238702    1.177972  -3.736128   8.887534
-------------+---------------------------------------------------------
    lnbeta_i |     94,334    1.306816    1.551072  -5.95e-08   10.41558
     nace4_i |     94,334    4496.266    1744.961        111       9609
         lng |     94,334    7.574616           0   7.574616   7.574616
      lnxi_i |     94,334    4.637232    1.907038  -.4629094   15.13195
     lnn_c_i |     94,334    3.336607    1.619613   .6931472   11.64907
-------------+---------------------------------------------------------
     lnW_c_i |     94,334    1.143648    .8135552  -9.34e-08    8.67841
*/	
