function val = WeightedQuantile(xVec,wVec,q)
    [xVec,idx] = sort(xVec);    
    massVec = cumsum(double(wVec(idx)));    
    val = xVec( find( massVec >= q*massVec(end) ,1,'first') );    
end