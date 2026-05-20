source("/home/jgeng/myRFuncs/printSharpeRatioIntra.R")
# general OLS func to compute shp related stats
# usage example: OLS(ooF1D~bt1FcstDM:ifelse(DOW==5,1,1),regdata)
OLSIntra <- function(model, data,sizeX=0.03,tcost = 0.03) {
     print("MODEL:")
     print(deparse(model))
     lmfit=lm(model, data); 
     s=summary(lmfit)
     print(s)
     y=lmfit$fitted+lmfit$resid;
     printSharpeRatioIntra(data,y,lmfit$fitted, T,sizeX,tcost)    

}  
