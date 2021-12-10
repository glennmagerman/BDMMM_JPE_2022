function [ss mom] = SMM_network(beta,prm,draws)

% Calculate simulated moments

[lnA lntheta lnpsi lnPtilde Pfinaltilde lnS Sinter lnAF] = iterate_network(beta,prm,draws);
R = prm.firms;
A = exp(lnA);
lnoutdeg = log(mean(A))';          
lnindeg = log(mean(A,2));

% % Market share calculations
lnM = lnS + log((1-prm.a)/prm.mu);
lnm = repmat(lntheta,1,prm.firms) + repmat(lnpsi',prm.firms,1); % A seller is a column
lnms_Down = mean((lnm-log(R)-repmat(lnM,1,R)),1)';        
% lnms_Up= mean((lnm-log(R)-repmat(lnS',R,1)),2);        

% Moment #1
mom(1) = var(log(Sinter));

% Moment #2
mom(2) = var(lnoutdeg);

% Moment #3
b=regress(lnms_Down,[ones(prm.firms,1) lnoutdeg]);
mom(3) = b(2);

% Moment #4
mom(4) = mean(lnoutdeg);

% Decomposition moments
lnSinter = log(Sinter);
for i=1:R
  mybuyers = A(:,i);
  lnthetabar(i,1) = mean(mybuyers.*lntheta);
  Omega_c(i,1) = sum(mybuyers.*exp(lntheta))/(exp(lnoutdeg(i))*exp(lnthetabar(i,1)));
end

[b ci]=regress(lnoutdeg,[ones(prm.firms,1) lnSinter]);
mom(5)=b(2);
[b ci]=regress(lnthetabar,[ones(prm.firms,1) lnSinter]);
mom(6)=b(2);
[b ci]=regress(log(Omega_c),[ones(prm.firms,1) lnSinter]);
mom(7)=b(2);

diff = mom-prm.mom;
ss = diff*prm.W*diff';
end