source("/home/jgeng/myRFuncs/printSharpeRatio.R")
# general OLS func to compute shp related stats
# usage example: OLS(ooF1D~bt1FcstDM:ifelse(DOW==5,1,1),regdata)
OLS <- function(model, data,sizeX=0.03,tcost = 0.03) {
     print("MODEL:")
     print(deparse(model))
     lmfit=lm(model, data); 
     s=summary(lmfit)
     print(s)
     y=lmfit$fitted+lmfit$resid;
     printSharpeRatio(data,y,lmfit$fitted, T,sizeX,tcost)    

}  
