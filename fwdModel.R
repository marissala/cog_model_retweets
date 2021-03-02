library(extraDistr)
library(igraph)
library(R2jags)
library(beepr)
pacman::p_load(extraDistr, R2jags, polspline)
library(polspline)

start_time = Sys.time()

nagents <- 5
ntopics <- 3
ntimesteps <- 10
ndocuments <- 20

# sensitivity/discriminability for news topic - represents knowledge
#kappa <- runif(nagents,3,15)
kappa <- array(0,c(ntopics,nagents))
for (i in 1:ntopics) {
  for (j in 1:nagents)
    kappa[i,j] <- runif(1,0,20)
}

# skepticism - tendency to disagree with topic independent of knowledge - bias
#beta <- runif(nagents,0,.5)
beta <- array(0,c(ntopics,nagents))
for (i in 1:ntopics) {
  for (j in 1:nagents)
    beta[i,j] <- runif(1,0,1)
}

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

samples <- jags(data, inits=NULL, params,
                model.file ="network.txt",
                n.chains=3, n.iter=5000, n.burnin=1000, n.thin=1)

end_time <- Sys.time()
end_time-start_time
beep(sound = 1)


########################################################################
########################################################################

## Plugging in some of my own data

X = dataframe
topics_df = read.csv("test_topics_RT_overand_6.csv")
topics = topics_df["topic"]
#x <- c(x[,1])
topics = topics[[1]]
length(unique(topics))

ntimesteps <- 8
nagents <- 36
ndocuments <- 10
ntopics <- 10


x <- array(0, c(ndocuments))
for (topic in 1:ndocuments) {
  x[topic] <- topics[topic]
} 

start_time = Sys.time()

data <- list("x","X","nagents","ntopics","ntimesteps","ndocuments") #data inputted into jags
params <- c("tau","omega","kappa","beta") #parameters we'll track in jags

samples <- jags.parallel(data, inits=NULL, params,
                model.file ="network.txt",
                n.chains=3, n.iter=5000, n.burnin=1000, n.thin=1)

end_time <- Sys.time()
end_time-start_time
beep(sound = 1)

par(mfrow=c(1,5))
plot(seq(0,1,.01),1/(1+exp(-kappa[1]*(seq(0,1,.01)-beta[1]))))
plot(seq(0,1,.01),1/(1+exp(-kappa[2]*(seq(0,1,.01)-beta[2]))))
plot(seq(0,1,.01),1/(1+exp(-kappa[3]*(seq(0,1,.01)-beta[3]))))
plot(seq(0,1,.01),1/(1+exp(-kappa[4]*(seq(0,1,.01)-beta[4]))))
plot(seq(0,1,.01),1/(1+exp(-kappa[5]*(seq(0,1,.01)-beta[5]))))

print(X)  
print(omega)  

network <- graph_from_adjacency_matrix( omega, weighted=TRUE, mode="directed", diag=F)
par(mfrow=c(1,1))
plot(network)


tau_infer <- samples$BUGSoutput$sims.list$tau
omega_infer <- samples$BUGSoutput$sims.list$omega
kappa_infer <- samples$BUGSoutput$sims.list$kappa
beta_infer <- samples$BUGSoutput$sims.list$beta

par(mfrow=c(2,2))
plot(density(tau_infer))
plot(density(omega_infer))
plot(density(kappa_infer))
plot(density(beta_infer))

par(mfrow=c(2,3))
d_a <- density(tau_infer[,3,])
plot(d_a, main="Tau - topic interest")
polygon(d_a, col="lightblue", border="lightblue")
d_w <- density(omega_infer)
plot(d_w, main="Omega - social influence")
polygon(d_w, col="lightblue", border="lightblue")
d_A <- density(kappa_infer[,3,])
plot(d_A, main="Kappa - knowledge")
polygon(d_A, col="lightblue", border="lightblue")
d_theta <- density(beta_infer[,3,])
plot(d_theta, main="Beta - skepticism")
polygon(d_theta, col="lightblue", border="lightblue")

par(mfrow=c(3,ntopics))
for (i in 1:ntopics){
  d_a <- density(tau_infer[,i,])
  plot(d_a, main="Tau - topic interest")
  polygon(d_a, col="lightblue", border="lightblue")
}

#par(mfrow=c(2,ntopics))
for (i in 1:ntopics){
  d_a <- density(kappa_infer[,i,])
  plot(d_a, main="Kappa - knowledge")
  polygon(d_a, col="lightblue", border="lightblue")
}

