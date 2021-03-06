profile.newton.se <-
function(x0, D, r, control = NULL) {
    ##Note D and r are both a list of length K
    if(is.null(control)){   
      lklMethod = 'REML'      
      lb = 0.01         	
      ub = 100 		       	
      s2profile = 'se' 		
      tol = 0.01          
    } else{    
      lklMethod = control$lklMethod
      lb = control$lb
      ub = control$ub
      s2profile = control$s2profile
      tol = control$tol
    }
    
    ncond = length(D)
   # if (ncond==1){stop("Only one condition detected!")}
    
    p = dim(D[[1]])[1]
    Ip = diag(rep(1, p), p, p)
    n = sapply(r, ncol)
    
    ##This is based on the notation in Lindstrom and Bates (1988)
    N = sum(n) * p 
    
    ##residual matrices
    R = vector("list", ncond)
    for (k in 1:ncond){
      R[[k]] = matrix(0, p, p)
      tmp = r[[k]]
      for ( i in 1:n[k]){
        R[[k]] = R[[k]] + tmp[, i] %o% tmp[, i]      
      }
    }
    
    DD = lapply(D, function(m) m %*% t(m))
    
    matTr <- function(z) sum(diag(z))
    
    #obj fn
    f <- function(tau) {
      
      V = lapply(DD, function(m) tau*m + Ip)
      Vinv = lapply(V, function(m) chol2inv(chol(m)))
      
      tmp = ifelse((lklMethod == "REML"), N - ncond*p, N)
      val = sum(sapply(1:ncond, function(k) n[k] * as.numeric(determinant(V[[k]])$modulus))) 
      + tmp * log(sum(sapply(1:ncond, function(k) matTr(Vinv[[k]] %*% R[[k]]) )))
      
      ##for REML
      if (lklMethod == "REML"){
        # First sum the matrices, then take the determinant and finally take the logarithm
        m_list = lapply(1:ncond, function(k) n[k] * (t(D[[k]]) %*% Vinv[[k]] %*% D[[k]]) )
        tmp = Reduce("+", m_list)
        val = val + as.numeric(determinant(tmp)$modulus)                        
      }
      
      return(val)
    }
    
    #gradient fn
    g <- function(tau) {
      
      V = lapply(DD, function(m) tau*m + Ip)
      Vinv = lapply(V, function(m) chol2inv(chol(m)))
      C = lapply(1:ncond, function(k) t(D[[k]]) %*% Vinv[[k]] %*% D[[k]])
      trace.C = sapply(C, matTr)
      
      tmp = ifelse((lklMethod == "REML"), N - ncond*p, N)
      
      a = sapply(1:ncond, function(k) matTr(Vinv[[k]] %*% DD[[k]] %*% Vinv[[k]] %*% R[[k]]))
      b = sapply(1:ncond, function(k) matTr(Vinv[[k]] %*% R[[k]])) 
      
      val = sum(sapply(1:ncond, function(k) n[k]*trace.C[k] )) - tmp * sum(a)/sum(b)
      
      ##for REML
      if (lklMethod == "REML") {
        C2 = lapply(C, function(m) m %*% m)
        tmp1 = Reduce("+", lapply(1:ncond, function(k) n[k] * C[[k]]))
        tmp2 = Reduce("+", lapply(1:ncond, function(k) n[k] * C2[[k]]))
        val = val - matTr(solve(tmp1) %*% tmp2)
      }
      
      return(val)
    }
    
    #hessian fn
    
    h <- function(tau) {
      V = lapply(DD, function(m) tau*m + Ip)
      Vinv = lapply(V, function(m) chol2inv(chol(m))) #dV=DD
      C = lapply(1:ncond, function(k) t(D[[k]]) %*% Vinv[[k]] %*% D[[k]])
      C2 = lapply(C, function(m) m %*% m)
      
      tmp = ifelse((lklMethod == "REML"), N - ncond*p, N)
      
      m_list = lapply(1:ncond, function(k) Vinv[[k]] %*% D[[k]] %*% C[[k]] %*% t(D[[k]]) %*% Vinv[[k]] %*% R[[k]])
      Vinv_R = lapply(1:ncond, function(k) Vinv[[k]] %*% R[[k]])
      hes1 = sum(sapply(m_list, matTr))/sum(sapply(Vinv_R, matTr))
      
      m_list = lapply(1:ncond, function(k) Vinv[[k]] %*% DD[[k]] %*% Vinv[[k]] %*% R[[k]])
      hes2 = sum(sapply(m_list, matTr)) / sum(sapply(Vinv_R, matTr))
      
      tmp2 = Reduce("+", lapply(1:ncond, function(k) n[k] * C2[[k]]))
      val = - matTr(tmp2) + tmp * 2 * hes1 - tmp * hes2^2
      
      ##for REML
      if (lklMethod == "REML") {
        C3 = lapply(C, function(m) m %*% m %*% m)
        tmp1 = Reduce("+", lapply(1:ncond, function(k) n[k] * C[[k]]))
        tmp3 = Reduce("+", lapply(1:ncond, function(k) n[k] * C3[[k]]))
        val = val + matTr(solve(tmp1) %*% (2 * tmp3 - tmp2))
      }
      return(val)
    }
    
    tau = newton(x0, lb, ub, f, g, h, tol=tol)$solution
    V = lapply(DD, function(m) tau*m + Ip)
    m_list = lapply(1:ncond, function(k) chol2inv(chol(V[[k]])) %*% R[[k]])
    
    tmp = sum(sapply(m_list, matTr))
    
    se = ifelse((lklMethod == "REML"), (1/(N - ncond*p)) * tmp, (1/N) * tmp)
    sg = tau * se
    
    return(list(s2e = se, s2g = sg, tau = tau))
  }
