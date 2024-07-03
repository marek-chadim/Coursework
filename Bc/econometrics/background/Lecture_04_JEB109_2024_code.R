### CODE FOR LECTURE #4 (not mandatory) ###
### JEB109 Econometrics I ###
### Institute of Economic Studies, Faculty of Social Sciences, Charles University ###

### SIMULATION OF AN OLS BIAS ###

rep<-1000 #number of repetitions of the simulation
n<-1000 #number of observations

#Set parameters
b0<-1
b1<-1
b2<- -2
rho<- 0.5 #set correlation between x1 and x2

#Simulate
b1_hats<-rep(NA,rep) #vector of NAs to fill with b1_hats
for(i in 1:rep){ #loop rep-times
  #Generate the model
  x1<-rnorm(n,0,10)
  u<-rnorm(n,0,10)
  x2<-sqrt(rho^2)*x1+sqrt(1-rho^2)*rnorm(n,0,10) #generate the correlated variable x2
  #x2<-rho*x1+sqrt(1-rho^2)*rnorm(n,0,10) #set this way for a negative rho 
  y<-b0+b1*x1+b2*x2+u #simulate the model with x1 and x2
  model<-lm(y~x1) #run the simple regression only (x2 omitted)
  b1_hats[i]<-coefficients(model)["x1"] #write the estimate into the vector
}

#Plot histogram
hist(b1_hats,breaks=33)