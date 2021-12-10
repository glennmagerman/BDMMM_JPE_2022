---------------------------------------
README 
Nov 2 andreamo@econ.uio.no
---------------------------------------


- matching_2019.m : Main file Matlab for SMM estimation, model fit and counterfactuals.

  The file produces:
  Figure 7
  All results contained in Table 5
  Data for Figure 5 : distributions.csv
  Data for Figure 6 : sim_data_noZ.csv and sim_data_noF.csv
  Data for Figure 8 : cf_data_baseline.csv and cf_data_nocorr.csv

- Fig6Fig8.do : Stata do file for producing Figure 6 and 8.

Other files:

- iterate_network.m performs the fixed point associated with eq (8) in the paper.
- networkformation4.m calculates the equilibrium network.
- vat_fp1.m performs the fixed points associated with eqs (6) and (7) in the paper.
- SMM_network.m calculates the simulated moments and the objective function.
