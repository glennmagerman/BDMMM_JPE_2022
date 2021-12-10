function [lnA lntheta lnpsi lnPtilde Pfinaltilde lnS Sinter lnAF] = iterate_network(beta,prm,draws)

% Given F and Z, find equilibrium network

% Initial network (complete network)
lnA = zeros(prm.firms);
lnAF = zeros(prm.firms,1);
diff = 1;
cc=0;
while diff>1e-6  
  [lnAnew lntheta lnpsi lnPtilde Pfinaltilde lnS Sinter lnAFnew] = networkformation4(beta,prm,draws,lnA,lnAF);
  tmp = (lnAnew-lnA).^2;
  diff = nansum(tmp(:));
  lnA = lnAnew;
  lnAF = lnAFnew;
  cc=cc+1;  
  if cc>400 disp('Error: Too many iterations'); break; end;
end

if cc>200 disp('Warning: More than 200 iterations'); end;
end