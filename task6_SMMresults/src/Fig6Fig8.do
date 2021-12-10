
* ------------------------------------
* Figure 6: Restricted models
* ------------------------------------


cd /Users/andreas/Dropbox/Work/VAT_project/matlab_toJPE

import delim using sim_data_noZ.csv, clear
ren (v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12) (lnoutdeg lnindeg lnS lnSnet lnM m_outS m_inC lnms_Down lnms_Up lnm10 lnm50 lnm90)

foreach x of varlist ln* {
		reg `x' 
        predict double r_`x', r
}

binscatter r_lnms_Down r_lnoutdeg, n(20) savedata(noZ) replace
reg r_lnms_Down r_lnoutdeg
save /tmp/tmp_noZ, replace

import delim using sim_data_noF.csv, clear
ren (v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12) (lnoutdeg_noF lnindeg_noF lnS_noF lnSnet_noF lnM_noF m_outS_noF m_inC_noF lnms_Down_noF lnms_Up_noF lnm10_noF lnm50_noF lnm90_noF)
foreach x of varlist ln* {
		reg `x' 
        predict double r_`x', r
}
binscatter r_lnms_Down_noF r_lnoutdeg_noF, n(20) savedata(noF) replace
reg r_lnms_Down_noF r_lnoutdeg_noF
save /tmp/tmp_noF, replace

* Combine graphs
insheet using noF.csv, clear
ren (r_lnout r_lnms) (lnonoF lnmsnoF)
save /tmp/tmp_noF, replace
insheet using noZ.csv, clear
ren (r_lnout r_lnms) (lnonoZ lnmsnoZ)
append using /tmp/tmp_noF

twoway (scatter lnmsnoF lnonoF) (scatter lnmsnoZ lnonoZ, msymbol(T)), ///
graphregion(fcolor(white))  xtitle("lnZ") xtitle("Number of customers") ytitle("Avg. mkt. share")  ///
legend(label(1 "noF") label(2 "noZ") region(col(white)) )

gr export fit_restricted.eps, replace
gr export fit_restricted.pdf, replace


* ------------------------------------
* Figure 8 : Counterfactual
* ------------------------------------

import delim using cf_data_baseline.csv, clear
ren (v1 v2 v3) (lnZ lno2 lno1)
gen ch = lno2-lno1
binscatter ch lnZ, n(20) savedata(cf_base) replace
reg ch lnZ
save /tmp/tmp_base, replace

import delim using cf_data_nocorr.csv, clear
ren (v1 v2 v3) (lnZ lno4 lno3)
gen ch = lno4-lno3
binscatter ch lnZ, n(20) savedata(cf_nocorr) replace
reg ch lnZ
save /tmp/tmp_nocorr, replace

* Combine graphs
insheet using cf_base.csv, clear
ren (ch lnz) (ch1 lnz1)
save /tmp/tmp_base, replace
insheet using cf_nocorr.csv, clear
ren (ch lnz) (ch2 lnz2)
append using /tmp/tmp_base

twoway (scatter ch1 lnz1) (scatter ch2 lnz2, msymbol(T)), ///
graphregion(fcolor(white))  xtitle("lnZ") ytitle("Change in log # customers")  ///
legend(label(1 "Baseline") label(2 "No correlation") region(col(white)) )

gr export counterfactual.eps, replace
gr export counterfactual.pdf, replace
