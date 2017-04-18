function [EigenVectors, EigenValues, ratio] = KSIR(K, y, NumOfSlice, NumOfPC)

%----------------------------------------------------------------------------%
% KSIR: kernel sliced inverse regression for dimension reduction.            %
%                                                                            %
% Inputs                                                                     %
% K: kernel matrix (reduced or full)                                         %
% y: class label for classification; response for regression.                %
% NumOfSlice: no. of slices.                                                 %
% For classification problem, NumOfSlice is a string variable 'class'.       %
% For regression problem, NumOfSlice is an integer. Responses y are sorted   %
% and sliced into NumOfSlice slices and so are rows of K accordingly.        %
% NumOfPC: If NumOfPC= r ? 1, it extracts leading r-many eigenvectors.       %
% IfNumOfPC= r < 1, it extracts leading eigenvectors whose corresponding     %
% eigenvalues account for 100r% of the total sum of eigenvalues.             %
%                                                                            %
% [EigenVectors, EigenValues, ratio] = KSIR(K, y, NumOfSlice, NumOfPC)       %
% also keep tracks of extracted eigenvalues and their ratio to the total sum.%
%                                                                            %
% Outputs                                                                    %
% EigenVectors: leading eigenvectors of between-slice covariance.            %
% EigenValues: corresponding leading eigenvalues.                            %
% ratio: sum of leading eigenvalues over the total sum of all eigenvalues.   %
%                                                                            %
% References                                                                 %
% Author: Yeh, Yi-Ren; D9515009@mail.ntust.edu.tw                            %
% in KernelStat toolbox at http://dmlab1.csie.ntust.edu.tw/downloads         %
% Send your comment and inquiry to syhuang@stat.sinica.edu.tw                %
%----------------------------------------------------------------------------%

[n p] = size(K);
if (nargin < 4)
    NumOfPC = p;
end
 

if (NumOfPC > p )
    error(['the number of leading eigenvalues must be less than ',num2str(p),]);
end


[Sorty Index] = sort(y);
K = K(Index,:);
HK = [];
base = zeros(2,1);
if (ischar(NumOfSlice))
    Label = unique(y);
    for i = 1: length(Label)
        count = length(find(y==Label(i)));
        base(2) = base(2) + count;
        HK = [HK;ones(base(2)-base(1),1)*mean(K(base(1)+1:base(2),:))];
        base(1) = base(2);
    end
else
    SizeOfSlice = fix(n/NumOfSlice); % size of each slice
    m = mod(n,SizeOfSlice);
    for i = 1 : NumOfSlice
        count = SizeOfSlice+(i<m+1);
        base(2) = base(2) + count;
        HK = [HK;ones(base(2)-base(1),1)*mean(K(base(1)+1:base(2),:))];
        base(1) = base(2);
    end
end

% solve the following generalized eigenvalue problem
% "KH'*(I_n - (1_n*1_n')/n)*HK*beta=lambda*K*(I_n - (1_n*1_n')/n)*K'*beta"
Cov_b=cov(HK);%between-slice covariance matrix
clear HK
Cov_w=cov(K);% within-slice covariance matrix 
clear K



%[EigenVectors EigenValues]=eigs(Cov_b, Cov_w+eps*eye(p), NumOfPC);
[EigenVectors EigenValues]=eig(Cov_b, Cov_w+eps*eye(p));

clear Cov_b Cov_w

EigenValues = diag(EigenValues);
[EigenValues Index] = sort(EigenValues,'descend');
EigenVectors = EigenVectors(:,Index);
% ZeroEigenValue = length(find(EigenValues<=0));
% if (NumOfPC > p-ZeroEigenValue )
%     error(['the number of leading eigenvalues must be less than ',num2str(p-ZeroEigenValue),]);
% end
Total = sum(EigenValues);

if (NumOfPC >= 1)
    % choose the leading NumOfPc eigenvectors.
    EigenVectors = EigenVectors(:,1:NumOfPC);
    ratio = sum(EigenValues(1:NumOfPC))/Total;
    EigenValues = EigenValues(1:NumOfPC);
else
    % choose those leading eigenvectors that explain at least 100*NumOfPC%
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