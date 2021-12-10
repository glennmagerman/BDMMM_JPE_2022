function [lnZ lnF] = lnZlnF(beta,draws,prm)

sd_z = beta(1);
sd_f = beta(2);
corrr = beta(3);
mu_f = beta(4);
mu_z = 0;

covv = corrr*sd_f*sd_z;
Omega = [sd_f^2 covv; covv sd_z^2];
Cho = chol(Omega);                                     
lnF = mu_f + draws(:,1).*Cho(1,1);
lnZ = mu_z + draws(:,2).*Cho(2,2) + draws(:,1).*Cho(1,2);
lnZ = (prm.sig-1).*lnZ;