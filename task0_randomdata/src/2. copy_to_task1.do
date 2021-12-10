* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

*---------------------------------------------------
* 1. Move random data to task1 if no real data there
*---------------------------------------------------
copy "output/Belgian B2B flows_large_cleaned_n_balanced.dta" "$task1/input/Belgian B2B flows_large_cleaned_n_balanced.dta" 
copy "output/NBB_B2B_sample_large_nace_n_zip_codes.dta" "$task1/input/NBB_B2B_sample_large_nace_n_zip_codes.dta"
copy "output/NACE_0214.dta" "$task1/input/NACE_0214.dta"
copy "output/annualized_annac_02_14.dta" "$task1/input/annualized_annac_02_14.dta"