#par(mfrow=c(2,ntopics))
for (i in 1:ntopics){
  d_a <- density(beta_infer[,i,])
  plot(d_a, main="Beta - skepticism")
  polygon(d_a, col="lightblue", border="lightblue")
}

median(tau_infer)
median(omega_infer)
median(kappa_infer)
median(beta_infer)

save.image(file='RT_cog_model.RData')

########################################################################
########################Added figures ##################################

# savage dickey plot
plot(density(rnorm(10000,0,1/sqrt(1))),ylim=c(0,1),main=" ")
lines(density(samples$BUGSoutput$sims.list$kappa),col="red")
fit.posterior <- logspline(samples$BUGSoutput$sims.list$kappa)
null.posterior <- dlogspline(0, fit.posterior)
null.prior <- dnorm(0,0,(1/sqrt(.1)))                   
BF <- null.prior/null.posterior
# We should divide posterior with prior because we are more sure that there is no difference between the groups (based on the plots below)
#opi_BF_a_rew <- dlogspline(0, (logspline(samples$BUGSoutput$sims.list$beta))) / dnorm(0,0,(1/sqrt(1)))
#opi_BF_a_pun <- dlogspline(0, (logspline(samples$BUGSoutput$sims.list$kappa))) / dnorm(0,0,(1/sqrt(1)))
#opi_BF_omega_f <- dlogspline(0, (logspline(samples$BUGSoutput$sims.list$omega))) / dnorm(0,0,(1/sqrt(1)))
#opi_BF_omega_p <- dlogspline(0, (logspline(samples$BUGSoutput$sims.list$tau))) / dnorm(0,0,(1/sqrt(1)))
#opi_BF_K <- dlogspline(0, (logspline(samples$BUGSoutput$sims.list$alpha_K))) / dnorm(0,0,(1/sqrt(1)))

x <- rnorm(1000, mean=100, sd=15)
hist(x, probability=TRUE)
xx <- seq(min(x), max(x), length=100)
lines(xx, dnorm(xx, mean=100, sd=15))

opi_BF_a_rew <- dlogspline(0, (logspline(samples$BUGSoutput$sims.list$beta))) / rnorm(0,0,(1/sqrt(1)))
opi_BF_a_pun <- dlogspline(0, (logspline(samples$BUGSoutput$sims.list$kappa))) / rnorm(0,0,(1/sqrt(1)))
opi_BF_omega_f <- dlogspline(0, (logspline(samples$BUGSoutput$sims.list$omega))) / rnorm(0,0,(1/sqrt(1)))
opi_BF_omega_p <- dlogspline(0, (logspline(samples$BUGSoutput$sims.list$tau))) / rnorm(0,0,(1/sqrt(1)))
par(mfrow=c(2,2))
plot(density(runif(10000,0,1/sqrt(1))),ylim=c(0,5),main="beta")
lines(density(samples$BUGSoutput$sims.list$beta[,1,]),col="red")
plot(density(rnorm(10000,10,5)),ylim=c(0,.2),main="kappa")
lines(density(samples$BUGSoutput$sims.list$kappa),col="red")
plot(density(runif(10000,0,1/sqrt(1))),ylim=c(0,5),main="omega")
lines(density(samples$BUGSoutput$sims.list$omega),col="red")
plot(density(runif(10000,0,1/sqrt(1))),ylim=c(0,5),main="tau")
lines(density(samples$BUGSoutput$sims.list$tau),col="red")

par(mfrow=c(3,ntopics))
for (i in 1:ntopics){
  plot(density(runif(10000,0,1/sqrt(1))),ylim=c(0,5),main="beta")
  lines(density(samples$BUGSoutput$sims.list$beta[,i,]),col="red")
}

#par(mfrow=c(2,ntopics))
for (i in 1:ntopics){
  plot(density(rnorm(10000,10,5)),ylim=c(0,.2),main="kappa")
  lines(density(samples$BUGSoutput$sims.list$kappa[,i,]),col="red")
}

#par(mfrow=c(2,ntopics))
for (i in 1:ntopics){
  plot(density(runif(10000,0,1/sqrt(1))),ylim=c(0,5),main="tau")
  lines(density(samples$BUGSoutput$sims.list$tau[,i,]),col="red")
}

