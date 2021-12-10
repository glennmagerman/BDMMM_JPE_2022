function [lnA lntheta lnpsi lnPtilde Pfinaltilde lnS Sinter lnZ] = iterate_network_noZ(beta,prm,draws)

% Given F and Z, find equilibrium network


% Initial network (complete network)
lnA = zeros(prm.firms);

diff = 1;
cc=0;
while diff>1e-6
  [lnAnew lntheta lnpsi lnPtilde Pfinaltilde lnS Sinter lnZ] = networkformation4_noZ(beta,prm,draws,lnA);
  tmp = (lnAnew-lnA).^2;
  diff = nansum(tmp(:));
  lnA = lnAnew;
  cc=cc+1;  
  if cc>400 disp('Error: Too many iterations'); break; end;
end
end