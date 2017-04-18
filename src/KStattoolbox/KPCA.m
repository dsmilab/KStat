function [EigenVectors, EigenValues, ratio] = KPCA(K, NumOfPC);
%-------------------------------------------------------------------------%
% KPCA: kernel principal component analysis for dimension reduction.      %
%                                                                         %
% Inputs                                                                  %
% K: kernel matrix (reduced or full)                                      %
% NumOfPC: If NumOfPC= r ? 1, it extracts leading r-many eigenvectors.    %
% IfNumOfPC= r < 1, it extracts leading eigenvectors whose corresponding  %
% eigenvalues account for 100r% of the total sum of eigenvalues.          %
% [EigenVectors, EigenValues, ratio] = KPCA(K, NumOfPC) also keep tracks  %
% ofextracted eigenvalues and their ratio to the total sum.               %
%                                                                         % 
% Outputs                                                                 %
% EigenVectors: leading eigenvectors.                                     %
% EigenValues: leading eigenvalues.                                       %
% ratio: sum of leading eigenvalues over the total sum of all eigenvalues.%
%                                                                         %
%                                                                         %
% References                                                              %
% Programmer: Yeh, Yi-Ren; D9515009@mail.ntust.edu.tw                     %
% in KernelStat toolbox at http://dmlab1.csie.ntust.edu.tw/downloads      %
% Send your comment and inquiry to syhuang@stat.sinica.edu.tw             %
%-------------------------------------------------------------------------%

[n p] = size(K);

if (NumOfPC > p )
    error(['the number of leading eigenvalues must be less than ',num2str(p),]);
end

[EigenVectors EigenValues] = svd((K-ones(n,1)*mean(K))',0);
clear K
EigenValues = diag(EigenValues);
ZeroEigenValue = length(find(EigenValues==0));
if (NumOfPC > p-ZeroEigenValue )
    error(['the number of leading eigenvalues must be less than ',num2str(p-ZeroEigenValue),]);
end
Total = sum(EigenValues);
if (NumOfPC >= 1)
    % choose the leading NumOfPc eigenvectors.
    EigenVectors = EigenVectors(:,1:NumOfPC);
    ratio = sum(EigenValues(1:NumOfPC))/Total;
    EigenValues = EigenValues(1:NumOfPC);
else
    % choose those leading eigenvectors that explains at least 100*NumOfPC%
    % of the kernel data variation
    count = 1;
    Temp = EigenValues(count);
    ratio = Temp/Total;
    while (ratio < NumOfPC)
        count = count + 1;
        Temp = Temp + EigenValues(count);
        ratio = Temp/Total; 
    end
    EigenVectors = EigenVectors(:,1:count);
    EigenValues = EigenValues(1:count);
end
% normalization
 EigenVectors = EigenVectors./(ones(p,1)*sqrt(EigenValues)');

