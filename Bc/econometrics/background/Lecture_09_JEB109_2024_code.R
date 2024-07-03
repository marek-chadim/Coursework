### CODE FOR LECTURE #9 (not mandatory) ###
### JEB109 Econometrics I ###
### Institute of Economic Studies, Faculty of Social Sciences, Charles University ###

### SIMULATION OF TWO DIFFERENT SUBPOPULATIONS ###

#Set random seed for replication
set.seed(12345)

#Create a function to simulate simply
dummy_sim<-function(obs, #specify number of observations
                    b0, #specify the intercept for the base group
                    d0, #specify the intercept difference for the other group
                    b1, #specify the slope for the base group
                    d1, #specify the slope difference for the other group
                    split, #specify the split boundary/ratio for the other group
                    sigma2){ #specify the error variance
  x<-runif(obs) #generate the independent variable from the uniform distribution
  D<-runif(obs)<split #generate D randomly to follow the split boundary, i.e., for the other group
  y<-b0+d0*D+b1*x+d1*D*x+rnorm(obs,sd=sqrt(sigma2)) #generate the dependent variable
  plot(x[D==0],y[D==0],col="blue", #plot the base group (blue)
       xlim=c(min(x),max(x)),ylim=c(min(y),max(y))) #make sure all will be visible in the chart
  points(x[D==1],y[D==1],col="red") #add the other group (red)
  return(data.frame(y=y,x=x,D=as.numeric(D))) #return a data frame with the variables
}

#Simulate the data according to specific parameters
dataset<-dummy_sim(1000,1,-1,1,-1,0.5,0.1)

#Estimate two models by OLS
summary(lm(y~D+x+I(D*x),data=dataset)) #check the model with dummies
summary(lm(y~x,data=dataset)) #compare to the trivial model