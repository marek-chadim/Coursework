### CODE FOR LECTURE #6 (not mandatory) ###
### JEB109 Econometrics I ###
### Institute of Economic Studies, Faculty of Social Sciences, Charles University ###

### CONSISTENCY ###

#Let us visualize the concept of consistency

#Simulate a simple regression model for different sample sizes
n<-c(10,25,50,100,500,1000,2000,5000)
#n<-c(10,25,50,100,500,1000,2000,5000,10000,30000,100000)
se<-rep(NA,length(n)) #vector of NAs to fill with standard errors

#Set parameters
b0<-1
b1<-1

for(i in n){ #loop for all elements in n
  #Generate the model
  x<-runif(i,1,10)
  u<-rnorm(i,0,1)
  y<-b0+b1*x+u
  model<-lm(y~x) #estimate the model
  se[match(i,n)]<-summary(model)$coefficients["x","Std. Error"] #write standard error into the vector
}
plot(n,se) #plot
plot(log(n),se) #plot in a log scale
plot(log(n),log(se)) #plot in a log-log scale

#Approximate the densities of the OLS estimators:
aux_plot=matrix(NA,1000,length(n)) #matrix of NAs to fill
for (j in se){ #loop for all elements in se
  aux_plot[,match(j,se)]=rnorm(1000,b1,j) #approximation: write Gaussians with sd=se into the matrix 
}
aux_plot=data.frame(aux_plot) #ensure the data.frame structure

#Requires packages to install
require(ggplot2)
require(reshape2)

#Plot the approximated densities nicely using the ggplot2 and reshape2 packages
data=melt(aux_plot[,-9])
density_plot=ggplot(data,aes(x=value,fill=variable))+geom_density(alpha=0.25)
density_plot