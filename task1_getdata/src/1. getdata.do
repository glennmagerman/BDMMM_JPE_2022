* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: March 26, 2020

/*______________________________________________________________________________

This code loads the following data:
- NBB B2B Transactions dataset, with info on Belgian firm-to-firm sales.
- firm NACE codes, with info on the main 4-digit NACE sector code of the firm.
- firm ZIP codes, with info on the postal code of the firm. 
- zip to NUTS, a mapping from zip codes to NUTS administrative units.
- annual accounts, with standard firm characteristics like sales, employment etc.
- VAT declarations for missing info on sales and inputs for small firms.
______________________________________________________________________________*/

*---------------
* 1. B2B network
*---------------
// Load the B2B network and split the data by year 
forvalues t = $start/$end { 						
	use "input/Belgian B2B flows_large_cleaned_n_balanced", clear
	keep if year == `t'
	keep year vat* sales_ij
	ren sales_ij m_ij
	format vat* %12.0f
	save "output/network_`t'", replace						// 17,304,408 in 2014
}
// vars: year vat_i (seller) vat_j (buyer) m_ij (sales value from i to j)

// Create nodes list: firms that are active in the network. 
*  Note: Some firms in other datasets might not be in the B2B network. We drop 
*  these later on by merging with this nodes list.
forvalues t = $start/$end {
	use "output/network_`t'", clear
	
	// supplier side
	preserve
		fcollapse (first) m_ij, by(vat_i) fast				
		ren *_i *
		keep vat
		tempfile sellers 
		save `sellers'										// 590,271 in 2014
	restore
	
	// buyer side
	fcollapse (first) m_ij, by(vat_j) fast					// 840,607 in 2014
	ren *_j *
	keep vat
	
	// merge both sides
	fmerge 1:1 vat using `sellers', nogen					// 859,733 in 2014
	gisid vat 												// sanity check: unit of observation is correct and unique
	gen year = `t'
	save "tmp/firmslist_`t'", replace
}
// create panel of firmslist
use "tmp/firmslist_2002", clear	
	forvalues t = 2003/$end {
		append using "tmp/firmslist_`t'"
	}
save "output/firms_list", replace	

// vars: year vat

*--------------------
* 2. firms NACE codes (panel)
*--------------------
// Main activity of the firm by NACE Rev2 (2008) 4-digit from the CBE. 
// NACE codes are already harmonized over time to cope with changes in the classification.
use "input/NACE_0214", clear			

	// merge with 2nd data source to maximize the number of observations
	merge 1:1 vat year using "input/NBB_B2B_sample_large_nace_n_zip_codes", ///
	nogen keepusing(C_NACE)									// adds 365k obs
	ren cnace nace
	
	// use 2nd dataset if missing in main dataset
	replace nace = C_NACE if missing(nace)
	
	// extract 4-digit NACE codes (initially reported at 5-digit level)
	gen nace4 = substr(nace,1,4)							
	
	// wrap up
	destring nace4, replace
	keep vat year nace4
	gisid vat year											// sanity check: unit of observation is correct and unique
save "tmp/firms_nace", replace	
// vars: vat year nace4										// 26,805,047 total

*-------------------
* 3. firms locations (panel)
*-------------------
// location info at zip/postal code level
use "input/NBB_B2B_sample_large_nace_n_zip_codes", clear	
	keep if year >= 2002 & year <= 2014	
	keep vat year POST_CODE	
	ren POST_CODE zip										// sanity check: unit of observation is correct and unique
	gisid vat year 
save "tmp/firms_zip", replace							// 9,766,841 total
// vars: vat year zip
	
*---------------	
* 4. zip to NUTS
*---------------
// mapping to aggregate postal codes to NUTS3 level (44 arrondissements)
use	"input/zip_nuts_Belgium", clear
	keep zip zip_name nuts_3_code nuts_3_name nis
	
	// Verviers is split into a German and a French part
	replace nuts_3_name = "Verviers (French)" if nuts_3_code == "BE335"
	replace nuts_3_name = "Verviers (German)" if nuts_3_code == "BE336"
	drop if missing(zip)
save "output/zip_to_nuts", replace												
// vars: vat year zip zip_name nuts_3_code nuts_3_name		// 1,144 postal codes

*-------------------
* 5. Annual accounts (panel)
*-------------------
// firms annual accounts
use "input/annualized_annac_02_14", clear					// already includes S and M for small firms from the VAT decl 

	// keep turnover, input expenditures, labor cost and employment
	ren (turnover total_inputs laborcost empl) (S M wL FTE)  
	keep year vat S M wL FTE
	gisid vat year
save "tmp/firms_annac", replace							// 4,756,846 total
// vars: year vat M S wL L

clear
