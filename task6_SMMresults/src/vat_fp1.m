function [lnP Pfinaltilde lnS Sinter] = vat_fp1(lnztilde,lnmu,ainv,lng,wL,lnA,lnAF)

% Calculate equilibrium lnPtilde and lnS

% ps. lnmu is here (1-alpha)/markup

N = size(lnA,2);

lnP = zeros(N,1);
diff = 1;
cc=0;
while diff>1e-8
  xx = exp(lnA + repmat((ainv.*lnP+lnztilde+lng)',N,1));
  lnPnew = log(mean(xx,2));
  tmp = lnPnew-lnP;
  diff = tmp'*tmp;
  lnP = lnPnew;
  cc=cc+1;
  if cc>1e4 disp('lnP: Too many iterations'); break; end;
end


Pfinaltilde = mean(exp(lnAF + ainv.*lnP + lnztilde + lng));    

% Sales fixed point (forward linkages)
diff = 1;
cc=0;
lnS = zeros(N,1);

while diff>1e-8
  const = exp(lng+lnztilde+ainv.*lnP);
  xx = exp(lnA + repmat(lnmu+lnS-lnP,1,N));   
  Sinter = const.*mean(xx,1)';
  Sfinal = const.*exp(lnAF).*wL/Pfinaltilde;  
  lnSnew=log(Sfinal+Sinter);
  tmp = lnSnew-lnS;
  diff = tmp'*tmp;
  lnS = lnSnew;  
  cc=cc+1;
  if cc>1e4 disp('lnS: Too many iterations'); break; end;

end
end