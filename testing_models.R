library(extraDistr)
library(igraph)
library(R2jags)
library(beepr)

start_time = Sys.time()

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

#setwd("C:/Users/au199986/Dropbox/network")

data <- list("x","X","nagents","ntopics","ntimesteps","ndocuments") #data inputted into jags
params <- c("tau","omega","kappa","beta") #parameters we'll track in jags

jags.inits <- function(){
  list("tau"=rnorm(1),
       "omega"=rnorm(1),
       "kappa"=mvrnorm(n=1, mu=10, Sigma=10^2),
       "beta"=rnorm(1))
}
library(MASS)
#empirical=T forces mean and sd to be exact
#x <- mvrnorm(n=20, mu=5, Sigma=10^2, empirical=T)
start_time = Sys.time()
samples2 <- jags.parallel(data, inits=NULL, params,
                model.file ="network.txt",
                n.chains=3, n.iter=5000, n.burnin=1000, n.thin=1)

end_time <- Sys.time()
end_time-start_time

start_time = Sys.time()
samples2 <- jags(data, inits=NULL, params,
                          model.file ="network.txt",
                          n.chains=3, n.iter=5000, n.burnin=1000, n.thin=1)

end_time <- Sys.time()
end_time-start_time
beep(sound = 1)

tau_infer <- samples$BUGSoutput$sims.list$tau
omega_infer <- samples$BUGSoutput$sims.list$omega
kappa_infer <- samples$BUGSoutput$sims.list$kappa
beta_infer <- samples$BUGSoutput$sims.list$beta

par(mfrow=c(2,2))
plot(density(tau_infer))
plot(density(omega_infer))
plot(density(kappa_infer))
plot(density(beta_infer))

par(mfrow=c(2,2))
d_a <- density(tau_infer)
plot(d_a, main="Tau - topic interest")
polygon(d_a, col="lightblue", border="lightblue")
d_w <- density(omega_infer)
plot(d_w, main="Omega - social influence")
polygon(d_w, col="lightblue", border="lightblue")
d_A <- density(kappa_infer)
plot(d_A, main="Kappa - knowledge")
polygon(d_A, col="lightblue", border="lightblue")
d_theta <- density(beta_infer)
plot(d_theta, main="Beta - skepticism")
polygon(d_theta, col="lightblue", border="lightblue")



########################################################################
########################################################################

## Plugging in some of my own data
nagents <- 89
ntopics <- 50
ntimesteps <- 8
ndocuments <- 1937

X = dataframe
topics_df = read.csv("test_topics.csv")
topics = topics_df["topic"]
#x <- c(x[,1])
topics = topics[[1]]
length(unique(x))
x <- array(0, c(ndocuments))
for (topic in 1:ndocuments) {
  x[topic] <- topics[topic]
} 

start_time = Sys.time()

data <- list("x","X","nagents","ntopics","ntimesteps","ndocuments") #data inputted into jags
params <- c("tau","omega","kappa","beta") #parameters we'll track in jags

samples <- jags(data, inits=NULL, params,
                model.file ="network.txt",
                n.chains=3, n.iter=5000, n.burnin=1000, n.thin=1)

end_time <- Sys.time()
end_time-start_time
beep(sound = 1)