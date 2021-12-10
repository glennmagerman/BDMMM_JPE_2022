* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: June 4, 2020

/*______________________________________________________________________________
This codes performs some cleaning on the raw datasets.

NACE codes:
- replace nace4 = nace2*100 if missing nace4 (some report only 2digit)
- fill in 1-year gaps in panel (only interpolated, not at ends of panel)

Location:
- fill in 1-year gaps in panel (only interpolated, not at ends of panel)
- merge zip codes with NUTS codes (aggregation to 44 arrondissements or 11 provinces)

Annual accounts:
- drop if missing sales or inputs expenditures (needed objects for analysis)
- drop if less than 1 FTE, or missing FTE (sole traders, shell and managment companies)
- keep only firms active in the B2B network
______________________________________________________________________________*/

*--------------
* 1. NACE codes
*--------------
use "tmp/firms_nace", clear

// fill missing nace4 with nace2 if available
	replace nace4 = nace4*100 if nace4 < 100				// some report 2digit only		
		
// fill in panel gaps if missing in one year 	
	sort vat year											// fill in panel gaps						
	bys vat: replace nace4 = nace4[_n-1] if missing(nace4)	// backwards	
	gsort vat -year
	bys vat: replace nace4 = nace4[_n-1] if missing(nace4)	// forwards	
	
	keep year vat nace4
	drop if missing(nace4)
save "output/firms_nace", replace
	
*-----------------	
* 2. location info	
*-----------------	
use "tmp/firms_zip", clear

// fill in panel gaps if missing in one year 	
	sort vat year										
	bys vat: replace zip = zip[_n-1] if missing(zip)	// backwards	
	gsort vat -year
	bys vat: replace zip = zip[_n-1] if missing(zip)	// forwards	
	
	keep year vat zip 
	drop if missing(zip)
	
// attach NUTS code for each zip 	
	merge m:1 zip using "output/zip_to_nuts", nogen keep(match master) ///
	keepusing(zip_name nuts_3_code nuts_3_name nis) 
save "output/firms_zip_nuts", replace	
	
*-------------------	
* 3. Annual accounts	
*-------------------
use "tmp/firms_annac", clear

// cleaning and selection criteria
	drop if missing(S) | missing(M)							// if 0, will drop out of network
	drop if missing(FTE) | FTE < 1 							// sole traders, shell or management companies	
	
// keep firms active in network
	merge 1:1 vat year using "output/firms_list", nogen keep(match)
save "output/firms_annac", replace 							// 1,380,988 obs

clear