#plot(density(rnorm(10000,0,1/sqrt(1))),ylim=c(0,.7),main="K")
#lines(density(samples$BUGSoutput$sims.list$alpha_K),col="red")
opi_BF_a_rew
opi_BF_a_pun
opi_BF_omega_f
opi_BF_omega_p
#opi_BF_K


########################################################################
##################Run parameter recovery################################

niterations <- 100
RT_t.tau <- array(0,c(niterations))
RT_t.omega <- array(0, c(niterations))
RT_t.kappa <- array(0, c(niterations))
RT_t.beta <- array(0, c(niterations))

RT_i.tau <- array(0,c(niterations))
RT_i.omega <- array(0, c(niterations))
RT_i.kappa <- array(0, c(niterations))
RT_i.beta <- array(0, c(niterations))
##
ntrials <- 100
for (i in 1:niterations) {
  # true parameters
  tau <- array(0,c(ntopics,nagents))
  for (i in 1:ntopics) {
    for (j in 1:nagents)
      tau[i,j] <- runif(1,0,1)
  }
  omega <- diag(1,nagents,nagents)
  for (i in 1:nagents) {
    for (j in 1:nagents) {
      omega[i,j] <- ifelse(omega[i,j]==1,0,runif(1,0,1))
    }
  }
  kappa <- runif(nagents,3,15)
  beta <- runif(nagents,0,.5)
  
  #run function and extract responses
  source("RT.R")
  RT_sims <- RT(nagents, ntopics, ndocuments, ntimesteps, kappa, beta, tau, omega)
  x <- RT_sims$x
  X <- RT_sims$X
  
  data <- list("x","X","nagents","ntopics","ntimesteps","ndocuments") #data inputted into jags
  params <- c("tau","omega","kappa","beta") #parameters we'll track in jags
  
  samples <- jags(data, inits=NULL, params,
                  model.file ="network.txt",
                  n.chains=3, n.iter=5000, n.burnin=1000, n.thin=1)
  
  RT_t.tau[i] <- tau
  RT_t.omega[i] <- omega
  RT_t.kappa[i] <- kappa
  RT_t.beta[i] <- beta
  
  #find max posteriori
  X <- samples$BUGSoutput$sims.list$tau
  RT_i.tau[i] <- density(X)$x[which(density(X)$y==max(density(X)$y))]
  
  X <- samples$BUGSoutput$sims.list$omega
  RT_i.omega[i] <- density(X)$x[which(density(X)$y==max(density(X)$y))]
  
  X <- samples$BUGSoutput$sims.list$kappa
  RT_i.kappa[i] <- density(X)$x[which(density(X)$y==max(density(X)$y))]
  
  X <- samples$BUGSoutput$sims.list$beta
  RT_i.beta[i] <- density(X)$x[which(density(X)$y==max(density(X)$y))]
  
  print(i);beepr::beep(sound=1)
}

save.image(file='RT_parameter_recovery.RData')
########################################################################
########################################################################





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

# density plot, probability mass function, 8 successes, binomial
rangeP <- seq(0, 1, length.out = 100)
plot(rangeP, dbinom(x = 8, prob = rangeP, size = 10),
     type = "l", xlab = "P(Black)", ylab = "Density")

# Add a prior distribution
lines(rangeP, dnorm(x = rangeP, mean = .5, sd = .1)/15,
      col = "red")
# calculate product between prior and posterior, unstandardized
# UPDATED PRIOR
lik <- dbinom(x = 8, prob = rangeP, size = 10)
prior <- dnorm(x = rangeP, mean = .5, sd = .1)
lines(rangeP, lik * prior, col = "green")


plot(density(runif(10000,0,1/sqrt(1))),ylim=c(0,5),main="beta")
lines(density(samples$BUGSoutput$sims.list$beta[,1,]),col="red")
rangeP <- samples$BUGSoutput$sims.list$beta[,1,]
lik <- samples$BUGSoutput$sims.list$beta[,1,]  #dbinom(x = 8, prob = rangeP, size = 10)
prior <- runif(10000,0,1/sqrt(1))  #dnorm(x = rangeP, mean = 0, sd = 1/sqrt(1))
lines(rangeP, lik * prior, col = "green")

pacman::p_load("bayesplot","rstanarm","ggplot2")

fit <- stan_glm(mpg ~ ., data = mtcars)
posterior <- as.matrix(samples)

plot_title <- ggtitle("Posterior distributions",
                      "with medians and 80% intervals")
mcmc_areas(rangeP,
           pars = c("beta", "kappa", "tau", "omega"),
           prob = 0.8) + plot_title
