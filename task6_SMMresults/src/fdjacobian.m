function J = fdjacobian(f,x,dx)
y = f(x);
m = length(y);
n = length(x);
J = zeros(m,n);
for k = 1:n
    xnew = x;
    xnew(k) = xnew(k)+dx;
    ynew = f(xnew);
    J(:,k) = ynew-y;
end
J = J/dx;