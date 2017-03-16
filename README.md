# netgsa
Network-based Gene Set Analysis

1. The current version gives an error message if either network has no interactions at all, but this should be allowed in future versions. 

2. We should also include one sample test using NetGSA.

3. For some settings, the variance estimates from approxVarEst could be negative. This affects the subsequent estimation with profile likelihood. We should thus add a validity check after approxVarEst. If negative, then use the previous simple estimates as the initialization for profileVarEst. In addition, approxVarEst may not converge for p > 2000. In such settings, we directly apply profileVarEst. Ali also mentioned potential identifiability issue with NetGSA.

4. When do we get an empty estimated network based on a pre-specified graph and data? What guidance to provide in such a setting?
5. The following is a strange error message:
    Error in seq.default(1, dim(zero.pos)[1]) : 'to' must be of length 1
 It is strange because I don't see the same error message when using code from my end instead of the R package. It is to do with the zeroInd() function. Something seems to be wrong with the input matrix. 
6. New error message when running permuted NetGSA: 

 Error in bic.netEst(X = t(current_data[[k]]), one = oneMat, lambda = lambda_vec[i],  :
  task 1 failed - "'to' must be of length 1"
 Calls: %dopar% -> <Anonymous>
 Execution halted
