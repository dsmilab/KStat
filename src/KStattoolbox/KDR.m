function [Info] = KDR(Label, Inst, strParam)
%==========================================================================
% Kernel Statistics 
%--------------------------------------------------------------------------
% Inputs:
% label       [m x 1] : training data class label or response
% inst        [m x n] : training data inputs
% strParam    [string]: parameters
%    -s               : statistic method. 0-PCA, 1-SIR                      (default:0)
%    -t               : kernel type. 0-linear, 1-polynomial, 2-radial basis (default:2)
%    -r               : ratio of random subset size to the full data size   (default:1)
%    -z               : number of slices                                    (default:20)
%                       If NumOfSlice >= 1, it represents NumOfSlice slices.
%                       If NumOfSlice = 0,  it extracts slices according to class labels.
%    -p               : number of principal components                      (default:1)
%                       If NumOfPC= r >= 1, it extracts the first r leading eigenvectors.
%                       If NumOfPC= r < 1, it extracts leading eigenvectors whose sum 
%                       of eigenvalues is greater than 100*r% of the total
%                       sum of eigenvalues
%    -g               : gamma in kernel function                            (default:0.1)
%    -d       [1 x 1] : degree of polynomial kernel                         (default:2)
%    -b       [1 x 1] : constant term of polynomial kernel                  (default:0)
%    -m       [1 x 1] : scalar factor of polynomial kernel                  (default:1)
%--------------------------------------------------------------------------
% Outputs:
% Info        [struct]: results of Kernel Statistics method
%   .PC       [? x ?] : principal components of data
%   .EV       [? x 1] : eigenvalues respect to the principal components
%   .Ratio    [1 x 1] : 
%   .RS       [? x n] : reduced set
%   .Space    [string]: the space of Kernel Statistics method
%   .Params   [struct]: parameters specified by the user in the inputs
%--------------------------------------------------------------------------

% setting up parameters
params.s=0; params.t=2; params.r=1; params.z=20; params.p=1; params.g=0.1; 
params.d=2; params.b=0; params.m=1; 
[pInd, pVal] = strread(strParam, '%s%f', 'delimiter', ' ');
for i=1:length(pInd)
    if(strcmp(pInd{i}, '-s'))
        % statistic method¡G 0-KPCA, 1-KSIR (default: 0)
        params.s=pVal(i);
    elseif(strcmp(pInd{i}, '-t'))
        % kernel type¡G 0-linear, 1-polynomial, 2-radial basis (default: 2)
        params.t=pVal(i);
    elseif(strcmp(pInd{i}, '-g'))
        % gamma (default: 0.1)
        params.g=pVal(i);
    elseif(strcmp(pInd{i}, '-r'))
        params.r=pVal(i);
    elseif(strcmp(pInd{i}, '-z'))
        % number of slices
        params.z=pVal(i);  
    elseif(strcmp(pInd{i}, '-p'))
        % number of principal components 
        params.p=pVal(i);  
    elseif(strcmp(pInd{i}, '-d'))
        % degree of polynomial (default: 2)
        params.d=pVal(i);
    elseif(strcmp(pInd{i}, '-b'))
        % constant term of polynomial (default: 0)
        params.b=pVal(i);
    elseif(strcmp(pInd{i}, '-m'))
        % scalar term of polynomial (default: 1)
        params.m=pVal(i);
    else
        error('undefined parameter: %s', pVal(i));
    end
end


% build up (reduced) kernel matrix
if params.r < 1
    if (params.s==0)
        % KPCA
        n = length(Inst(:,1));
        temp = randperm(n);
        RIndex = temp(1:fix(n*params.r));
    elseif (params.z ==0)
        % KSIR_classification
        [RIndex]=srsplit('svm', Label, params.r, 1); 
    else
        % KSIR_regression
        RIndex = srsplit('svr', Label, params.r, 1);
    end
    [K, flag] = build_ker(params, Inst, Inst(RIndex,:));
else
    RIndex = 1 : length(Inst(:,1));
    [K, flag] = build_ker(params, Inst, Inst);
end

% Start 
if (params.s==0)
    % KPCA
    [EigenVectors, EigenValues, ratio] = KPCA(K, params.p);
elseif (params.z ==0)
    % KSIR for classification
    [K,V] = IndepentCol(K, params.r); % preprocess for preventing ill-posed
    [EigenVectors, EigenValues, ratio] = KSIR(K, Label, 'CLASS', length(unique(Label))-1);
    %[EigenVectors, EigenValues, ratio] = KSIR(K, Label, 'CLASS', params.p);
    EigenVectors = V*EigenVectors;
else
    % KSIR for regression
    [K,V] = IndepentCol(K, params.r); % preprocess for preventing ill-posed
    [EigenVectors, EigenValues, ratio] = KSIR(K, Label, params.z, params.p);
    EigenVectors = V*EigenVectors;
end

Info.PC = EigenVectors;
Info.EV = EigenValues;
Info.Ratio = ratio;
Info.RS=Inst(RIndex, :);
Info.Space = flag;
Info.Params = params;


%##########################################################################
function [K,V] = IndepentCol(K, ratio)
%
% input:
%  K         - (reduced) kernel matrix
%  ratio     - ratio of random subset size to the full data size
%
% output:
%  K         - 
%  V         -

V = 1;
if (ratio > 0.1)
    %value = 0.9999-ratio*0.0555+0.00555;
    value = fix(length(K(:,1))*0.15);
    [V] = KPCA(K, value);
end
K = K*V;


%##########################################################################

function [K, flag] = build_ker(params, u, v)
%  params  [struct]: Learning parameters 
%
%  u,v   - kernel data,                                            
%           u is a [m x n] real number matrix,                      
%           v is a [p x n] real number matrix
%  p     - kernel arguments(it dependents on your kernel type)

flag = 'FeatureSpace';

if (params.t==2)
    p = [params.g];
    K = SVKernel_C('rbf', u, v, p);
elseif (params.t==0)
    [m, n] = size(u);
    if ((n > m) || (params.r < 1))
        K = SVKernel_C('linear', u, v);
    else
        K = u;
        flag = 'InputSpace';
    end
else
    p = [params.m params.b params.d];
    K = SVKernel_C('poly', u, v, p);
end
