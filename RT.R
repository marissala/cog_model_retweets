RT <- function(nagents, ntopics, ndocuments, ntimesteps, kappa, beta, tau, omega) {
  # Arrays to populate
  x <- array(0,c(ndocuments)) 
  #strength of topic
  chi <- array(0,c(ntimesteps,nagents,ndocuments))
  #probability of retransmitting
  psy <- array(0,c(ntimesteps,nagents,ndocuments)) 
  #retransmission
  X <- array(0,c(ntimesteps,nagents,ndocuments)) 
  
  for (d in 1:ndocuments) {
    
    #---------- timestep 1 -----------
    x[d] <- rcat(1,c(1/3,1/3,1/3)) # which topic is presented for this document
    
    # compute probability of retransmitting - psy
    for (n in 1:nagents) {
      chi[1,n,d] <- tau[x[d],n] # strength of topic for each agent - select filter value from tau matrix
      psy[1,n,d] <- 1/(1+exp(-kappa[n]*(chi[1,n,d]-beta[n])))
      X[1,n,d] <- rbinom(1,1,psy[1,n,d])
    }
    
    #---------- timestep 2 to ntimesteps -----------
    for (t in 2:ntimesteps) {
      
      for (n in 1:nagents) {
        chi[t,n,d] <- sum(omega[n,]*X[t-1,,d])/nagents
        psy[t,n,d] <- 1/(1+exp(-kappa[n]*(chi[t,n,d]-beta[n])))
        X[t,n,d] <- rbinom(1,1,psy[t,n,d])
      }
      
    }
  }
  result <- list(x=x, X=X)
  return(result)
}