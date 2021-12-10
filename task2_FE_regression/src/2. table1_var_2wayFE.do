* Project: Origins of Firm Heterogeneity, JPE
* Author: Glenn Magerman (glenn.magerman@ulb.be)
* Version: Nov 4, 2021

*------------------------------------------------
* 1. Number of observations, R^2 and adjusted R^2 
*------------------------------------------------
use "results/2wayFE", clear

	keep if t == 2014
	format N %12.0f
	format R2 R2_adj %3.2f
	
	su
	/*
	t		N			R2		R2_adj	Fstat
	2014	17054274	0.43	0.39	0
	*/

*-------------------------------------------------------	
* 2. Variance shares of psi, theta, and 2xcov(psi,theta)
*-------------------------------------------------------
use "output/mobilitygroup_2014", clear
	gen lnpsi_theta = lnpsi_i + lntheta_j 

	// variance 
	foreach x in psi_i theta_j psi_theta {
		su ln`x'
		gen var_`x' = r(Var)	
	}
	di var_psi_i/var_psi_theta				// 0.66
	di var_theta/var_psi_theta				// 0.32

	// covariance
	corr lnpsi_i lntheta_j, cov		
	gen cov = r(cov_12)
	di 2*cov/var_psi_theta					// 0.02


