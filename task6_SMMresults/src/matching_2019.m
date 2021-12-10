%% Estimate model : SMM

clear
close all
workdir = '/Users/Andreas/Dropbox/Work/VAT_project/matlab_toJPE';
cd(workdir);

%
% Parameters
%

prm.firms = 400;     % Number of firms in simulation
rng('default'); rng(1);
draws = randn(prm.firms,2);

prm.a = .24;         % Labor cost share
prm.mu = 1.24;       % Mark-up
prm.sig = prm.mu/(prm.mu-1);    % Elasticity of substitution
prm.G = 0;           % Constant term (redundant)
prm.wL = 1;          % Final demand, normalized to one.

%
% Empirical moments
%
prm.mom = [3.12 1.87 -.08 -8.12 .51 .05 .25];   
% Moments: Var(lnSnet), Var(lnn_c), Slope coeff lnPi = a+blnn_c,
% mean(lnn_c), decomposition: # cust, decomposition: avg. customer capability, decomposition: Covariance term
 
% Initial values
beta0 = [.2 2.4 .88 18];         
% Parameters: sd(lnZ), sd(lnF), corr(lnF,lnZ), mu(lnF)

prm.W = eye(length(prm.mom));       % Identity weighting matrix

f = @(beta) SMM_network(beta,prm,draws);

options = optimset('Display','iter','TolFun',1e-6,'TolX',1e-6);
options = optimset(options,'MaxFunEvals',30000);
options = optimset(options,'Algorithm','interior-point');
options = optimset(options,'PlotFcn',{@optimplotx,@optimplotfval,@optimplotfirstorderopt});

% Lower and upper bounds of parameters
lb = [.1 .8 -1 -30]; ub = [4 4 1 22];

tic; [r1.beta,r1.fval,r1.exitflag,r1.output,r1.lambda,r1.grad,r1.hessian] = fmincon(f,beta0,[],[],[],[],lb,ub,[],options); toc;

% Do we match moments?
[ss mom] = SMM_network(r1.beta,prm,draws);
disp('True / simulated moments'); disp([prm.mom' mom']);
disp('Estimates'); disp(r1.beta);

%% Estimate the model using the inverse of the variance-covariance matrix of the moments

fid = fopen(strcat(workdir,'/bootstrap_moments.csv'));
N = textscan(fid, '%f %f %f %f %f %f %f','delimiter',',');
fclose(fid);
prm.momB=[];
for i=1:7
  prm.momB(:,i) = N{i};
end
prm.momB(:,4) = prm.momB(:,4)-log(94147);       % Mean log outdegree relative to the number of firms
covmom = cov(prm.momB);
prm.W = inv(covmom);  % Inverse of variance-covariance matrix

f = @(beta) SMM_network(beta,prm,draws);

tic; [r2.beta,r2.fval,r2.exitflag,r2.output,r2.lambda,r2.grad,r2.hessian] = fmincon(f,beta0,[],[],[],[],lb,ub,[],options); toc;

% Do we match moments?
[ss2 mom2] = SMM_network(r2.beta,prm,draws);
disp('True / simulated moments'); disp([prm.mom' mom2']);
disp('Estimates'); disp(r2.beta);


%% Bootstrap standard errors

fid = fopen(strcat(workdir,'/bootstrap_moments.csv'));
N = textscan(fid, '%f %f %f %f %f %f %f','delimiter',',');
fclose(fid);
prm.momB=[];
for i=1:7
  prm.momB(:,i) = N{i};
end
prm.momB(:,4) = prm.momB(:,4)-log(94147);       % Mean log outdegree relative to the number of firms
prm.momB(201:end,:)=[];     % 200 repetitions

beta0 = [.2 2.4 .88 18];         
lb = [.1 .8 -1 -30];
ub = [4 4 1 22];

options = optimset('Display','iter','TolFun',1e-6,'TolX',1e-6);
options = optimset(options,'MaxFunEvals',30000);
options = optimset(options,'Algorithm','interior-point');
options = optimset(options,'PlotFcn',{@optimplotx,@optimplotfval,@optimplotfirstorderopt});

rep = size(prm.momB,1);
for i=1:rep
  prm.mom = prm.momB(i,:);  
  f = @(beta) SMM_network(beta,prm,draws);
  tic; [beta,fval,exitflag,output,lambda,grad,hessian] = fmincon(f,beta0,[],[],[],[],lb,ub,[],options); toc;
  betaB(i,:) = beta;    
end

std(betaB)
mean(betaB)
    

