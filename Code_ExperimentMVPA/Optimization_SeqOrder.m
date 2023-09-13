numObj = 4;
numObjRepPerRun = numObj;
objNums = repmat((1:numObj)',[numObjRepPerRun,1]);

numParLoop = 24;
minVals = zeros(numParLoop,1);
minOrders = zeros(numObjRepPerRun*numObj+1,numParLoop);

maxI = 1000; %

parfor np = 1:numParLoop
    minVal = 10^10;
    minOrder = zeros(numObjRepPerRun*numObj+1,1);
    aa = zeros(numObjRepPerRun*numObj+1,1);

    for ii = 1:maxI
        disp(['>> trial #' num2str(ii)]);
        aa(1) = randi(numObj);
        check = false;

        while ~check
            aa(2:end) = objNums(randperm(length(objNums)));
            checkTemp = zeros(numObjRepPerRun);
            for tempI = 1:numObjRepPerRun
                idx = find(aa(2:end)==tempI);
                for tempJ = 1:numObjRepPerRun
                    checkTemp(tempI,tempJ) = sum(aa(idx) == tempJ);
                end
            end
            check = ~any(checkTemp~=1,'all');
        end

        critF = 0;
        for kk = 1:numObj
            M = reshape(aa(2:end),[numObj, numObj]);
            critF = critF + sumsqr(sum(M==kk)-1);
        end
        disp(['Criterion value:' num2str(critF)]);
        if minVal > critF; minVal = critF; minOrder = aa; end
    end
    minVals(np) = minVal;
    minOrders(:,np) = minOrder;
end

%%
[minCrit,minIdx] = min(minVals);
minCritOrder = minOrders(:,minIdx);
disp(minCrit);
disp(minCritOrder);

save OptTest3 minCrit*