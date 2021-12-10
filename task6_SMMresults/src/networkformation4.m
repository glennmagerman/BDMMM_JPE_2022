function [lnAnew lntheta lnpsi lnPtilde Pfinaltilde lnS Sinter lnAFnew] = networkformation4(beta,prm,draws,lnA,lnAF)

% Calculate adjacency matrix

a = prm.a;
mu = prm.mu;
gamma = 1;          % % Share of purchases from network
G = prm.G;
oldmu = gamma*(1-prm.a)./prm.mu; 
buyers = prm.firms;
sellers = prm.firms;
sd_e = 4;

[lnZ lnF] = lnZlnF(beta,draws,prm);
% Note: lnZ = (sigma-1)*lnz

% Calculate fixed point, given adjacency matrix A and Z
lng = log(prm.mu^(1-prm.sig));
[lnPtilde Pfinaltilde lnS Sinter] = vat_fp1(lnZ,log(oldmu),(1-prm.a)*gamma,lng,prm.wL,lnA,lnAF);
lnM = lnS + log((1-prm.a)/prm.mu);
lntheta = log(gamma) + lnM - lnPtilde;      % Buyer fixed effect
lnpsi = lnZ + (gamma*(1-prm.a)).*lnPtilde;  % Seller fixed effect

lnm = repmat(lntheta,1,buyers) + repmat(lnpsi',sellers,1) + prm.G - (prm.sig-1)*log(prm.mu);
lnpinew = lnm + log((prm.mu-1)/prm.mu);

ElnF = repmat(lnF',sellers,1);

Anew = normcdf(lnpinew-ElnF,0,sd_e);
lnAnew = log(Anew);
lnAFnew = ones(sellers,1);  