%% Calculate Andrews et al sensitivity (Figure 7)

savefigures=0;
prm.firms = 400;
rng('default'); rng(1);
draws = randn(prm.firms,2);

% Estimates
r1.beta = [0.2381 2.2342 0.8616 18.1120];         

% Moments
prm.mom = [3.12 1.87 -.08 -8.12 .51 .05 .25];   

g = @(beta) SMM_network_mom(beta,prm,draws);

J = fdjacobian(g,r1.beta,.1); % Jacobian, #moments x #params (7x4)
L = inv(J'*J)*J'; % (4x7)
disp('Lambda');
disp(L);

% Scale L by the standard deviation of the moments
fid = fopen(strcat(workdir,'/bootstrap_moments.csv'));
N = textscan(fid, '%f %f %f %f %f %f %f','delimiter',',');
fclose(fid);
prm.momB=[];
for i=1:7
  prm.momB(:,i) = N{i};
end
prm.momB(:,4) = prm.momB(:,4)-log(94147);       % Mean log outdegree relative to the number of firms

stdmom = std(prm.momB);
Lnorm = L.*repmat(stdmom,4,1)*100;
disp('Lambda, normalized * 100'); disp(Lnorm);

close all
Xlab = categorical({'mean(lnS^{net})','var(lnn^c)','\beta (mkt. share regression)','mean(lnn^c)','Decomp 1','Decomp 2','Decomp 3'});
Xlab = reordercats(Xlab,{'mean(lnS^{net})','var(lnn^c)','\beta (mkt. share regression)','mean(lnn^c)','Decomp 1','Decomp 2','Decomp 3'});
figure(1); barh(Xlab,Lnorm(3,:)); xlabel('Sensitivity');

if (savefigures) 
    saveas(gcf,strcat(workdir,'/graph/andrews_sensitivity.eps')); 
    saveas(gcf,strcat(workdir,'/graph/andrews_sensitivity.png')); 
    saveas(gcf,strcat(workdir,'/graph/andrews_sensitivity.pdf')); 
end

%% Model fit

close all;
savefigures=0;
prm.firms = 400;
rng('default'); rng(1);
draws = randn(prm.firms,2);
sd_e=4;

% Estimates
r1.beta = [0.2381 2.2342 0.8616 18.1120];          

prm.mom = [3.12 1.87 -.08 -8.12 .51 .05 .25];      % Empirical moments
prm.W = eye(length(prm.mom));                     % Identity weighting matrix

[lnA lntheta lnpsi lnPtilde Pfinaltilde lnS Sinter lnZ] = iterate_network(r1.beta,prm,draws);
A = exp(lnA);
lnoutdeg = log(mean(A))';          % Each col is a seller
lnindeg = log(mean(A,2));
lnSinter = log(Sinter);
lnM = lnS + log((1-prm.a)/prm.mu);
lnVA = log(exp(lnS)-exp(lnM));
lnm = repmat(lntheta,1,prm.firms) + repmat(lnpsi',prm.firms,1) - (prm.sig-1)*log(prm.mu); % A seller is a column
Em = A.*exp(lnm);       
Pfinal = Pfinaltilde^(1/(1-prm.sig));

[ss mom] = SMM_network(r1.beta,prm,draws);
disp('Simulated moments'); disp(mom);

% lnF and lnZ
[lnZ lnF] = lnZlnF(r1.beta,draws,prm);

lnc = -((1-prm.a)*lnPtilde+lnZ)/(prm.sig-1);
lnL = log(prm.a/prm.mu)+lnS;

% Fixed costs relative to sales/profits
lnpi = lnm + log((prm.mu-1)/prm.mu);
ElnF = repmat(lnF',prm.firms,1);

tmp2 = ElnF-lnm;
disp('---------------------');
disp('F relative to sales for all potential matches');
disp(exp(mean(tmp2(:))));

xx = (lnpi-ElnF)/sd_e;
tmp = ElnF-lnm - sd_e*normpdf(xx)./normcdf(xx);
disp('F relative to sales for successful matches');
disp(exp((mean(tmp(:)))));
R = prm.firms;

% Market shares
wUp = A./repmat(exp(lnindeg),1,R);        % Pr that buyer j links to a given seller i (sum over i=1)
wDown = A./repmat(exp(lnoutdeg)',R,1);    % Pr that seller i links to a given buyer j (sum over j=1)

ms_Down = mean(exp(lnm)/R./repmat(exp(lnM),1,R),1)';        
ms_Up = mean(exp(lnm)/R./repmat(exp(lnS)',R,1),2);        
lnms_Down = mean((lnm-log(R)-repmat(lnM,1,R)),1)';        
lnms_Up= mean((lnm-log(R)-repmat(lnS',R,1)),2);        


% (1) Histogram of network sales (Figure 5)
figure(5);
hist(lnSinter);xlabel('Network sales (log)');

% Explort distributions to csv files
EE = [lnoutdeg lnS lnSinter lnindeg lnM];
TT = array2table(EE)
TT.Properties.VariableNames(1:5) = {'log outdegree','log S','log Sinter','log indegree','log input purchases'};
writetable(TT,strcat(workdir,'/distributions.csv'));

%
% Non-targeted moments
%

% Assortivity
wUp = A./repmat(exp(lnindeg),1,prm.firms)/prm.firms;  % Pr that buyer j links to a given seller i (sum over i=1)
wDown = A./repmat(exp(lnoutdeg)',prm.firms,1)/prm.firms;  % Pr that seller i links to a given buyer j (sum over j=1)
m_lnoutS = sum(wUp.*repmat(lnoutdeg',prm.firms,1),2);       
m_lninC = sum(wDown.*repmat(lnindeg,1,prm.firms),1)';

figure(10);
subplot(2,1,1); scatter(lnindeg,m_lnoutS);  xlabel('Indegree'); ylabel('Mean log outdegree of suppliers'); lsline;
b=regress(m_lnoutS,[ones(prm.firms,1) lnindeg]);
theString = sprintf('y = %.2f + %.2f x', b(1), b(2));
text(min(lnindeg), min(m_lnoutS), theString, 'FontSize', 12);

subplot(2,1,2); scatter(lnoutdeg,m_lninC);  xlabel('Outdegree'); ylabel('Mean log indegree of customers'); lsline;
b=regress(m_lninC,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('y = %.2f + %.2f x', b(1), b(2));
text(min(lnoutdeg), min(m_lninC), theString, 'FontSize', 12);


% Sales p10, p50, p90 buyer

figure(11);
clear p10 p50 p90
for i = 1:prm.firms
  lns = lnm(:,i)-log(prm.firms);
  p10(i,1) = WeightedQuantile(lns,A(:,i),.1);
  p50(i,1) = WeightedQuantile(lns,A(:,i),.5);
  p90(i,1) = WeightedQuantile(lns,A(:,i),.9);
end
subplot(3,1,1); scatter(lnoutdeg,p10); 
xlabel('Outdegree'); ylabel('P10'); lsline;
b=regress(p10,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('y = %.2f + %.2f x', b(1), b(2));
text(min(lnoutdeg), min(p10), theString, 'FontSize', 12);

subplot(3,1,2); scatter(lnoutdeg,p50); 
xlabel('Outdegree'); ylabel('P50'); lsline;
b=regress(p50,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('y = %.2f + %.2f x', b(1), b(2));
text(min(lnoutdeg), min(p50), theString, 'FontSize', 12);

subplot(3,1,3); scatter(lnoutdeg,p90); 
xlabel('Outdegree'); ylabel('P90'); lsline;
b=regress(p90,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('y = %.2f + %.2f x', b(1), b(2));
text(min(lnoutdeg), min(p90), theString, 'FontSize', 12);

disp('Mean/var/median lnS'); disp([mean(lnS) var(lnS) median(lnS)]);
disp('Mean/var/median lnM'); disp([mean(lnM) var(lnM) median(lnM)]);
disp('Mean/var/median ln indegree'); disp([mean(lnindeg) var(lnindeg) median(lnindeg)]);


%
% Value added per worker
%

% Production workers
lnL1 = log(prm.a)+lnS-log(prm.mu);

% Marketing workers
lnL2 = lnoutdeg+lnF;

% Total employment
lnL = log(exp(lnL1)+exp(lnL2));

disp('Variance of log value added per worker (including marketing workers)');
disp(var(lnVA-lnL));

%% Restricted estimation : var(lnZ)=0 ("noZ")

% Initial values
beta0 = [1.3158 19.8570];         

% Moments
prm.mom = [3.12 1.87 -.11 -8.12 .51 .05 .25];   

options = optimset('Display','iter','TolFun',1e-6,'TolX',1e-6);
options = optimset(options,'MaxFunEvals',30000);
options = optimset(options,'Algorithm','interior-point');
options = optimset(options,'PlotFcn','optimplotx');
lb = [.6  -10]; ub = [8 29];

f2 = @(beta) SMM_network_noZ(beta,prm,draws);
tic; [r2.beta,r2.fval,r2.exitflag,r2.output,r2.lambda,r2.grad,r2.hessian] = fmincon(f2,beta0,[],[],[],[],lb,ub,[],options); toc;
[ss mom] = SMM_network_noZ(r2.beta,prm,draws);
disp('True moments'); disp(prm.mom);
disp('Simulated moments'); disp(mom);
disp('Estimates'); disp(r2.beta);


%% Restricted model fit: var(lnZ)=0 ("noZ")
close all;

savefigures=0;
size=12;

% Estimates:
r2.beta = [1.4831 19.6534];          

[lnA lntheta lnpsi lnPtilde Pfinaltilde lnS Sinter] = iterate_network_noZ(r2.beta,prm,draws);
A = exp(lnA);
lnoutdeg = log(mean(A))';          % Each col is a seller
lnindeg = log(mean(A,2));
lnSinter = log(Sinter);
lnM = lnS + log((1-prm.a)/prm.mu);
lnVA = log(exp(lnS)-exp(lnM));
lnm = repmat(lntheta,1,prm.firms) + repmat(lnpsi',prm.firms,1) - (prm.sig-1)*log(prm.mu); % A seller is a column
Em = A.*exp(lnm);       
Pfinal = Pfinaltilde^(1/(1-prm.sig));
R = prm.firms;

[ss mom] = SMM_network_noZ(r2.beta,prm,draws);
disp('Simulated moments'); disp(mom);


% Market shares
wUp = A./repmat(exp(lnindeg),1,R);        % Pr that buyer j links to a given seller i (sum over i=1)
wDown = A./repmat(exp(lnoutdeg)',R,1);    % Pr that seller i links to a given buyer j (sum over j=1)
lnms_Down = mean((lnm-log(R)-repmat(lnM,1,R)),1)';        
lnms_Up= mean((lnm-log(R)-repmat(lnS',R,1)),2);        

%
% Non-targeted moments
%

% Sales to median buyer
for i = 1:prm.firms
  lns = lnm(:,i)-log(prm.firms);
  p10(i,1) = WeightedQuantile(lns,A(:,i),.1);
  p50(i,1) = WeightedQuantile(lns,A(:,i),.5);
  p90(i,1) = WeightedQuantile(lns,A(:,i),.9);
end

figure(12);
subplot(3,1,1); 
scatter(lnoutdeg,p10); 
xlabel('Outdegree (logs)','FontSize',size); ylabel('P10 (logs)','FontSize',size); lsline;
b=regress(p10,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('Slope: %.2f', b(2));
text(min(lnoutdeg), min(p10), theString, 'FontSize', 12);

subplot(3,1,2); 
scatter(lnoutdeg,p50); 
xlabel('Outdegree (logs)','FontSize',size); ylabel('P50 (logs)','FontSize',size); lsline;
b=regress(p50,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('Slope: %.2f', b(2));
text(min(lnoutdeg), min(p50), theString, 'FontSize', 12);

subplot(3,1,3); 
scatter(lnoutdeg,p90); 
xlabel('Outdegree (logs)','FontSize',size); ylabel('P90 (logs)','FontSize',size); lsline;
b=regress(p90,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('Slope: %.2f', b(2));
text(min(lnoutdeg), min(p90), theString, 'FontSize', 12);

disp('---------------------');
disp('Mean/var/median lnS'); disp([mean(lnS) var(lnS) median(lnS)]);
disp('Mean/var/median lnM'); disp([mean(lnM) var(lnM) median(lnM)]);
disp('Mean/var/median ln indegree'); disp([mean(lnindeg) var(lnindeg) median(lnindeg)]);


% Assortivity
wUp = A./repmat(exp(lnindeg),1,prm.firms)/prm.firms;  % Pr that buyer j links to a given seller i (sum over i=1)
wDown = A./repmat(exp(lnoutdeg)',prm.firms,1)/prm.firms;  % Pr that seller i links to a given buyer j (sum over j=1)
m_lnoutS = sum(wUp.*repmat(lnoutdeg',prm.firms,1),2);
m_lninC = sum(wDown.*repmat(lnindeg,1,prm.firms),1)';

b=regress(m_lnoutS,[ones(prm.firms,1) lnindeg]);
disp('Regress outdeg of suppliers on # suppliers (upstream)'); disp(b(2));
b=regress(m_lninC,[ones(prm.firms,1) lnoutdeg]);
disp('Regress indeg of customers on # customers (downstream)'); disp(b(2));


%
% Value added per worker
%

% Production workers
lnL1 = log(prm.a)+lnS-log(prm.mu);

% Marketing workers
sd_f = r2.beta(1);
mu_f = r2.beta(2);
lnF = mu_f + draws(:,1).*sd_f;
lnL2 = lnoutdeg+lnF;

% Total employment
lnL = log(exp(lnL1)+exp(lnL2));

disp('Variance of log sales per worker (including marketing workers)');
disp(var(lnS-lnL));

exportdata = [lnoutdeg lnindeg lnS log(Sinter) lnM m_lnoutS m_lninC lnms_Down lnms_Up p10 p50 p90];
csvwrite(strcat(workdir,'/sim_data_noZ.csv'),exportdata);


%% Restricted estimation : var(lnF)=0 ("noF")


% Initial values
beta0 = [0.9671 15.0798];         % R=400

% Moments
prm.mom = [3.12 1.87 -.11 -8.12 .51 .05 .25];   


options = optimset('Display','iter','TolFun',1e-6,'TolX',1e-6);
options = optimset(options,'MaxFunEvals',30000);
options = optimset(options,'Algorithm','interior-point');
options = optimset(options,'PlotFcn','optimplotx');
lb = [.1  -10]; ub = [8 29];

f2 = @(beta) SMM_network_noF(beta,prm,draws);
tic; [r2.beta,r2.fval,r2.exitflag,r2.output,r2.lambda,r2.grad,r2.hessian] = fmincon(f2,beta0,[],[],[],[],lb,ub,[],options); toc;
[ss mom] = SMM_network_noF(r2.beta,prm,draws);
disp('True moments'); disp(prm.mom);
disp('Simulated moments'); disp(mom);
disp('Estimates'); disp(r2.beta);

%% Restricted model fit: var(lnF)=0 ("noF")
close all;

savefigures=0;
size=12;

% Estimates
r2.beta = [0.1296 19.1773];         

[lnA lntheta lnpsi lnPtilde Pfinaltilde lnS Sinter lnZ] = iterate_network_noF(r2.beta,prm,draws);
A = exp(lnA);
lnoutdeg = log(mean(A))';          % Each col is a seller
lnindeg = log(mean(A,2));
lnSinter = log(Sinter);
lnM = lnS + log((1-prm.a)/prm.mu);
lnVA = log(exp(lnS)-exp(lnM));
lnm = repmat(lntheta,1,prm.firms) + repmat(lnpsi',prm.firms,1) - (prm.sig-1)*log(prm.mu); % A seller is a column
Em = A.*exp(lnm);       
Pfinal = Pfinaltilde^(1/(1-prm.sig));
R = prm.firms;

[ss mom] = SMM_network_noF(r2.beta,prm,draws);
disp('Simulated moments'); disp(mom);


% Market shares
wUp = A./repmat(exp(lnindeg),1,R);        % Pr that buyer j links to a given seller i (sum over i=1)
wDown = A./repmat(exp(lnoutdeg)',R,1);    % Pr that seller i links to a given buyer j (sum over j=1)
lnms_Down = mean((lnm-log(R)-repmat(lnM,1,R)),1)';        
lnms_Up= mean((lnm-log(R)-repmat(lnS',R,1)),2);        

%
% Non-targeted moments
%

% Sales to median buyer
for i = 1:prm.firms
  lns = lnm(:,i)-log(prm.firms);
  p10(i,1) = WeightedQuantile(lns,A(:,i),.1);
  p50(i,1) = WeightedQuantile(lns,A(:,i),.5);
  p90(i,1) = WeightedQuantile(lns,A(:,i),.9);
end


figure(12);
subplot(3,1,1); 
scatter(lnoutdeg,p10); 
xlabel('Outdegree (logs)','FontSize',size); ylabel('P10 (logs)','FontSize',size); lsline;
b=regress(p10,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('Slope: %.2f', b(2));
text(min(lnoutdeg), min(p10), theString, 'FontSize', 12);

subplot(3,1,2); 
scatter(lnoutdeg,p50); 
xlabel('Outdegree (logs)','FontSize',size); ylabel('P50 (logs)','FontSize',size); lsline;
b=regress(p50,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('Slope: %.2f', b(2));
text(min(lnoutdeg), min(p50), theString, 'FontSize', 12);

subplot(3,1,3); 
scatter(lnoutdeg,p90); 
xlabel('Outdegree (logs)','FontSize',size); ylabel('P90 (logs)','FontSize',size); lsline;
b=regress(p90,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('Slope: %.2f', b(2));
text(min(lnoutdeg), min(p90), theString, 'FontSize', 12);


disp('---------------------');
disp('Mean/var/median lnS'); disp([mean(lnS) var(lnS) median(lnS)]);
disp('Mean/var/median lnM'); disp([mean(lnM) var(lnM) median(lnM)]);
disp('Mean/var/median ln indegree'); disp([mean(lnindeg) var(lnindeg) median(lnindeg)]);

% Assortivity
wUp = A./repmat(exp(lnindeg),1,prm.firms)/prm.firms;  % Pr that buyer j links to a given seller i (sum over i=1)
wDown = A./repmat(exp(lnoutdeg)',prm.firms,1)/prm.firms;  % Pr that seller i links to a given buyer j (sum over j=1)
m_lnoutS = sum(wUp.*repmat(lnoutdeg',prm.firms,1),2);
m_lninC = sum(wDown.*repmat(lnindeg,1,prm.firms),1)';

b=regress(m_lnoutS,[ones(prm.firms,1) lnindeg]);
disp('Regress outdeg of suppliers on # suppliers (upstream)'); disp(b(2));
b=regress(m_lninC,[ones(prm.firms,1) lnoutdeg]);
disp('Regress indeg of customers on # customers (downstream)'); disp(b(2));

%
% Value added per worker
%

% Production workers
lnL1 = log(prm.a)+lnS-log(prm.mu);

% Marketing workers
mu_f = r2.beta(2);
lnF = mu_f*ones(prm.firms,1);
lnL2 = lnoutdeg+lnF;

% Total employment
lnL = log(exp(lnL1)+exp(lnL2));

disp('Variance of log sales per worker (including marketing workers)');
disp(var(lnS-lnL));

exportdata = [lnoutdeg lnindeg lnS log(Sinter) lnM m_lnoutS m_lninC lnms_Down lnms_Up p10 p50 p90];
csvwrite(strcat(workdir,'/sim_data_noF.csv'),exportdata);

%% Restricted estimation : No correlation

% Empirical moments
prm.mom = [3.12 1.87 -.11 -8.12 .51 .05 .25]; 

% Initial values
beta0 = [.2 2.23 0 18.08];         

f = @(beta) SMM_network(beta,prm,draws);

options = optimset('Display','iter','TolFun',1e-6,'TolX',1e-6);
options = optimset(options,'MaxFunEvals',30000);
options = optimset(options,'Algorithm','interior-point');
options = optimset(options,'PlotFcn',{@optimplotx,@optimplotfval,@optimplotfirstorderopt});

lb = [.03 .8 0 -30]; ub = [4 4 0 22];

tic; [rR.beta,r1.fval,r1.exitflag,r1.output,r1.lambda,r1.grad,r1.hessian] = fmincon(f,beta0,[],[],[],[],lb,ub,[],options); toc;


[ss mom] = SMM_network(rR.beta,prm,draws);
disp('True moments'); disp(prm.mom);
disp('Simulated moments'); disp(mom);
disp('Estimates'); disp(rR.beta);
%% Restricted model fit: No correlation ("norho")

close all;
savefigures=0;
prm.firms = 400;
rng('default'); rng(1);
draws = randn(prm.firms,2);
sd_e=4;

% Estimates
r1.beta = [0.0723 1.2976 0 18.2196];          

[lnA lntheta lnpsi lnPtilde Pfinaltilde lnS Sinter lnZ] = iterate_network(r1.beta,prm,draws);
A = exp(lnA);
lnoutdeg = log(mean(A))';          % Each col is a seller
lnindeg = log(mean(A,2));
lnSinter = log(Sinter);
lnM = lnS + log((1-prm.a)/prm.mu);
lnVA = log(exp(lnS)-exp(lnM));
lnm = repmat(lntheta,1,prm.firms) + repmat(lnpsi',prm.firms,1) - (prm.sig-1)*log(prm.mu); % A seller is a column
Em = A.*exp(lnm);       
Pfinal = Pfinaltilde^(1/(1-prm.sig));

[ss mom] = SMM_network(r1.beta,prm,draws);
disp('Simulated moments'); disp(mom);

% lnF and lnZ
[lnZ lnF] = lnZlnF(r1.beta,draws,prm);

% Market shares
wUp = A./repmat(exp(lnindeg),1,R);        % Pr that buyer j links to a given seller i (sum over i=1)
wDown = A./repmat(exp(lnoutdeg)',R,1);    % Pr that seller i links to a given buyer j (sum over j=1)
lnms_Down = mean((lnm-log(R)-repmat(lnM,1,R)),1)';        
lnms_Up= mean((lnm-log(R)-repmat(lnS',R,1)),2);        

%
% Non-targeted moments
%

% Assortivity
wUp = A./repmat(exp(lnindeg),1,prm.firms)/prm.firms;  % Pr that buyer j links to a given seller i (sum over i=1)
wDown = A./repmat(exp(lnoutdeg)',prm.firms,1)/prm.firms;  % Pr that seller i links to a given buyer j (sum over j=1)
m_lnoutS = sum(wUp.*repmat(lnoutdeg',prm.firms,1),2);       
m_lninC = sum(wDown.*repmat(lnindeg,1,prm.firms),1)';

figure(10);
subplot(2,1,1); scatter(lnindeg,m_lnoutS);  xlabel('Indegree'); ylabel('Mean log outdegree of suppliers'); lsline;
b=regress(m_lnoutS,[ones(prm.firms,1) lnindeg]);
theString = sprintf('y = %.2f + %.2f x', b(1), b(2));
text(min(lnindeg), min(m_lnoutS), theString, 'FontSize', 12);

subplot(2,1,2); scatter(lnoutdeg,m_lninC);  xlabel('Outdegree'); ylabel('Mean log indegree of customers'); lsline;
b=regress(m_lninC,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('y = %.2f + %.2f x', b(1), b(2));
text(min(lnoutdeg), min(m_lninC), theString, 'FontSize', 12);


% Sales p10, p50, p90 buyer

figure(11);
clear p10 p50 p90
for i = 1:prm.firms
  lns = lnm(:,i)-log(prm.firms);
  p10(i,1) = WeightedQuantile(lns,A(:,i),.1);
  p50(i,1) = WeightedQuantile(lns,A(:,i),.5);
  p90(i,1) = WeightedQuantile(lns,A(:,i),.9);
end
subplot(3,1,1); scatter(lnoutdeg,p10); 
xlabel('Outdegree'); ylabel('P10'); lsline;
b=regress(p10,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('y = %.2f + %.2f x', b(1), b(2));
text(min(lnoutdeg), min(p10), theString, 'FontSize', 12);

subplot(3,1,2); scatter(lnoutdeg,p50); 
xlabel('Outdegree'); ylabel('P50'); lsline;
b=regress(p50,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('y = %.2f + %.2f x', b(1), b(2));
text(min(lnoutdeg), min(p50), theString, 'FontSize', 12);

subplot(3,1,3); scatter(lnoutdeg,p90); 
xlabel('Outdegree'); ylabel('P90'); lsline;
b=regress(p90,[ones(prm.firms,1) lnoutdeg]);
theString = sprintf('y = %.2f + %.2f x', b(1), b(2));
text(min(lnoutdeg), min(p90), theString, 'FontSize', 12);

disp('Mean/var/median lnS'); disp([mean(lnS) var(lnS) median(lnS)]);
disp('Mean/var/median lnM'); disp([mean(lnM) var(lnM) median(lnM)]);
disp('Mean/var/median ln indegree'); disp([mean(lnindeg) var(lnindeg) median(lnindeg)]);


%
% Value added per worker
%

% Production workers
lnL1 = log(prm.a)+lnS-log(prm.mu);

% Marketing workers
lnL2 = lnoutdeg+lnF;

% Total employment
lnL = log(exp(lnL1)+exp(lnL2));

disp('Variance of log value added per worker (including marketing workers)');
disp(var(lnVA-lnL));

%% Counterfactual, baseline model: Lower F by 50% 

r1.beta = [0.2436 2.2758 0.8704 18.1342];          

[lnA lntheta lnpsi lnPtilde Pfinaltilde lnS Sinter ] = iterate_network(r1.beta,prm,draws);
[lnZ lnF] = lnZlnF(r1.beta,draws,prm);

A = exp(lnA);
outdeg = mean(A)';          % Each col is a seller
indeg = mean(A,2);
Pfinal = Pfinaltilde^(1/(1-prm.sig));
lnP = (1/(1-prm.sig))*lnPtilde;
lnM = lnS + log((1-prm.a)/prm.mu);
lnVA = log(exp(lnS)-exp(lnM));
lnLa = log(prm.a)+lnS-log(prm.mu);
lnLb = log(outdeg)+lnF;
lnL = log(exp(lnLa)+exp(lnLb));
lpr1 = lnVA-lnL;

beta_cf = [r1.beta(1) r1.beta(2) r1.beta(3) r1.beta(4)-.5];
[lnA2 lntheta2 lnpsi2 lnPtilde2 Pfinaltilde2 lnS2 Sinter2] = iterate_network(beta_cf,prm,draws);
[lnZ2 lnF2] = lnZlnF(beta_cf,draws,prm);
A2 = exp(lnA2);
outdeg2 = mean(A2)';          % Each col is a seller
indeg2 = mean(A2,2);
Pfinal2 = Pfinaltilde2^(1/(1-prm.sig));
lnP2 = (1/(1-prm.sig))*lnPtilde2;
lnM2 = lnS2 + log((1-prm.a)/prm.mu);
lnVA2 = log(exp(lnS2)-exp(lnM2));
lnLa2 = log(prm.a)+lnS2-log(prm.mu);
lnLb2 = log(outdeg2)+lnF2;
lnL2 = log(exp(lnLa2)+exp(lnLb2));
lpr2 = lnVA2-lnL2;

totVA = sum(exp(lnVA));
totVA2 = sum(exp(lnVA2));

lnSf = log(exp(lnS)-Sinter);
lnSf2 = log(exp(lnS2)-Sinter2);

disp('----------------------');
disp('Change in real income'); disp(Pfinal/Pfinal2);
disp('Change in total number of connections'); disp(sum(outdeg2)/sum(outdeg));

lno1 = log(outdeg);
lno2 = log(outdeg2);
lni1 = log(indeg);
lni2 = log(indeg2);


%% Counterfactual, norho model: Lower F by 50% 

r1.beta = [0.2436 2.2758 0 18.1342];        % Baseline estimates with zero corr


[lnA3 lntheta3 lnpsi3 lnPtilde3 Pfinaltilde3 lnS3 Sinter3] = iterate_network(r1.beta,prm,draws);
[lnZ3 lnF3] = lnZlnF(r1.beta,draws,prm);

A3 = exp(lnA3);
outdeg3 = mean(A3)';          % Each col is a seller
indeg3 = mean(A3,2);
Pfinal3 = Pfinaltilde3^(1/(1-prm.sig));
lnP3 = (1/(1-prm.sig))*lnPtilde3;
lnSf3 = log(exp(lnS3)-Sinter3);
lnM3 = lnS3 + log((1-prm.a)/prm.mu);
lnVA3 = log(exp(lnS3)-exp(lnM3));
lnLa3 = log(prm.a)+lnS3-log(prm.mu);
lnLb3 = log(outdeg3)+lnF3;
lnL3 = log(exp(lnLa3)+exp(lnLb3));
lpr3 = lnVA3-lnL3;


beta_cf = [r1.beta(1) r1.beta(2) r1.beta(3) r1.beta(4)-.5];
[lnA4 lntheta4 lnpsi4 lnPtilde4 Pfinaltilde4 lnS4 Sinter4] = iterate_network(beta_cf,prm,draws);
[lnZ4 lnF4] = lnZlnF(beta_cf,draws,prm);
A4 = exp(lnA4);
outdeg4 = mean(A4)';          % Each col is a seller
indeg4 = mean(A4,2);
Pfinal4 = Pfinaltilde4^(1/(1-prm.sig));
lnP4 = (1/(1-prm.sig))*lnPtilde4;
lnSf4 = log(exp(lnS4)-Sinter4);
lnM4 = lnS4 + log((1-prm.a)/prm.mu);
lnVA4 = log(exp(lnS4)-exp(lnM4));
lnLa4 = log(prm.a)+lnS4-log(prm.mu);
lnLb4 = log(outdeg4)+lnF4;
lnL4 = log(exp(lnLa4)+exp(lnLb4));
lpr4 = lnVA4-lnL4;

totVA3 = sum(exp(lnVA3));
totVA4 = sum(exp(lnVA4));

disp('----------------------');
disp('Change in real income'); disp(Pfinal3/Pfinal4);
disp('Change in total number of connections'); disp(sum(outdeg4)/sum(outdeg3));


lno3 = log(outdeg3);
lno4 = log(outdeg4);
lni3 = log(indeg3);
lni4 = log(indeg4);

% Plot
close all
subplot(2,1,1); scatter(lnZ,lno2-lno1);
subplot(2,1,2); scatter(lnZ3,lno4-lno3);

% Export to stata, to make binscatters
exportdata = [lnZ lno2 lno1];
csvwrite(strcat(workdir,'/cf_data_baseline.csv'),exportdata);
exportdata = [lnZ3 lno4 lno3];
csvwrite(strcat(workdir,'/cf_data_nocorr.csv'),exportdata);