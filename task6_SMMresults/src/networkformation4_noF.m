function [lnAnew lntheta lnpsi lnPtilde Pfinaltilde lnS Sinter lnZ] = networkformation4_noF(beta,prm,draws,lnA)

% Calculate adjacency matrix

a = prm.a;
mu = prm.mu;
gamma = 1;
G = prm.G;
oldmu = gamma*(1-prm.a)./prm.mu; 
buyers = prm.firms;
sellers = prm.firms;

mu_z=0;
sd_z = beta(1);
mu_f = beta(2);
sd_e = 4;

lnZ = (mu_z + draws(:,2).*sd_z)*(prm.sig-1);
lnF = mu_f*ones(prm.firms,1);
lnAF = zeros(prm.firms,1);  % All firms sell to final demand

% Calculate fixed point, given adjacency matrix A and Z
lng = log(prm.mu^(1-prm.sig));
[lnPtilde Pfinaltilde lnS Sinter] = vat_fp1(lnZ,log(oldmu),(1-prm.a)*gamma,lng,prm.wL,lnA,lnAF);
lnM = lnS + log((1-prm.a)/prm.mu);
lntheta = log(gamma) + lnM - lnPtilde;      % Buyer fixed effect
lnpsi = lnZ + (gamma*(1-prm.a)).*lnPtilde;  % Seller fixed effect
lnpinew = repmat(lntheta,1,buyers) + repmat(lnpsi',sellers,1) + prm.G + log((mu-1)/mu);

ElnF = repmat(lnF',sellers,1);
Anew = normcdf(lnpinew-ElnF,0,sd_e);
lnAnew = log(Anew);