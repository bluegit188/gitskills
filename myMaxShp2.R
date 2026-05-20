source("/home/jgeng/myRFuncs/printSharpeRatio.R")
source("/home/jgeng/myRFuncs/OLS.R")
library(dplyr)
library(lubridate)

myMaxShp2 <- function(df, yvar, x1,x2) 
# depVar= yvar vector
# indepVar =x1, x2 vector
{
   df$pnlxy1 = yvar*x1;
   df$pnlxy2 = yvar*x2;

   #port level pnl for xy1,xy2
   dataTable <- data.table(df)
   groupData <- dataTable %>%
   group_by(DATE) %>%
   summarise(pnlxy1 = sum(pnlxy1),pnlxy2=sum(pnlxy2))


   groupData$yConst=1;
   lmfit1 <- lm(yConst~pnlxy1+pnlxy2-1,data=groupData)
   print(summary(lmfit1))


   #print(sd(groupData$pnlxy1))
   #print(sd(groupData$pnlxy2))
   #print(sd(df$pnlxy1))
   #print(sd(df$pnlxy2))

   # use tstats from the pnl regression as coefs ratio
   #coefPnl=coef(summary(lmfit1))[, "t value"]
   coefPnl=coef(summary(lmfit1))[, "Estimate"]

   tmpFcst=coefPnl[1]*x1+coefPnl[2]*x2;
   lmfit2 <- lm(yvar~tmpFcst,data=df)
   #print(summary(lmfit2))

   coefs=c(lmfit2$coef[1],lmfit2$coef[2]*c(coefPnl[1],coefPnl[2]))

   print("maxShp coefs:")
   print(coefs)
   # 0.0156693   0.9793697  -0.2624828 

   newFcst=coefs[1]+coefs[2]*x1+coefs[3]*x2;
   OLS(yvar~newFcst,df)
}
