### CODE FOR LECTURE #3 (not mandatory) ###
### JEB109 Econometrics I ###
### Institute of Economic Studies, Faculty of Social Sciences, Charles University ###

### SIMPLE LINEAR REGRESSION MODEL ###

#Set the number of observations
n<-100

#Generate data for x
x<-runif(n,-100,100) #from uniform distribution between -100 and 100
#x<-rnorm(n) #from standard normal distribution
#x<-rnorm(n,mean=1,sd=10) #from normal distribution with given moments

#Generate the error terms (standardly from a normal distribution)
u<-rnorm(n,mean=0,sd=100) #try different sd (mean remains 0)

#Specify betas
b0<-0.5
b1<-1.5

#Generate y according to the simple linear regression model
y<-b0+b1*x+u

#Plot x-y scatterplot
plot(x,y)

#Add the population regression function
abline(a=b0,b=b1,lwd=2.0,col="red")

#Estimate the model
model<-lm(y~x)
b0_hat<-as.numeric(model$coefficients[1])
b1_hat<-as.numeric(model$coefficients[2])
print(c(b0_hat,b1_hat))

#Compare with the population regression function
abline(a=b0_hat,b=b1_hat,lwd=2.0,col="blue")

### UNBIASEDNESS OF OLS ###

#First generate the model assuming we have a full sample of size nn
nn<-500
x<-runif(nn,-100,100)
u<-rnorm(nn,mean=0,sd=100)
b0<-0.5
b1<-1.5
y<-b0+b1*x+u
plot(x,y)
abline(a=b0,b=b1,lwd=3.0,col="red")

#How many times we resample and how many observations?
rep<-30 #how many times resampled
n<-100 #how many observations
for(i in 1:rep){ #loop rep-times
  rnd<-sample(1:nn,n,replace=F) #sampling without replacement
  model_loop<-lm(y[rnd]~x[rnd]) #estimate the parameters
  b0_hat_loop<-as.numeric(model_loop$coefficients[1])
  b1_hat_loop<-as.numeric(model_loop$coefficients[2])
  abline(a=b0_hat_loop,b=b1_hat_loop,col="blue") #draw the estimated OLS regression line
}
abline(a=b0,b=b1,lwd=3.0,col="red")

### VARIANCE OF OLS ###

rep<-100 #number of repetitions of the simulation
n<-100 #how many observations
sd_u<-10 #sd of the error
b1s<-rep(NA,100) #vector of NAs to fill with b1_hats
for(i in 1:rep){ #loop rep-times
  #Generate the model
  x<-runif(n,-100,100)
  u<-rnorm(n,mean=0,sd=sd_u)
  b0<-0.5
  b1<-1.5
  y<-b0+b1*x+u
  model_loop<-lm(y~x) #estimate the parameters
  #b0_hat_loop<-as.numeric(model_loop$coefficients[1])
  b1_hat_loop<-as.numeric(model_loop$coefficients[2])
  b1s[i]<-b1_hat_loop #write the estimate into the vector
}
sd_theoretical<-sqrt(sd_u^2/(sum((x-mean(x))^2))) #theoretical sd of b1_hat
c(sd(b1s),sd_theoretical) #compare simulated and theoretical SDs