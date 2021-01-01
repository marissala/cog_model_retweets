library(extraDistr)
library(igraph)
library(R2jags)

nagents <- 5
ntopics <- 3
ntimesteps <- 10
ndocuments <- 20

# sensitivity/discriminability for news topic - represents knowledge
kappa <- runif(nagents,3,15) 

# skepticism - tendency to disagree with topic independent of knowledge - bias
beta <- runif(nagents,0,.5) 

# topic filter matrix - quantification of topic engagement
tau <- array(0,c(ntopics,nagents)) 
for (i in 1:ntopics) {
  for (j in 1:nagents)
    tau[i,j] <- runif(1,0,1)
}

x <- array(0,c(ndocuments)) 
#strength of topic
chi <- array(0,c(ntimesteps,nagents,ndocuments))
#probability of retransmitting
psy <- array(0,c(ntimesteps,nagents,ndocuments)) 
#retransmission
X <- array(0,c(ntimesteps,nagents,ndocuments)) 

# social influence/connectivity (bounded 0 to 1)
omega <- diag(1,nagents,nagents)
for (i in 1:nagents) {
  for (j in 1:nagents) {
    omega[i,j] <- ifelse(omega[i,j]==1,0,runif(1,0,1))
  }
}
# code to test graph
#omega[1,] <- c(0,.9,0,.1,.1)
#omega[2,] <- c(0,0,.1,.1,.1)
#omega[3,] <- c(0,.1,0,.1,.1)
#omega[4,] <- c(.1,.1,.1,0,.1)
#omega[5,] <- c(.1,.1,.1,.1,0)

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

setwd("C:/Users/au199986/Dropbox/network")

data <- list("x","X","nagents","ntopics","ntimesteps","ndocuments") #data inputted into jags
params <- c("tau","omega","kappa","beta") #parameters we'll track in jags

samples <- jags(data, inits=NULL, params,
                model.file ="network.txt",
                n.chains=3, n.iter=5000, n.burnin=1000, n.thin=1)




par(mfrow=c(1,5))
plot(seq(0,1,.01),1/(1+exp(-kappa[1]*(seq(0,1,.01)-beta[1]))))
plot(seq(0,1,.01),1/(1+exp(-kappa[2]*(seq(0,1,.01)-beta[2]))))
plot(seq(0,1,.01),1/(1+exp(-kappa[3]*(seq(0,1,.01)-beta[3]))))
plot(seq(0,1,.01),1/(1+exp(-kappa[4]*(seq(0,1,.01)-beta[4]))))
plot(seq(0,1,.01),1/(1+exp(-kappa[5]*(seq(0,1,.01)-beta[5]))))

print(X)  
print(omega)  

network <- graph_from_adjacency_matrix( omega, weighted=T, mode="directed", diag=F)
par(mfrow=c(1,1))
plot(network)

# # compute probability of retransmitting - psy
# for (n in 1:nagents) {
#   chi[1,n] <- tau[x,n] # strength of topic for each agent - select filter value from tau matrix
#   psy[1,n] <- 1/(1+exp(-kappa[n]*(chi[n]-beta[n])))
#   X[1,n] <- rbinom(1,1,psy[1,n])
# }
# 
# 
# 
# 
# 
# 
# 
# 
# for (n in 1:nagents) {
# 
# x[t] <- rgamma(1,1,1)*10
# 
# #influence 
# #omega[t] <- omega[t-1]
# 
# # individual exposure - sharability * influence of the individual
# tau[t] <- x[t]*omega[t]
#   
# # probability of RTing as a function of exposure and indiv. knowledge and skepticism
# psy <- 1/(1+exp(-theta*(tau-)))
# 
# }
# 
# 
# 
# 
# 
# 
# 
# 
# 
# #------------------ single agent function ---------------------------------------
# theta <- 10 # sensitivity/discriminability for news topic - represents knowledge
# beta <- ..6 # skepticism - tendency to disagree with topic independent of knowledge
# omega <- 1 # social influence/connectivity (bounded 0 to 1)
# 
# # exposure signal - how sharable the news is at the community level, independent of
# # social connectivity and individual differences in sensitivity and bias
# x <- seq(0,1,.1)
# 
# #influence 
# #omega[t] <- omega[t-1]
# 
# # individual exposure - sharability * influence of the individual
# tau <- x*omega
# 
# # probability of RTing as a function of exposure and indiv. knowledge and skepticism
# psy <- 1/(1+exp(-theta*(tau-beta)))
# 
# plot(x,psy)
