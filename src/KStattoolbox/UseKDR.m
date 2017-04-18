function [ProjInst] = UseKDR(Inst, Info)
%==========================================================================
% KStat Use
%--------------------------------------------------------------------------
% Inputs:
% inst            [m x n] : testing data inputs
% Info            [struct]: results of Kernel Statistics method
%   .PC           [? x ?] : principal components of data
%   .EV           [? x 1] : eigenvalues respect to the principal components
%   .Ratio        [1 x 1] : 
%   .RS           [? x n] : reduced set
%   .Space        [string]: the space of Kernel Statistics method
%   .Params       [struct]: parameters specified by the user in the inputs (see KStat.m)
%--------------------------------------------------------------------------
% Outputs:
% ProjInst        [m x ?] : the instances projected onto Info.PC
%==========================================================================

if (strcmp('InputSpace',Info.Space))
    K = Inst;
else
    K = build_ker(Info.Params, Inst, Info.RS);
end
ProjInst = K*Info.PC;


%==========================================================================

function K = build_ker(params, u, v)
%  params  [struct]: Learning parameters 
%
%  u,v   - kernel data,                                            
%           u is a [m x n] real number matrix,                      
%           v is a [p x n] real number matrix
%  p     - kernel arguments(it dependents on your kernel type)

if (params.t==2)
    p = [params.g];
    K = SVKernel_C('rbf', u, v, p);
elseif (params.t==0)
    K = SVKernel_C('linear', u, v);
else
    p = [params.m params.b params.d];
    K = SVKernel_C('poly', u, v, p);
end
