### CODE FOR LECTURE #11 (not mandatory) ###
### JEB109 Econometrics I ###
### Institute of Economic Studies, Faculty of Social Sciences, Charles University ###

### FUNCTIONAL FORM MISSPECIFICATION ###

#Generate x first
n<-1000
x<-runif(n,0,10)

#Set parameters
b0<-0
b1<-1
b2<-2

#Generate y with a quadratic functional form of x
y<-b0+b1*x+b2*x^2+rnorm(n,0,10) 
plot(x,y)

#Estimate a model with a linear functional form of x
model<-lm(y~x)
summary(model)

#Show bias
b1_hats<-rep(NA,1000) #vector of NAs to fill with b1_hats
for(i in 1:1000){ #loop 1000-times
  x<-runif(n,0,10) #just copy-paste from above
  y<-b0+b1*x+b2*x^2+rnorm(n,0,10)
  model<-lm(y~x)
  b1_hats[i]<-summary(model)$coefficients[2,1] #write the estimate into the vector
}
mean(b1_hats)
sd(b1_hats)
hist(b1_hats,breaks=33) #plot histogram

#Show inconsistency
reps<-1000 #number of repetitions for each setting
lengths<-c(100,500,1000,2000,5000,1000,10000,30000) #set of numbers of observations 
convergence<-matrix(c(lengths,NA*lengths,NA*lengths),ncol=3) #empty matrix for the results
colnames(convergence)<-c("obs. #","bias","sd")
for(n in 1:length(lengths)){
  b1_hats<-rep(NA,reps) #copy-paste from the above
  for(i in 1:reps){ #loop reps-times
    x<-runif(lengths[n],0,10) #just copy-paste from above
    y<-b0+b1*x+b2*x^2+rnorm(lengths[n],0,10)
    model<-lm(y~x)
    b1_hats[i]<-summary(model)$coefficients[2,1]
  }
  convergence[n,2]<-mean(b1_hats)-b1 #report bias
  convergence[n,3]<-sd(b1_hats) #report sample sd
}

#Check the results
convergence #numerically
plot(convergence[,1],convergence[,2]) #bias for various n
plot(convergence[,1],convergence[,3]) #convergence of sample sd
plot(log(convergence[,1],base=10),log(convergence[,3],base=10)) #log-convergence of sample sd
summary(lm(log(convergence[,3])~log(convergence[,1]))) #estimate the rate of convergence of sample sd